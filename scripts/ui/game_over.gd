class_name GameOverScreen
extends CanvasLayer
## Écran de fin de partie. Émet des signaux, ne décide de rien lui-même.

signal retry_requested
signal main_menu_requested

## Délai avant que les boutons répondent, pour qu'un toucher frénétique
## juste après la collision ne relance pas la partie par erreur.
const INPUT_DELAY := 0.3

@onready var score_label: Label = %ScoreLabel
@onready var best_label: Label = %BestLabel
@onready var record_label: Label = %RecordLabel
@onready var retry_button: Button = %RetryButton
@onready var main_menu_button: Button = %MainMenuButton

var _input_delay_timer := Timer.new()
var _record_tween: Tween


func _ready() -> void:
	retry_button.pressed.connect(retry_requested.emit)
	main_menu_button.pressed.connect(main_menu_requested.emit)
	_input_delay_timer.one_shot = true
	_input_delay_timer.wait_time = INPUT_DELAY
	_input_delay_timer.timeout.connect(_enable_buttons)
	add_child(_input_delay_timer)
	hide()


func show_result(score: int, best: int, is_new_record: bool) -> void:
	score_label.text = "Score : %d" % score
	best_label.text = "Record : %d" % best
	record_label.visible = is_new_record
	if _record_tween:
		_record_tween.kill()
	if is_new_record:
		_record_tween = create_tween().set_loops()
		_record_tween.tween_property(record_label, "modulate:a", 0.35, 0.35)
		_record_tween.tween_property(record_label, "modulate:a", 1.0, 0.35)
	_set_buttons_disabled(true)
	show()
	_input_delay_timer.start()


func _enable_buttons() -> void:
	_set_buttons_disabled(false)
	retry_button.grab_focus()


func _set_buttons_disabled(disabled: bool) -> void:
	retry_button.disabled = disabled
	main_menu_button.disabled = disabled
