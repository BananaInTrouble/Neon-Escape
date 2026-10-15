extends TestCase
## Tests d'intégration sur la vraie scène principale.


var main: GameManager


func before_each() -> void:
	main = create_main()
	main.start_game()


func after_each() -> void:
	tree.paused = false
	main.queue_free()
	delete_test_save()


func _block_center_on_player() -> void:
	var p: Array[bool] = [false, true, false]
	main.game.spawner.spawn_row(p, main.game.player.position.y)


func test_game_starts_and_obstacles_move() -> void:
	assert_eq(main.state.current, GameState.State.PLAYING)
	await wait_physics_frames(10)
	var spawner := main.game.spawner
	assert_true(spawner.active_count() > 0, "Une rangée est apparue")
	var obstacle: Obstacle = spawner._active[0]
	var y0 := obstacle.position.y
	await wait_physics_frames(10)
	assert_true(obstacle.position.y > y0, "Les obstacles descendent")


func test_collision_ends_game_once() -> void:
	var game_overs := [0]
	main.state.changed.connect(func(_f, to):
		if to == GameState.State.GAME_OVER:
			game_overs[0] += 1)
	_block_center_on_player()
	await wait_physics_frames(5)
	assert_eq(main.state.current, GameState.State.GAME_OVER)
	# Collisions supplémentaires simulées : ignorées.
	main.game.player.hit.emit()
	main.end_game()
	await wait_physics_frames(5)
	assert_eq(game_overs[0], 1, "Une seule fin de partie")
	assert_false(main.game_over_screen.visible, "Écran caché le temps de voir l'explosion")
	await tree.create_timer(GameManager.GAME_OVER_REVEAL_DELAY + 0.1).timeout
	assert_true(main.game_over_screen.visible, "Écran Game Over affiché")
	assert_eq(game_overs[0], 1, "Toujours une seule fin de partie")
	assert_false(main.game.spawner.running, "Obstacles arrêtés")


func test_score_counts_passed_rows() -> void:
	var p: Array[bool] = [true, false, false]
	main.game.spawner.spawn_row(p, main.game.player.position.y - 10.0)
	await wait_physics_frames(30)
	assert_eq(main.score.score, 1)
	assert_eq(main.hud.score_label.text, "1")


func test_retry_starts_clean_game() -> void:
	var p: Array[bool] = [true, false, false]
	main.game.spawner.spawn_row(p, main.game.player.position.y - 10.0)
	await wait_physics_frames(30)
	var old_game := main.game
	_block_center_on_player()
	await wait_physics_frames(5)
	assert_eq(main.state.current, GameState.State.GAME_OVER)
	main.game_over_screen.retry_requested.emit()
	await wait_frames(2)
	assert_eq(main.state.current, GameState.State.PLAYING)
	assert_true(main.game != old_game, "Nouvelle instance de partie")
	assert_false(is_instance_valid(old_game), "Ancienne partie libérée")
	assert_eq(main.score.score, 0, "Score remis à zéro")
	assert_eq(main.score.best, 1, "Record conservé")
	assert_eq(main.game.player.lane, Lanes.CENTER)
	assert_false(main.game_over_screen.visible)


func test_retry_button_enabled_after_short_delay() -> void:
	_block_center_on_player()
	await wait_physics_frames(5)
	await tree.create_timer(GameManager.GAME_OVER_REVEAL_DELAY + 0.05).timeout
	assert_true(main.game_over_screen.visible)
	assert_true(main.game_over_screen.retry_button.disabled, "Bouton bloqué juste après l'apparition")
	await tree.create_timer(GameOverScreen.INPUT_DELAY + 0.1).timeout
	assert_false(main.game_over_screen.retry_button.disabled, "Bouton actif ensuite")


func test_difficulty_drives_spawner_and_stops_on_game_over() -> void:
	var difficulty := main.game.difficulty
	assert_almost_eq(main.game.spawner.speed, difficulty.start_speed, 1.0, "Vitesse de départ")
	difficulty.elapsed = 45.0
	await wait_physics_frames(2)
	assert_almost_eq(main.game.spawner.speed, difficulty.speed(45.0), 2.0, "Vitesse suit la difficulté")
	assert_true(main.game.spawner.speed > difficulty.start_speed)
	_block_center_on_player()
	await wait_physics_frames(5)
	var frozen := difficulty.elapsed
	await wait_physics_frames(10)
	assert_eq(difficulty.elapsed, frozen, "Le temps de survie s'arrête à la fin de partie")


func test_retry_resets_difficulty() -> void:
	main.game.difficulty.elapsed = 80.0
	_block_center_on_player()
	await wait_physics_frames(5)
	main.game_over_screen.retry_requested.emit()
	await wait_physics_frames(2)
	assert_true(main.game.difficulty.elapsed < 0.5, "Nouvelle partie = difficulté de départ")
	assert_almost_eq(main.game.spawner.speed, main.game.difficulty.start_speed, 1.0)
