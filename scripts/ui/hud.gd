class_name Hud
extends CanvasLayer
## Affichage pendant la partie (score, bouton Pause). Ne contient aucune règle de jeu.

signal pause_requested

@onready var score_label: Label = %ScoreLabel
@onready var pause_button: Button = %PauseButton


func _ready() -> void:
	pause_button.pressed.connect(pause_requested.emit)


func show_score(score: int) -> void:
	score_label.text = str(score)
