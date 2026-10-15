class_name ObstacleSpawner
extends Node2D
## Génère des rangées d'obstacles toujours franchissables, les fait descendre
## et libère celles qui sortent de l'écran.
##
## Les rangées sont créées en fonction de la distance parcourue (et non du temps) :
## l'écart entre deux rangées est donc exactement [member row_spacing] pixels.

## Émis une fois par rangée franchie par le joueur.
signal row_passed

const OBSTACLE_SCENE: PackedScene = preload("res://scenes/obstacles/obstacle.tscn")
## Hauteur au-dessus de l'écran où naissent les obstacles.
const SPAWN_MARGIN := 60.0

## Vitesse de descente (pixels par seconde).
@export var speed := 420.0
## Distance verticale entre deux rangées (pixels).
@export var row_spacing := 520.0
## Probabilité qu'une rangée bloque deux voies au lieu d'une.
@export_range(0.0, 1.0) var double_chance := 0.3

var rng := RandomNumberGenerator.new()
var running := false
var _area_size := Vector2(720, 1280)
var _pass_line_y := 1000.0
var _distance_since_spawn := 0.0
var _active: Array[Obstacle] = []


## [param pass_line_y] : ligne (sous le joueur) à partir de laquelle une rangée est franchie.
func setup(area_size: Vector2, pass_line_y: float) -> void:
	_area_size = area_size
	_pass_line_y = pass_line_y


func start() -> void:
	running = true
	# La première rangée apparaît immédiatement (elle met ~2 s à atteindre le joueur).
	_distance_since_spawn = row_spacing


func stop() -> void:
	running = false


func active_count() -> int:
	return _active.size()


func _physics_process(delta: float) -> void:
	if running:
		step(speed * delta)


## Fait avancer le monde de [param dy] pixels (séparé de _physics_process pour les tests).
func step(dy: float) -> void:
	for i in range(_active.size() - 1, -1, -1):
		var obstacle := _active[i]
		if obstacle.advance(dy, _pass_line_y, _area_size.y):
			_active.remove_at(i)
			obstacle.queue_free()
	_distance_since_spawn += dy
	if _distance_since_spawn >= row_spacing:
		# On reporte le surplus pour garder un espacement exact entre les rangées.
		var overflow := _distance_since_spawn - row_spacing
		_distance_since_spawn = overflow
		spawn_row(generate_pattern(rng, double_chance), -SPAWN_MARGIN + overflow)


## Crée une rangée. [param pattern][i] = true si la voie i est bloquée.
func spawn_row(pattern: Array[bool], y: float) -> void:
	assert(is_passable(pattern), "Rangée infranchissable")
	var scorer_assigned := false
	for lane in Lanes.COUNT:
		if not pattern[lane]:
			continue
		var obstacle: Obstacle = OBSTACLE_SCENE.instantiate()
		obstacle.position = Vector2(Lanes.x_for(lane, _area_size.x), y)
		if not scorer_assigned:
			obstacle.awards_point = true
			obstacle.passed.connect(row_passed.emit)
			scorer_assigned = true
		add_child(obstacle)
		_active.append(obstacle)


## Tire une rangée au hasard : 1 ou 2 voies bloquées, toujours au moins une libre.
static func generate_pattern(random: RandomNumberGenerator, chance_of_double: float) -> Array[bool]:
	var pattern: Array[bool] = []
	pattern.resize(Lanes.COUNT)
	if random.randf() < chance_of_double:
		var free_lane := random.randi_range(0, Lanes.COUNT - 1)
		for lane in Lanes.COUNT:
			pattern[lane] = lane != free_lane
	else:
		var blocked_lane := random.randi_range(0, Lanes.COUNT - 1)
		for lane in Lanes.COUNT:
			pattern[lane] = lane == blocked_lane
	return pattern


static func is_passable(pattern: Array[bool]) -> bool:
	return pattern.size() == Lanes.COUNT and pattern.has(false)
