class_name GameManager
extends Node
## Chef d'orchestre : crée/détruit la partie, gère la pause et les écrans.
##
## Il ne contient aucune règle de gameplay détaillée : il relie les modules
## (partie, score, interface) via leurs signaux. Toute demande passe par
## GameState, qui refuse les transitions incohérentes (ex. pause depuis le menu).

const GAME_SCENE: PackedScene = preload("res://scenes/game/game.tscn")
## Délai entre la collision et l'écran de fin : le temps de voir l'explosion.
const GAME_OVER_REVEAL_DELAY := 0.5
const S := GameState.State

@onready var main_menu: MainMenu = $MainMenu
@onready var hud: Hud = $HUD
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var game_over_screen: GameOverScreen = $GameOver
@onready var credits_screen: CreditsScreen = $Credits

## Fichier du record. Les tests en utilisent un autre pour ne jamais toucher au vrai record.
@export var save_path := SaveManager.DEFAULT_PATH

var state := GameState.new()
var score := ScoreManager.new()
var save: SaveManager
var audio := AudioManager.new()
var music := MusicPlayer.new()
var game: Game
## Le jingle « record » est joué juste après le son de collision.
var _record_jingle_timer := Timer.new()
var _game_over_timer := Timer.new()
var _last_result_is_record := false


func _ready() -> void:
	# Le gestionnaire et l'interface continuent de fonctionner en pause ;
	# seule la partie (Game) est suspendue.
	process_mode = Node.PROCESS_MODE_ALWAYS
	save = SaveManager.new(save_path)
	score.best = save.load_best()
	add_child(audio)
	audio.set_enabled(save.load_sound_enabled())
	main_menu.set_sound_enabled(audio.enabled)
	add_child(music)
	music.set_enabled(save.load_music_enabled())
	main_menu.set_music_enabled(music.enabled)
	_record_jingle_timer.one_shot = true
	_record_jingle_timer.wait_time = 0.45
	_record_jingle_timer.timeout.connect(audio.play.bind(&"record"))
	add_child(_record_jingle_timer)
	_game_over_timer.one_shot = true
	_game_over_timer.wait_time = GAME_OVER_REVEAL_DELAY
	_game_over_timer.timeout.connect(_reveal_game_over)
	add_child(_game_over_timer)
	state.changed.connect(_on_state_changed)
	score.score_changed.connect(hud.show_score)
	score.score_changed.connect(_on_score_changed)
	main_menu.play_requested.connect(start_game)
	main_menu.sound_toggled.connect(_on_sound_toggled)
	main_menu.music_toggled.connect(_on_music_toggled)
	main_menu.credits_requested.connect(credits_screen.show)
	credits_screen.closed.connect(credits_screen.hide)
	hud.pause_requested.connect(pause_game)
	pause_menu.resume_requested.connect(resume_game)
	pause_menu.restart_requested.connect(start_game)
	pause_menu.main_menu_requested.connect(go_to_menu)
	game_over_screen.retry_requested.connect(start_game)
	game_over_screen.main_menu_requested.connect(go_to_menu)
	# Clic sonore sur tous les boutons de l'interface.
	for button: Button in find_children("*", "Button", true, false):
		button.pressed.connect(audio.play.bind(&"click"))
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
	_game_over_timer.stop()
	get_tree().paused = false
	_clear_game()
	score.reset()
	game = GAME_SCENE.instantiate()
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	game.row_passed.connect(_on_row_passed)
	game.crashed.connect(end_game)
	add_child(game)
	game.player.lane_changed.connect(_on_player_moved)  # le joueur existe une fois la partie ajoutée
	move_child(game, 0)  # sous l'interface dans l'arbre
	_show_screens([hud])
	music.play_next()
	return true


## Suspend réellement le gameplay : obstacles, chronomètre de difficulté et
## animations de la partie sont figés tant que l'arbre est en pause.
func pause_game() -> bool:
	if not state.transition_to(S.PAUSED):
		return false
	get_tree().paused = true
	music.set_paused(true)
	_show_screens([hud, pause_menu])
	return true


func resume_game() -> bool:
	if state.current != S.PAUSED or not state.transition_to(S.PLAYING):
		return false
	get_tree().paused = false
	music.set_paused(false)
	_show_screens([hud])
	return true


## Termine la partie. Les appels répétés sont ignorés.
func end_game() -> bool:
	if not state.transition_to(S.GAME_OVER):
		return false
	game.stop()
	var is_new_record := score.commit()
	audio.play(&"crash")
	music.fade_out_and_stop()
	if is_new_record:
		save.save_best(score.best)  # une seule écriture, et seulement si nécessaire
		_record_jingle_timer.start()
	_last_result_is_record = is_new_record
	_show_screens([hud])
	_game_over_timer.start()
	return true


func _reveal_game_over() -> void:
	if state.current != S.GAME_OVER:
		return
	_show_screens([game_over_screen])
	game_over_screen.show_result(score.score, score.best, _last_result_is_record)


func go_to_menu() -> bool:
	if not state.transition_to(S.MENU):
		return false
	_game_over_timer.stop()
	get_tree().paused = false
	music.stop()
	_clear_game()
	_show_menu()
	return true


func _show_menu() -> void:
	main_menu.show_best(score.best)
	_show_screens([main_menu])


func _show_screens(screens: Array[CanvasLayer]) -> void:
	credits_screen.hide()
	for screen: CanvasLayer in [main_menu, hud, pause_menu, game_over_screen]:
		screen.visible = screen in screens


func _on_score_changed(value: int) -> void:
	if value > 0:
		audio.play(&"score")


func _on_player_moved(_lane: int) -> void:
	audio.play(&"move")


func _on_sound_toggled(enabled: bool) -> void:
	audio.set_enabled(enabled)
	save.save_sound_enabled(enabled)


func _on_music_toggled(enabled: bool) -> void:
	music.set_enabled(enabled)
	save.save_music_enabled(enabled)


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
