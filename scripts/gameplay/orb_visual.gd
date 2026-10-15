extends Node2D
## Dessin du noyau lumineux (séparé de la logique : on peut l'étirer ou le cacher
## sans toucher à la zone de collision du joueur).

const CORE_COLOR := Color(0.91, 0.96, 1.0)
const GLOW_COLOR := Color(0.0, 0.898, 1.0)

@export var radius := 34.0

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 1.0 + 0.07 * sin(_time * 5.0)
	# Halo en anneaux concentriques (léger, sans shader).
	for i in 5:
		var t := float(i) / 5.0
		draw_circle(Vector2.ZERO, radius * (2.1 - t * 0.9) * pulse, Color(GLOW_COLOR, 0.035 + t * 0.045))
	draw_circle(Vector2.ZERO, radius, GLOW_COLOR)
	draw_circle(Vector2.ZERO, radius * 0.55, CORE_COLOR)
