class_name MusicPlayer
extends Node
## Musique de fond (menu principal et parties).
##
## - Un morceau tiré au hasard au menu, puis un autre à chaque partie
##   (jamais deux fois le même de suite).
## - Le morceau boucle tant que la partie dure ; il se met en pause avec le jeu.
## - Fondu d'entrée au départ, fondu de sortie à la fin de partie.
## - Sans aucun fichier de musique, tout fonctionne (simplement en silence).

## Volume de la musique en partie, sous les effets sonores pour qu'ils restent audibles.
@export var volume_db := -8.0
## Volume au menu, un peu plus doux.
@export var menu_volume_db := -12.0
@export var fade_in := 0.6
@export var fade_out := 0.8

const SILENT_DB := -40.0

var enabled := true
var rng := RandomNumberGenerator.new()
## Chemin du morceau en cours ("" si aucun).
var current_path := ""
## Vrai si le morceau en cours est celui du menu.
var in_menu := false
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


## Démarre un nouveau morceau (au hasard) pour une nouvelle partie.
func play_next() -> void:
	_start_random(volume_db)
	in_menu = false


## Musique du menu principal : ne redémarre pas si elle joue déjà (ex. retour des crédits).
func play_menu() -> void:
	if in_menu and is_playing():
		return
	_start_random(menu_volume_db)
	in_menu = true


func _start_random(target_db: float) -> void:
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
	_fade_to(target_db, fade_in)


func set_paused(paused: bool) -> void:
	_player.stream_paused = paused


## Fin de partie : la musique s'éteint en douceur.
func fade_out_and_stop() -> void:
	if not _player.playing:
		return
	_fade_to(SILENT_DB, fade_out).finished.connect(stop)


func stop() -> void:
	in_menu = false
	if _fade:
		_fade.kill()
	_player.stop()
	_player.stream_paused = false


func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		stop()


## Rallume la musique adaptée à l'écran en cours (après réactivation du réglage).
func resume_context(menu: bool) -> void:
	if not enabled or is_playing():
		return
	if menu:
		play_menu()
	else:
		play_next()


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
