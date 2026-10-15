class_name PauseMenu
extends CanvasLayer
## Menu affiché pendant la pause. Fonctionne alors que le gameplay est suspendu.

signal resume_requested
signal restart_requested
signal main_menu_requested

@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.pressed.connect(resume_requested.emit)
	restart_button.pressed.connect(restart_requested.emit)
	main_menu_button.pressed.connect(main_menu_requested.emit)
	visibility_changed.connect(_on_visibility_changed)
	hide()


func _on_visibility_changed() -> void:
	if visible:
		resume_button.grab_focus.call_deferred()
