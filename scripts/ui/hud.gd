class_name Hud
extends CanvasLayer
## Affichage pendant la partie. Ne contient aucune règle de jeu.

@onready var score_label: Label = %ScoreLabel


func show_score(score: int) -> void:
	score_label.text = str(score)
