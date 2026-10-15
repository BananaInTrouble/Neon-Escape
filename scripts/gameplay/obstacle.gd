class_name Obstacle
extends Area2D
## Un bloc d'obstacle. Il est déplacé par l'ObstacleSpawner (tous à la même vitesse)
## et signale une seule fois qu'il a été franchi.

signal passed

const FILL_COLOR := Color(1.0, 0.169, 0.839)
const CORE_COLOR := Color(1.0, 0.75, 0.96)

## Taille affichée. La zone de collision (dans la scène) est un peu plus petite,
## pour que les frôlements ne soient pas punis injustement.
@export var visual_size := Vector2(168, 56)

## Seul un obstacle par rangée rapporte un point.
var awards_point := false
var has_scored := false


## Descend de [param dy] pixels. Émet [signal passed] une seule fois quand le haut
## de l'obstacle dépasse [param pass_line_y]. Retourne true s'il est sorti de l'écran.
func advance(dy: float, pass_line_y: float, despawn_y: float) -> bool:
	position.y += dy
	var top := position.y - visual_size.y * 0.5
	if awards_point and not has_scored and top > pass_line_y:
		has_scored = true
		passed.emit()
	return top > despawn_y


func _draw() -> void:
	var rect := Rect2(-visual_size * 0.5, visual_size)
	draw_rect(rect.grow(10.0), Color(FILL_COLOR, 0.10))
	draw_rect(rect.grow(4.0), Color(FILL_COLOR, 0.25))
	draw_rect(rect, FILL_COLOR)
	draw_rect(rect.grow(-visual_size.y * 0.3), CORE_COLOR)
