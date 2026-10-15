class_name MainMenu
extends CanvasLayer
## Écran d'accueil : titre, meilleur score, bouton Play.

signal play_requested
signal sound_toggled(enabled: bool)

@onready var background: Node2D = $Background
@onready var best_label: Label = %BestLabel
@onready var play_button: Button = %PlayButton
@onready var sound_button: Button = %SoundButton
@onready var title: Control = %TitleBox

var _sound_enabled := true


func _ready() -> void:
	play_button.pressed.connect(play_requested.emit)
	sound_button.pressed.connect(_on_sound_pressed)
	set_sound_enabled(_sound_enabled)
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


func _resize_background() -> void:
	background.set_area_size(get_viewport().get_visible_rect().size)
	background.scroll_speed = 60.0  # défilement lent et apaisant


func _on_visibility_changed() -> void:
	if visible:
		play_button.grab_focus.call_deferred()
