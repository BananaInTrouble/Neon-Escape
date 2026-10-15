extends Node2D
## Décor : séparations lumineuses entre les trois voies.

const LINE_COLOR := Color(0.0, 0.898, 1.0, 0.18)
const GUIDE_COLOR := Color(0.0, 0.898, 1.0, 0.05)

var _size := Vector2.ZERO


func set_area_size(size: Vector2) -> void:
	_size = size
	queue_redraw()


func _draw() -> void:
	if _size == Vector2.ZERO:
		return
	var lane_w := Lanes.width_of(_size.x)
	# Bandes très légères au centre de chaque voie.
	for lane in Lanes.COUNT:
		var x := Lanes.x_for(lane, _size.x)
		draw_rect(Rect2(x - lane_w * 0.3, 0.0, lane_w * 0.6, _size.y), GUIDE_COLOR)
	# Séparations entre les voies.
	for i in range(1, Lanes.COUNT):
		var x := lane_w * i
		draw_line(Vector2(x, 0.0), Vector2(x, _size.y), LINE_COLOR, 2.0)
