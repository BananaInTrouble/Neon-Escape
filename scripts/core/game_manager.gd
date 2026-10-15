class_name GameManager
extends Node
## Chef d'orchestre : crée/détruit la partie, gère la pause et les écrans.
##
## Il ne contient aucune règle de gameplay détaillée : il relie les modules
## (partie, score, interface) via leurs signaux. Toute demande passe par
## GameState, qui refuse les transitions incohérentes (ex. pause depuis le menu).

const GAME_SCENE: PackedScene = preload("res://scenes/game/game.tscn")
const S := GameState.State

@onready var main_menu: MainMenu = $MainMenu
@onready var hud: Hud = $HUD
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var game_over_screen: GameOverScreen = $GameOver

## Fichier du record. Les tests en utilisent un autre pour ne jamais toucher au vrai record.
@export var save_path := SaveManager.DEFAULT_PATH

var state := GameState.new()
var score := ScoreManager.new()
var save: SaveManager
var game: Game


func _ready() -> void:
	# Le gestionnaire et l'interface continuent de fonctionner en pause ;
	# seule la partie (Game) est suspendue.
	process_mode = Node.PROCESS_MODE_ALWAYS
	save = SaveManager.new(save_path)
	score.best = save.load_best()
	state.changed.connect(_on_state_changed)
	score.score_changed.connect(hud.show_score)
	main_menu.play_requested.connect(start_game)
	hud.pause_requested.connect(pause_game)
	pause_menu.resume_requested.connect(resume_game)
	pause_menu.restart_requested.connect(start_game)
	pause_menu.main_menu_requested.connect(go_to_menu)
	game_over_screen.retry_requested.connect(start_game)
	game_over_screen.main_menu_requested.connect(go_to_menu)
	_show_menu()


func _exit_tree() -> void:
	# Ne jamais laisser l'arbre en pause derrière nous.
	get_tree().paused = false


## Pause automatique si l'application passe en arrière-plan (appel, notification,
## changement d'onglet dans le navigateur...).
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if is_node_ready():
			pause_game()


## Clavier : Échap ou P pour mettre en pause / reprendre.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		if state.current == S.PLAYING:
			pause_game()
		elif state.current == S.PAUSED:
			resume_game()
		get_viewport().set_input_as_handled()


## Lance une nouvelle partie propre (depuis le menu, la pause ou la fin de partie).
func start_game() -> bool:
	if not state.transition_to(S.PLAYING):
		return false
	get_tree().paused = false
	_clear_game()
	score.reset()
	game = GAME_SCENE.instantiate()
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	game.row_passed.connect(_on_row_passed)
	game.crashed.connect(end_game)
	add_child(game)
	move_child(game, 0)  # sous l'interface dans l'arbre
	_show_screens([hud])
	return true


## Suspend réellement le gameplay : obstacles, chronomètre de difficulté et
## animations de la partie sont figés tant que l'arbre est en pause.
func pause_game() -> bool:
	if not state.transition_to(S.PAUSED):
		return false
	get_tree().paused = true
	_show_screens([hud, pause_menu])
	return true


func resume_game() -> bool:
	if state.current != S.PAUSED or not state.transition_to(S.PLAYING):
		return false
	get_tree().paused = false
	_show_screens([hud])
	return true


## Termine la partie. Les appels répétés sont ignorés.
func end_game() -> bool:
	if not state.transition_to(S.GAME_OVER):
		return false
	game.stop()
	var is_new_record := score.commit()
	if is_new_record:
		save.save_best(score.best)  # une seule écriture, et seulement si nécessaire
	_show_screens([game_over_screen])
	game_over_screen.show_result(score.score, score.best, is_new_record)
	return true


func go_to_menu() -> bool:
	if not state.transition_to(S.MENU):
		return false
	get_tree().paused = false
	_clear_game()
	_show_menu()
	return true


func _show_menu() -> void:
	main_menu.show_best(score.best)
	_show_screens([main_menu])


func _show_screens(screens: Array[CanvasLayer]) -> void:
	for screen: CanvasLayer in [main_menu, hud, pause_menu, game_over_screen]:
		screen.visible = screen in screens


func _on_row_passed() -> void:
	if state.is_playing():
		score.add_point()


func _clear_game() -> void:
	if is_instance_valid(game):
		remove_child(game)
		game.queue_free()
	game = null


func _on_state_changed(from: GameState.State, to: GameState.State) -> void:
	print_verbose("[GameManager] %s -> %s" % [GameState.name_of(from), GameState.name_of(to)])
