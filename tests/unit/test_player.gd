extends TestCase

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

var player: PlayerController


func before_each() -> void:
	player = PLAYER_SCENE.instantiate()
	tree.root.add_child(player)
	player.setup(720.0, 1000.0)


func after_each() -> void:
	player.queue_free()


func test_lane_positions() -> void:
	assert_eq(Lanes.x_for(Lanes.LEFT, 720.0), 120.0)
	assert_eq(Lanes.x_for(Lanes.CENTER, 720.0), 360.0)
	assert_eq(Lanes.x_for(Lanes.RIGHT, 720.0), 600.0)


func test_starts_in_center_lane() -> void:
	assert_eq(player.lane, Lanes.CENTER)
	assert_eq(player.position, Vector2(360.0, 1000.0))


func test_cannot_leave_lanes() -> void:
	assert_true(player.move_by(-1))
	assert_eq(player.lane, Lanes.LEFT)
	assert_false(player.move_by(-1), "Bord gauche")
	assert_eq(player.lane, Lanes.LEFT)
	player.move_by(1)
	player.move_by(1)
	assert_eq(player.lane, Lanes.RIGHT)
	assert_false(player.move_by(1), "Bord droit")
	assert_eq(player.lane, Lanes.RIGHT)


func test_movement_reaches_lane_center() -> void:
	player.move_by(1)
	await wait_frames(30)  # bien plus que la durée de l'animation
	assert_almost_eq(player.position.x, 600.0, 0.5)


func _tap(x: float) -> void:
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = Vector2(x, 600.0)
	tree.root.push_input(touch, true)  # coordonnées de la zone de jeu


func _key(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	tree.root.push_input(ev)


func test_tap_direction() -> void:
	assert_eq(PlayerController.direction_for_tap(10.0, 720.0), -1)
	assert_eq(PlayerController.direction_for_tap(359.0, 720.0), -1)
	assert_eq(PlayerController.direction_for_tap(360.0, 720.0), 1)
	assert_eq(PlayerController.direction_for_tap(710.0, 720.0), 1)


func test_touch_moves_player() -> void:
	_tap(100.0)
	assert_eq(player.lane, Lanes.LEFT, "Toucher à gauche")
	_tap(100.0)
	assert_eq(player.lane, Lanes.LEFT, "Reste dans les voies")
	_tap(650.0)
	_tap(650.0)
	_tap(650.0)
	assert_eq(player.lane, Lanes.RIGHT, "Toucher à droite")


func test_touch_release_is_ignored() -> void:
	var release := InputEventScreenTouch.new()
	release.pressed = false
	release.position = Vector2(100.0, 600.0)
	tree.root.push_input(release, true)
	assert_eq(player.lane, Lanes.CENTER)


func test_keyboard_moves_player() -> void:
	_key("move_left")
	assert_eq(player.lane, Lanes.LEFT)
	_key("move_right")
	_key("move_right")
	assert_eq(player.lane, Lanes.RIGHT)


func test_disabled_controls_ignore_input() -> void:
	player.controls_enabled = false
	_tap(100.0)
	_key("move_right")
	assert_eq(player.lane, Lanes.CENTER)
