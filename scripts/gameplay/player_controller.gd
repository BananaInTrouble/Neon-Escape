class_name PlayerController
extends Area2D
## Le noyau lumineux : position sur les voies, déplacements et détection de collision.

signal hit
signal lane_changed(lane: int)

const CORE_COLOR := Color(0.91, 0.96, 1.0)
const GLOW_COLOR := Color(0.0, 0.898, 1.0)

## Durée de l'animation de changement de voie (secondes).
@export var move_duration := 0.09
## Rayon visuel de l'orbe (la zone de collision est un peu plus petite, par équité).
@export var visual_radius := 34.0

var lane: int = Lanes.CENTER
var _area_width := 720.0
var _tween: Tween


func _ready() -> void:
	area_entered.connect(_on_area_entered)


## Place le joueur sur la voie centrale, à la hauteur donnée.
func setup(area_width: float, y: float) -> void:
	_area_width = area_width
	lane = Lanes.CENTER
	position = Vector2(Lanes.x_for(lane, _area_width), y)


## Déplace le joueur de [param direction] voies (-1 = gauche, +1 = droite).
## Retourne false si le joueur est déjà au bord.
func move_by(direction: int) -> bool:
	var target := Lanes.clamp_lane(lane + direction)
	if target == lane:
		return false
	lane = target
	_animate_to(Lanes.x_for(lane, _area_width))
	lane_changed.emit(lane)
	return true


func _animate_to(target_x: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position:x", target_x, move_duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_area_entered(_area: Area2D) -> void:
	hit.emit()


func _draw() -> void:
	# Halo en anneaux concentriques (léger, sans shader).
	for i in 4:
		var t := float(i) / 4.0
		draw_circle(Vector2.ZERO, visual_radius * (1.9 - t * 0.6), Color(GLOW_COLOR, 0.05 + t * 0.04))
	draw_circle(Vector2.ZERO, visual_radius, GLOW_COLOR)
	draw_circle(Vector2.ZERO, visual_radius * 0.5, CORE_COLOR)
