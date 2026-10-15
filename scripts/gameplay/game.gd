class_name Game
extends Node2D
## Une partie en cours : relie joueur, décor et obstacles.
##
## Une nouvelle instance est créée à chaque partie : rejouer repart donc
## toujours d'un état propre (aucun obstacle ni score hérité).

## Émis une seule fois, au premier contact avec un obstacle.
signal crashed
## Émis à chaque rangée d'obstacles franchie.
signal row_passed

## Position verticale du joueur, mesurée depuis le bas de l'écran.
const PLAYER_BOTTOM_OFFSET := 230.0

@onready var background: Node2D = $Background
@onready var player: PlayerController = $Player
@onready var spawner: ObstacleSpawner = $ObstacleSpawner
@onready var difficulty: DifficultyManager = $DifficultyManager

var area_size := Vector2(720, 1280)
var _crashed := false


func _ready() -> void:
	area_size = get_viewport_rect().size
	background.set_area_size(area_size)
	player.setup(area_size.x, area_size.y - PLAYER_BOTTOM_OFFSET)
	# Une rangée est franchie quand son haut dépasse le bas du joueur.
	spawner.setup(area_size, player.position.y + player.visual_radius)
	spawner.row_passed.connect(row_passed.emit)
	player.hit.connect(_on_player_hit)
	difficulty.start()
	difficulty.apply_to(spawner)
	spawner.start()


# Game est traité avant ses enfants : les réglages sont à jour avant que les obstacles bougent.
func _physics_process(_delta: float) -> void:
	difficulty.apply_to(spawner)


## Fige la partie (obstacles arrêtés, contrôles et collisions désactivés).
func stop() -> void:
	difficulty.stop()
	spawner.stop()
	player.controls_enabled = false
	player.set_deferred("monitoring", false)


func _on_player_hit() -> void:
	if _crashed:
		return
	_crashed = true
	crashed.emit()
