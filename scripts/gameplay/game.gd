class_name Game
extends Node2D
## Une partie en cours : relie joueur, décor, obstacles et score.
##
## Une nouvelle instance est créée à chaque partie : rejouer repart donc
## toujours d'un état propre.

## Position verticale du joueur, mesurée depuis le bas de l'écran.
const PLAYER_BOTTOM_OFFSET := 230.0

@onready var background: Node2D = $Background
@onready var player: PlayerController = $Player

var area_size := Vector2(720, 1280)


func _ready() -> void:
	area_size = get_viewport_rect().size
	background.set_area_size(area_size)
	player.setup(area_size.x, area_size.y - PLAYER_BOTTOM_OFFSET)
