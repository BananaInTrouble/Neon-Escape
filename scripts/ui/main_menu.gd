class_name MainMenu
extends CanvasLayer
## Écran d'accueil : titre, meilleur score, bouton Play.

signal play_requested
signal sound_toggled(enabled: bool)
signal music_toggled(enabled: bool)
signal credits_requested

@onready var background: Node2D = $Background
@onready var best_label: Label = %BestLabel
@onready var play_button: Button = %PlayButton
@onready var sound_button: Button = %SoundButton
@onready var music_button: Button = %MusicButton
@onready var credits_button: Button = %CreditsButton
@onready var title: Control = %TitleBox

var _sound_enabled := true
var _music_enabled := true


func _ready() -> void:
	play_button.pressed.connect(play_requested.emit)
	sound_button.pressed.connect(_on_sound_pressed)
	music_button.pressed.connect(_on_music_pressed)
	credits_button.pressed.connect(credits_requested.emit)
	set_sound_enabled(_sound_enabled)
	set_music_enabled(_music_enabled)
	var glow := create_tween().set_loops()
	glow.tween_property(title, "modulate:a", 0.75, 1.2).set_trans(Tween.TRANS_SINE)
	glow.tween_property(title, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE)
	get_viewport().size_changed.connect(_resize_background)
	_resize_background()
	visibility_changed.connect(_on_visibility_changed)


func show_best(best: int) -> void:
	best_label.text = "Record : %d" % best
	best_label.visible = best > 0


## Met à jour l'affichage du bouton son (sans émettre de signal).
func set_sound_enabled(enabled: bool) -> void:
	_sound_enabled = enabled
	if sound_button:
		sound_button.text = "SOUND : ON" if enabled else "SOUND : OFF"


func _on_sound_pressed() -> void:
	set_sound_enabled(not _sound_enabled)
	sound_toggled.emit(_sound_enabled)


## Met à jour l'affichage du bouton musique (sans émettre de signal).
func set_music_enabled(enabled: bool) -> void:
	_music_enabled = enabled
	if music_button:
		music_button.text = "MUSIC : ON" if enabled else "MUSIC : OFF"


func _on_music_pressed() -> void:
	set_music_enabled(not _music_enabled)
	music_toggled.emit(_music_enabled)


func _resize_background() -> void:
	background.set_area_size(get_viewport().get_visible_rect().size)
	background.scroll_speed = 60.0  # défilement lent et apaisant


func _on_visibility_changed() -> void:
	if visible:
		play_button.grab_focus.call_deferred()
