class_name MusicPlayer
extends Node
## Musique de fond des parties.
##
## - Un morceau différent à chaque partie (tirage au hasard, jamais deux fois de suite).
## - Le morceau boucle tant que la partie dure ; il se met en pause avec le jeu.
## - Fondu d'entrée au départ, fondu de sortie à la fin de partie.
## - Sans aucun fichier de musique, tout fonctionne (simplement en silence).

## Volume de la musique, sous les effets sonores pour qu'ils restent audibles.
@export var volume_db := -8.0
@export var fade_in := 0.6
@export var fade_out := 0.8

const SILENT_DB := -40.0

var enabled := true
var rng := RandomNumberGenerator.new()
## Chemin du morceau en cours ("" si aucun).
var current_path := ""
var _paths: PackedStringArray = []
var _player := AudioStreamPlayer.new()
var _fade: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # la pause est gérée explicitement
	add_child(_player)
	rng.randomize()
	if _paths.is_empty():
		_paths = MusicTracks.available_paths()


## Remplace la liste des morceaux (utilisé par les tests).
func set_track_paths(paths: PackedStringArray) -> void:
	_paths = paths


func track_count() -> int:
	return _paths.size()


func is_playing() -> bool:
	return _player.playing and not _player.stream_paused


## Démarre un nouveau morceau pour une nouvelle partie.
func play_next() -> void:
	stop()
	if not enabled or _paths.is_empty():
		return
	current_path = _pick_next()
	var stream: AudioStream = load(current_path)
	if stream == null:
		push_warning("Musique illisible : %s" % current_path)
		current_path = ""
		return
	if "loop" in stream:
		stream.loop = true
	_player.stream = stream
	_player.volume_db = SILENT_DB
	_player.play()
	_fade_to(volume_db, fade_in)


func set_paused(paused: bool) -> void:
	_player.stream_paused = paused


## Fin de partie : la musique s'éteint en douceur.
func fade_out_and_stop() -> void:
	if not _player.playing:
		return
	_fade_to(SILENT_DB, fade_out).finished.connect(stop)


func stop() -> void:
	if _fade:
		_fade.kill()
	_player.stop()
	_player.stream_paused = false


func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		stop()


func _pick_next() -> String:
	if _paths.size() == 1:
		return _paths[0]
	var choice := current_path
	while choice == current_path:
		choice = _paths[rng.randi_range(0, _paths.size() - 1)]
	return choice


func _fade_to(target_db: float, duration: float) -> Tween:
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(_player, "volume_db", target_db, duration)
	return _fade
