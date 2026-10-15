class_name MainMenu
extends CanvasLayer
## Écran d'accueil : titre, meilleur score, bouton Play.

signal play_requested

@onready var background: Node2D = $Background
@onready var best_label: Label = %BestLabel
@onready var play_button: Button = %PlayButton


func _ready() -> void:
	play_button.pressed.connect(play_requested.emit)
	get_viewport().size_changed.connect(_resize_background)
	_resize_background()
	visibility_changed.connect(_on_visibility_changed)


func show_best(best: int) -> void:
	best_label.text = "Record : %d" % best
	best_label.visible = best > 0


func _resize_background() -> void:
	background.set_area_size(get_viewport().get_visible_rect().size)


func _on_visibility_changed() -> void:
	if visible:
		play_button.grab_focus.call_deferred()
