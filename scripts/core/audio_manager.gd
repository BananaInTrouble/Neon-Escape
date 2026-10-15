class_name AudioManager
extends Node
## Effets sonores. Quelques lecteurs réutilisés à tour de rôle : plusieurs sons
## peuvent se superposer sans créer de nœud à chaque lecture.

const SOUNDS: Dictionary = {
	&"move": preload("res://assets/audio/sfx/move.wav"),
	&"score": preload("res://assets/audio/sfx/score.wav"),
	&"crash": preload("res://assets/audio/sfx/crash.wav"),
	&"record": preload("res://assets/audio/sfx/record.wav"),
	&"click": preload("res://assets/audio/sfx/click.wav"),
}
const VOICES := 4

var enabled := true
## Dernier son joué (pour les tests).
var last_played: StringName = &""
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # les clics fonctionnent aussi en pause
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		for player in _players:
			player.stop()


func play(sound: StringName) -> void:
	if not enabled:
		return
	var stream: AudioStream = SOUNDS.get(sound)
	if stream == null:
		push_warning("Son inconnu : %s" % sound)
		return
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = stream
	player.play()
	last_played = sound
