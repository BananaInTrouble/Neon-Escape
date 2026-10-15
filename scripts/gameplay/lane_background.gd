extends Node2D
## Décor : bandes des voies, séparations en tirets lumineux et grille légère
## qui défilent vers le bas à la vitesse du jeu (sensation de vitesse).

const LINE_COLOR := Color(0.0, 0.898, 1.0, 0.35)
const GUIDE_COLOR := Color(0.0, 0.898, 1.0, 0.045)
const GRID_COLOR := Color(1.0, 0.168, 0.839, 0.07)
const DASH := 46.0
const GAP := 34.0
const GRID_STEP := 160.0

## Vitesse de défilement (pixels/seconde). 0 = immobile.
var scroll_speed := 0.0
## Décalage courant du défilement (exposé pour les tests).
var offset := 0.0
var _size := Vector2.ZERO


func set_area_size(size: Vector2) -> void:
	_size = size
	queue_redraw()


func _process(delta: float) -> void:
	if scroll_speed <= 0.0:
		return
	# Modulo commun aux tirets et à la grille : le motif boucle sans saut visible.
	offset = fmod(offset + scroll_speed * delta, (DASH + GAP) * GRID_STEP)
	queue_redraw()


func _draw() -> void:
	if _size == Vector2.ZERO:
		return
	var lane_w := Lanes.width_of(_size.x)
	for lane in Lanes.COUNT:
		var x := Lanes.x_for(lane, _size.x)
		draw_rect(Rect2(x - lane_w * 0.3, 0.0, lane_w * 0.6, _size.y), GUIDE_COLOR)
	# Grille horizontale discrète.
	var grid_y := fmod(offset, GRID_STEP) - GRID_STEP
	while grid_y < _size.y:
		draw_line(Vector2(0.0, grid_y), Vector2(_size.x, grid_y), GRID_COLOR, 2.0)
		grid_y += GRID_STEP
	# Séparations en tirets.
	var period := DASH + GAP
	for i in range(1, Lanes.COUNT):
		var x := lane_w * i
		var y := fmod(offset, period) - period
		while y < _size.y:
			draw_line(Vector2(x, y), Vector2(x, y + DASH), LINE_COLOR, 3.0)
			y += period
