class_name DifficultyManager
extends Node
## Seul endroit où se règle la difficulté.
##
## La difficulté dépend du temps de survie : elle progresse de façon linéaire
## de « départ » à « maximum » pendant [member ramp_duration] secondes, puis plafonne.
## Toutes les valeurs ci-dessous sont modifiables dans l'inspecteur de Godot
## (nœud DifficultyManager de scenes/game/game.tscn) sans toucher au code.

@export_group("Vitesse des obstacles (pixels/seconde)")
@export var start_speed := 560.0
@export var max_speed := 1150.0

@export_group("Temps entre deux rangées (secondes)")
@export var start_row_interval := 0.95
@export var min_row_interval := 0.52

@export_group("Rangées à deux voies bloquées (probabilité)")
@export_range(0.0, 1.0) var start_double_chance := 0.3
@export_range(0.0, 1.0) var max_double_chance := 0.7

@export_group("Progression et sécurité")
## Durée (secondes) pour passer de la difficulté de départ au maximum.
@export var ramp_duration := 75.0
## Temps minimal garanti entre deux rangées, quelles que soient les valeurs ci-dessus.
## 0,5 s laisse le temps de traverser deux voies (2 touchers + 2 × 0,09 s d'animation).
@export var safety_min_row_interval := 0.5
## Écart vertical minimal entre deux rangées (obstacle + orbe + marge), en pixels.
@export var safety_min_row_spacing := 260.0

## Temps de survie de la partie en cours (secondes). N'avance pas pendant la pause.
var elapsed := 0.0
var running := false


func start() -> void:
	elapsed = 0.0
	running = true


func stop() -> void:
	running = false


func _physics_process(delta: float) -> void:
	if running:
		elapsed += delta


## Avancement de 0 (début) à 1 (difficulté maximale).
func progress(time: float = elapsed) -> float:
	if ramp_duration <= 0.0:
		return 1.0
	return clampf(time / ramp_duration, 0.0, 1.0)


func speed(time: float = elapsed) -> float:
	return lerpf(start_speed, max_speed, progress(time))


## Temps entre deux rangées, jamais sous le minimum de sécurité.
func row_interval(time: float = elapsed) -> float:
	var interval := lerpf(start_row_interval, min_row_interval, progress(time))
	return maxf(interval, safety_min_row_interval)


## Écart en pixels entre deux rangées : c'est ce qu'utilise le générateur.
func row_spacing(time: float = elapsed) -> float:
	return maxf(speed(time) * row_interval(time), safety_min_row_spacing)


func double_chance(time: float = elapsed) -> float:
	return clampf(lerpf(start_double_chance, max_double_chance, progress(time)), 0.0, 1.0)


## Applique les paramètres du moment au générateur (sans allocation, appelé à chaque frame).
func apply_to(spawner: ObstacleSpawner) -> void:
	spawner.speed = speed()
	spawner.row_spacing = row_spacing()
	spawner.double_chance = double_chance()
