class_name CreditsScreen
extends CanvasLayer
## Écran des crédits (obligatoire pour les musiques sous licence CC-BY).

signal closed

@onready var text_label: Label = %CreditsText
@onready var back_button: Button = %BackButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	back_button.pressed.connect(closed.emit)
	text_label.text = build_text()
	hide()


static func build_text() -> String:
	return "\n".join([
		"MUSIQUE",
		"",
		MusicTracks.credits_text(),
		"",
		"CC0 : domaine public, aucune restriction.",
		"CC-BY 4.0 : creativecommons.org/licenses/by/4.0",
		"Morceaux disponibles sur opengameart.org.",
		"",
		"JEU, GRAPHISMES ET EFFETS SONORES",
		"",
		"Neon Escape — créés pour le jeu avec Godot Engine",
		"(godotengine.org, licence MIT).",
	])
