class_name Hud
extends CanvasLayer
## Affichage pendant la partie (score, bouton Pause). Ne contient aucune règle de jeu.

signal pause_requested

@onready var score_label: Label = %ScoreLabel
@onready var pause_button: Button = %PauseButton

var _pop: Tween


func _ready() -> void:
	pause_button.pressed.connect(pause_requested.emit)


func show_score(score: int) -> void:
	score_label.text = str(score)
	if score > 0 and is_inside_tree():
		_pop_score()


func _pop_score() -> void:
	if _pop:
		_pop.kill()
	score_label.pivot_offset = score_label.size * 0.5
	score_label.scale = Vector2(1.35, 1.35)
	_pop = create_tween()
	_pop.tween_property(score_label, "scale", Vector2.ONE, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
