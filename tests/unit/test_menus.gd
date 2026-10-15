extends TestCase
## Étape 6 : menu principal, pause, retour au menu, zones de sécurité.

const S := GameState.State

var main: GameManager


func before_each() -> void:
	main = create_main()


func after_each() -> void:
	tree.paused = false
	main.queue_free()
	delete_test_save()


func _crash() -> void:
	var p: Array[bool] = [false, true, false]
	main.game.spawner.spawn_row(p, main.game.player.position.y)
	await wait_physics_frames(5)


func test_starts_on_main_menu() -> void:
	assert_eq(main.state.current, S.MENU)
	assert_true(main.main_menu.visible, "Menu affiché")
	assert_false(main.hud.visible)
	assert_false(main.pause_menu.visible)
	assert_false(main.game_over_screen.visible)
	assert_true(main.game == null, "Aucune partie en cours")


func test_play_button_starts_game() -> void:
	main.main_menu.play_button.pressed.emit()
	assert_eq(main.state.current, S.PLAYING)
	assert_true(main.game != null)
	assert_true(main.hud.visible)
	assert_false(main.main_menu.visible)


func test_pause_really_freezes_gameplay() -> void:
	main.start_game()
	await wait_physics_frames(10)
	var obstacle: Obstacle = main.game.spawner._active[0]
	assert_true(main.pause_game())
	assert_true(tree.paused)
	assert_true(main.pause_menu.visible, "Menu pause affiché")
	var y := obstacle.position.y
	var elapsed := main.game.difficulty.elapsed
	await wait_physics_frames(30)
	assert_eq(obstacle.position.y, y, "Les obstacles ne bougent pas en pause")
	assert_eq(main.game.difficulty.elapsed, elapsed, "La difficulté n'avance pas en pause")
	assert_true(main.resume_game())
	assert_false(tree.paused)
	assert_false(main.pause_menu.visible)
	await wait_physics_frames(5)
	assert_true(obstacle.position.y > y, "Les obstacles repartent après la reprise")


func test_player_cannot_move_while_paused() -> void:
	main.start_game()
	main.pause_game()
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = Vector2(50, 900)
	tree.root.push_input(touch, true)
	assert_eq(main.game.player.lane, Lanes.CENTER)


func test_invalid_pause_requests_are_ignored() -> void:
	assert_false(main.pause_game(), "Pas de pause depuis le menu")
	main.start_game()
	assert_true(main.pause_game())
	assert_false(main.pause_game(), "Pas de double pause")
	main.resume_game()
	await _crash()
	assert_false(main.pause_game(), "Pas de pause après la défaite")
	assert_false(tree.paused)


func test_restart_from_pause_gives_clean_unpaused_game() -> void:
	main.start_game()
	await wait_physics_frames(10)
	var old_game := main.game
	main.pause_game()
	main.pause_menu.restart_button.pressed.emit()
	await wait_frames(2)
	assert_eq(main.state.current, S.PLAYING)
	assert_false(tree.paused, "Plus en pause")
	assert_false(is_instance_valid(old_game), "Ancienne partie libérée")
	assert_eq(main.score.score, 0)
	assert_false(main.pause_menu.visible)


func test_main_menu_from_pause() -> void:
	main.start_game()
	main.pause_game()
	main.pause_menu.main_menu_button.pressed.emit()
	await wait_frames(2)
	assert_eq(main.state.current, S.MENU)
	assert_false(tree.paused)
	assert_true(main.game == null)
	assert_true(main.main_menu.visible)
	assert_false(main.pause_menu.visible)


func test_main_menu_from_game_over_shows_best() -> void:
	main.start_game()
	var p: Array[bool] = [true, false, false]
	main.game.spawner.spawn_row(p, main.game.player.position.y - 10.0)
	await wait_physics_frames(30)
	await _crash()
	assert_eq(main.state.current, S.GAME_OVER)
	main.game_over_screen.main_menu_requested.emit()
	await wait_frames(2)
	assert_eq(main.state.current, S.MENU)
	assert_true(main.main_menu.best_label.visible, "Record affiché")
	assert_eq(main.main_menu.best_label.text, "Record : 1")


func test_pause_button_touch_pauses_without_moving_player() -> void:
	main.start_game()
	await wait_frames(2)  # laisse l'interface se mettre en place
	var center := main.hud.pause_button.get_global_rect().get_center()
	# Sur téléphone, un toucher produit un événement tactile ET un clic émulé.
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = center
	tree.root.push_input(touch, true)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = center
	tree.root.push_input(click, true)
	var release := click.duplicate()
	release.pressed = false
	tree.root.push_input(release, true)
	assert_eq(main.state.current, S.PAUSED, "Le bouton a mis en pause")
	assert_eq(main.game.player.lane, Lanes.CENTER, "Le joueur n'a pas bougé")


func test_keyboard_toggles_pause() -> void:
	main.start_game()
	var ev := InputEventAction.new()
	ev.action = "pause_game"
	ev.pressed = true
	tree.root.push_input(ev)
	assert_eq(main.state.current, S.PAUSED)
	tree.root.push_input(ev)
	assert_eq(main.state.current, S.PLAYING)


func test_app_going_to_background_pauses() -> void:
	main.start_game()
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_eq(main.state.current, S.PAUSED)
	assert_true(tree.paused)


func test_safe_area_insets() -> void:
	# Écran 1170×2532 avec encoche de 141 px en haut et barre de 102 px en bas.
	var insets := SafeAreaContainer.insets_in_viewport(
		Rect2(0, 141, 1170, 2532 - 141 - 102), Vector2(1170, 2532), Vector2(720, 1558))
	assert_almost_eq(insets[0], 0.0, 0.01)
	assert_almost_eq(insets[1], 141.0 * 720.0 / 1170.0, 0.5)
	assert_almost_eq(insets[2], 0.0, 0.01)
	assert_almost_eq(insets[3], 102.0 * 1558.0 / 2532.0, 0.5)
	var none := SafeAreaContainer.insets_in_viewport(Rect2(), Vector2.ZERO, Vector2(720, 1280))
	assert_eq(none, [0.0, 0.0, 0.0, 0.0] as Array[float], "Valeurs absentes : pas de marge")
