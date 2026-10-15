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
