extends TestCase
## Musique de fond, réglage MUSIC et écran Crédits.

const S := GameState.State
const FIXTURES: PackedStringArray = ["res://tests/fixtures/tone_a.ogg", "res://tests/fixtures/tone_b.ogg"]

var main: GameManager


func before_each() -> void:
	delete_test_save()
	main = load(MAIN_SCENE_PATH).instantiate()
	main.save_path = TEST_SAVE_PATH
	main.music.set_track_paths(FIXTURES)  # avant l'ajout : la musique du menu démarre dès le lancement
	main.music.fade_in = 0.05
	main.music.fade_out = 0.05
	tree.root.add_child(main)


func after_each() -> void:
	tree.paused = false
	main.queue_free()
	delete_test_save()


func _crash() -> void:
	var p: Array[bool] = [false, false, false]
	p[main.game.player.lane] = true
	main.game.spawner.spawn_row(p, main.game.player.position.y)
	await wait_physics_frames(5)


func test_track_list_is_valid() -> void:
	assert_eq(MusicTracks.TRACKS.size(), 10, "10 morceaux déclarés")
	var ids := {}
	for track in MusicTracks.TRACKS:
		for key in ["id", "title", "author", "license", "url"]:
			assert_true(track.has(key) and String(track[key]) != "", "%s : champ %s" % [track.get("id"), key])
		assert_true(track["license"] in ["CC0", "CC-BY 4.0"], "Licence autorisée : %s" % track["license"])
		assert_false(ids.has(track["id"]), "Identifiant unique : %s" % track["id"])
		ids[track["id"]] = true


func test_all_ten_tracks_are_in_the_game() -> void:
	assert_eq(MusicTracks.available_paths().size(), 10, "Les 10 fichiers de musique sont présents")
	for path in MusicTracks.available_paths():
		var stream: AudioStream = load(path)
		assert_true(stream != null and stream.get_length() > 60.0, "Morceau lisible et complet : %s" % path)
	assert_true("facebook.com/BogartVGM" in CreditsScreen.build_text(), "Lien demandé par Bogart VGM")


func test_no_music_files_is_silent_and_safe() -> void:
	main.music.set_track_paths(PackedStringArray())
	main.start_game()
	await wait_frames(2)
	assert_false(main.music.is_playing(), "Pas de musique, pas d'erreur")
	assert_eq(main.state.current, S.PLAYING)


func test_menu_music_at_launch() -> void:
	await wait_frames(2)
	assert_true(main.music.is_playing(), "Musique dès le menu principal")
	assert_true(main.music.in_menu)
	assert_true(main.music.current_path in FIXTURES)


func test_credits_do_not_restart_menu_music() -> void:
	var track := main.music.current_path
	main.main_menu.credits_button.pressed.emit()
	main.credits_screen.back_button.pressed.emit()
	assert_eq(main.music.current_path, track, "Même morceau après les crédits")
	assert_true(main.music.is_playing())


func test_game_track_differs_from_menu_track() -> void:
	for i in 10:
		var menu_track := main.music.current_path
		main.start_game()
		assert_true(main.music.current_path != menu_track, "Partie : un autre morceau que le menu")
		assert_false(main.music.in_menu)
		main.pause_game()
		main.go_to_menu()


func test_music_plays_during_game_and_pauses_with_it() -> void:
	main.start_game()
	await wait_frames(2)
	assert_true(main.music.is_playing(), "Musique pendant la partie")
	assert_true(main.music.current_path in FIXTURES)
	main.pause_game()
	assert_false(main.music.is_playing(), "Musique en pause avec le jeu")
	main.resume_game()
	assert_true(main.music.is_playing(), "La musique reprend")


func test_music_fades_out_on_game_over_and_stops_in_menu() -> void:
	main.start_game()
	await wait_frames(2)
	await _crash()
	await tree.create_timer(0.3).timeout
	assert_false(main.music.is_playing(), "Musique arrêtée après la collision")
	main.start_game()
	await wait_frames(2)
	main.pause_game()
	main.go_to_menu()
	await wait_frames(2)
	assert_true(main.music.is_playing(), "Musique du menu au retour au menu")
	assert_true(main.music.in_menu)


func test_next_game_changes_track() -> void:
	main.start_game()
	var first := main.music.current_path
	await _crash()
	main.start_game()
	assert_true(main.music.current_path != first, "Un autre morceau à la partie suivante")


func test_music_toggle_and_persistence() -> void:
	assert_eq(main.main_menu.music_button.text, "MUSIC : ON")
	main.main_menu.music_button.pressed.emit()
	assert_eq(main.main_menu.music_button.text, "MUSIC : OFF")
	assert_false(main.music.is_playing(), "Couper la musique l'arrête au menu")
	main.main_menu.music_button.pressed.emit()
	assert_true(main.music.is_playing(), "La rallumer relance la musique du menu")
	main.main_menu.music_button.pressed.emit()
	main.start_game()
	await wait_frames(2)
	assert_false(main.music.is_playing(), "Musique coupée")
	assert_true(main.audio.enabled, "Les effets sonores restent indépendants")
	main.queue_free()
	await wait_frames(2)
	main = create_main(true)
	assert_false(main.music.enabled, "Réglage relu après redémarrage")
	assert_eq(main.main_menu.music_button.text, "MUSIC : OFF")


func test_music_and_sound_settings_are_independent_in_save() -> void:
	var save := SaveManager.new(TEST_SAVE_PATH)
	save.save_music_enabled(false)
	save.save_best(7)
	var reread := SaveManager.new(TEST_SAVE_PATH)
	assert_false(reread.load_music_enabled())
	assert_true(reread.load_sound_enabled(), "Le son reste activé")
	assert_eq(reread.load_best(), 7)


func test_credits_screen_lists_every_track() -> void:
	main.main_menu.credits_button.pressed.emit()
	assert_true(main.credits_screen.visible, "Crédits affichés")
	var text := main.credits_screen.text_label.text
	for track in MusicTracks.TRACKS:
		assert_true(track["title"] in text and track["author"] in text, "Crédité : %s" % track["title"])
	assert_true("creativecommons.org/licenses/by/4.0" in text, "Lien vers la licence CC-BY")
	main.credits_screen.back_button.pressed.emit()
	assert_false(main.credits_screen.visible, "Retour au menu")
	assert_true(main.main_menu.visible)
