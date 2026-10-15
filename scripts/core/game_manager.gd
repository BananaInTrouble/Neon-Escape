class_name GameManager
extends Node
## Chef d'orchestre : crée/détruit la partie et pilote les transitions d'état.
##
## Il ne contient aucune règle de gameplay détaillée : il relie les modules
## (partie, score, interface) via leurs signaux.

const GAME_SCENE: PackedScene = preload("res://scenes/game/game.tscn")

@onready var hud: Hud = $HUD
@onready var game_over_screen: GameOverScreen = $GameOver

var state := GameState.new()
var score := ScoreManager.new()
var game: Game


func _ready() -> void:
	# Le gestionnaire doit continuer à tourner quand le gameplay est en pause.
	process_mode = Node.PROCESS_MODE_ALWAYS
	state.changed.connect(_on_state_changed)
	score.score_changed.connect(hud.show_score)
	game_over_screen.retry_requested.connect(start_game)
	# Provisoire (avant le menu principal) : on lance directement une partie.
	start_game()


## Lance une nouvelle partie propre (détruit la précédente si besoin).
func start_game() -> bool:
	if not state.transition_to(GameState.State.PLAYING):
		return false
	_clear_game()
	score.reset()
	game = GAME_SCENE.instantiate()
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	game.row_passed.connect(_on_row_passed)
	game.crashed.connect(end_game)
	add_child(game)
	move_child(game, 0)  # sous l'interface dans l'arbre
	game_over_screen.hide()
	hud.show()
	return true


## Termine la partie. Les appels répétés sont ignorés.
func end_game() -> bool:
	if not state.transition_to(GameState.State.GAME_OVER):
		return false
	game.stop()
	var is_new_record := score.commit()
	hud.hide()
	game_over_screen.show_result(score.score, score.best, is_new_record)
	return true


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
