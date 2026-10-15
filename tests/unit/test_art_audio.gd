extends TestCase
## Étape 8 : sons, réglage du son, effets visuels.

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


func test_audio_manager_plays_known_sounds_only() -> void:
	var audio := main.audio
	for sound in AudioManager.SOUNDS:
		audio.play(sound)
		assert_eq(String(audio.last_played), String(sound))
	audio.last_played = &""
	audio.play(&"inconnu")
	assert_eq(audio.last_played, &"", "Son inconnu ignoré sans plantage")
	audio.set_enabled(false)
	audio.play(&"score")
	assert_eq(audio.last_played, &"", "Aucun son quand le son est coupé")


func test_game_events_play_sounds() -> void:
	main.start_game()
	main.game.player.move_by(-1)
	assert_eq(main.audio.last_played, &"move", "Changement de voie")
	var p: Array[bool] = [false, true, false]
	main.game.spawner.spawn_row(p, main.game.player.position.y - 10.0)
	for i in 60:
		if main.score.score > 0:
			break
		await wait_physics_frames(1)
	assert_eq(main.audio.last_played, &"score", "Point marqué")
	main.game.player.move_by(1)
	await _crash()
	assert_eq(main.audio.last_played, &"crash", "Collision")


func test_sound_setting_toggle_and_persistence() -> void:
	assert_true(main.audio.enabled, "Son activé par défaut")
	assert_eq(main.main_menu.sound_button.text, "SOUND : ON")
	main.main_menu.sound_button.pressed.emit()
	assert_false(main.audio.enabled)
	assert_eq(main.main_menu.sound_button.text, "SOUND : OFF")
	main.queue_free()
	await wait_frames(2)
	main = create_main(true)
	assert_false(main.audio.enabled, "Réglage relu après redémarrage")
	assert_eq(main.main_menu.sound_button.text, "SOUND : OFF")


func test_record_and_sound_setting_do_not_overwrite_each_other() -> void:
	var save := SaveManager.new(TEST_SAVE_PATH)
	save.save_sound_enabled(false)
	save.save_best(25)
	var reread := SaveManager.new(TEST_SAVE_PATH)
	assert_eq(reread.load_best(), 25)
	assert_false(reread.load_sound_enabled(), "Le record n'a pas effacé le réglage")
	reread.save_sound_enabled(true)
	assert_eq(SaveManager.new(TEST_SAVE_PATH).load_best(), 25, "Le réglage n'a pas effacé le record")


func test_invalid_sound_setting_defaults_to_on() -> void:
	var f := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f.store_string('[settings]\nsound_enabled="peut-être"\n')
	f.close()
	assert_true(SaveManager.new(TEST_SAVE_PATH).load_sound_enabled())


func test_background_scrolls_with_game_and_stops() -> void:
	main.start_game()
	var bg := main.game.background
	await wait_physics_frames(3)
	var o1: float = bg.offset
	await wait_frames(10)
	assert_true(bg.offset != o1, "Le décor défile pendant la partie")
	main.pause_game()
	var o2: float = bg.offset
	await wait_frames(10)
	assert_eq(bg.offset, o2, "Le décor est figé en pause")
	main.resume_game()
	await _crash()
	var o3: float = bg.offset
	await wait_frames(10)
	assert_eq(bg.offset, o3, "Le décor s'arrête après la collision")


func test_squash_is_visual_only() -> void:
	main.start_game()
	var player := main.game.player
	var shape: CircleShape2D = player.get_node("CollisionShape2D").shape
	var radius := shape.radius
	player.move_by(1)
	assert_true(player.visual.scale != Vector2.ONE, "Le dessin s'étire")
	assert_eq(player.scale, Vector2.ONE, "Le joueur (et sa collision) ne change pas d'échelle")
	assert_eq(shape.radius, radius)
	await wait_frames(30)
	assert_almost_eq(player.visual.scale.x, 1.0, 0.01, "Le dessin revient à la normale")


func test_crash_spawns_burst_and_hides_orb() -> void:
	main.start_game()
	await _crash()
	var bursts := 0
	for child in main.game.get_children():
		if child is CPUParticles2D and child.one_shot:
			bursts += 1
	assert_eq(bursts, 1, "Une explosion")
	assert_false(main.game.player.visual.visible, "L'orbe a disparu")
