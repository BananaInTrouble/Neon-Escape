extends TestCase
## Étape 7 : sauvegarde locale du record.

const S := GameState.State

var save: SaveManager


func before_each() -> void:
	delete_test_save()
	save = SaveManager.new(TEST_SAVE_PATH)


func after_each() -> void:
	delete_test_save()


func _write_raw(text: String) -> void:
	var f := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func test_missing_file_gives_zero() -> void:
	assert_eq(save.load_best(), 0)


func test_save_then_load_in_new_instance() -> void:
	assert_true(save.save_best(42))
	assert_eq(SaveManager.new(TEST_SAVE_PATH).load_best(), 42, "Relu par une nouvelle instance")
	assert_false(FileAccess.file_exists(TEST_SAVE_PATH + ".tmp"), "Pas de fichier temporaire oublié")


func test_overwrite_keeps_latest_value() -> void:
	save.save_best(5)
	save.save_best(17)
	assert_eq(save.load_best(), 17)


func test_corrupted_file_does_not_block_and_can_be_repaired() -> void:
	_write_raw("\u0000ÿ garbage [[[ = = =")
	assert_eq(save.load_best(), 0, "Fichier illisible : record à 0")
	assert_true(save.save_best(9), "On peut réécrire par-dessus")
	assert_eq(save.load_best(), 9)


func test_invalid_values_are_rejected() -> void:
	for raw in ['[scores]\nbest=-5\n', '[scores]\nbest="beaucoup"\n',
			'[scores]\nbest=99999999999\n', '[scores]\nbest=3.5\n', '[scores]\nbest=[1, 2]\n']:
		_write_raw(raw)
		assert_eq(save.load_best(), 0, "Valeur refusée : %s" % raw.strip_edges())
	_write_raw('[scores]\nbest=12.0\n')
	assert_eq(save.load_best(), 12, "Un nombre décimal entier est accepté")


func test_sanitize_score() -> void:
	assert_eq(SaveManager.sanitize_score(7), 7)
	assert_eq(SaveManager.sanitize_score(-1), 0)
	assert_eq(SaveManager.sanitize_score(null), 0)
	assert_eq(SaveManager.sanitize_score(INF), 0)
	assert_eq(SaveManager.sanitize_score(NAN), 0)


func _play_and_score(main: GameManager, points: int) -> void:
	main.start_game()
	for i in points:
		var p: Array[bool] = [true, false, false]
		main.game.spawner.spawn_row(p, main.game.player.position.y - 10.0)
		# Attend que la rangée soit franchie (un point) avant la suivante.
		var target := main.score.score + 1
		for f in 60:
			if main.score.score >= target:
				break
			await wait_physics_frames(1)
	var wall: Array[bool] = [false, true, false]
	main.game.spawner.spawn_row(wall, main.game.player.position.y)
	await wait_physics_frames(5)


func test_record_survives_restart() -> void:
	var main := create_main()
	assert_eq(main.score.best, 0)
	await _play_and_score(main, 3)
	assert_eq(main.state.current, S.GAME_OVER)
	assert_eq(main.score.best, 3)
	main.queue_free()
	await wait_frames(2)
	# « Redémarrage » : une toute nouvelle scène principale relit le fichier.
	var restarted := create_main(true)
	assert_eq(restarted.score.best, 3, "Record relu après redémarrage")
	assert_eq(restarted.main_menu.best_label.text, "Record : 3", "Affiché dans le menu")
	assert_true(restarted.main_menu.best_label.visible)
	restarted.queue_free()


func test_saves_only_on_new_record() -> void:
	var main := create_main()
	await _play_and_score(main, 2)
	assert_eq(main.save.write_count, 1, "Nouveau record : une écriture")
	main.game_over_screen.retry_requested.emit()
	await _play_and_score(main, 1)
	assert_eq(main.save.write_count, 1, "Score plus bas : aucune écriture")
	assert_eq(SaveManager.new(TEST_SAVE_PATH).load_best(), 2)
	main.queue_free()


func test_corrupted_save_does_not_prevent_launch() -> void:
	_write_raw("n'importe quoi")
	var main := create_main(true)
	assert_eq(main.state.current, S.MENU, "Le jeu démarre normalement")
	assert_eq(main.score.best, 0)
	main.queue_free()
