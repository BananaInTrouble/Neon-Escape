class_name GameManager
extends Node
## Chef d'orchestre : crée/détruit la partie et pilote les transitions d'état.
##
## Il ne contient aucune règle de gameplay détaillée : il relie les modules
## (partie, score, interface) via leurs signaux.

var state := GameState.new()


func _ready() -> void:
	# Le gestionnaire doit continuer à tourner quand le gameplay est en pause.
	process_mode = Node.PROCESS_MODE_ALWAYS
	state.changed.connect(_on_state_changed)


func _on_state_changed(from: GameState.State, to: GameState.State) -> void:
	print_verbose("[GameManager] %s -> %s" % [GameState.name_of(from), GameState.name_of(to)])
