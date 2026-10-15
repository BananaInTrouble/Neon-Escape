extends SceneTree
## Captures d'écran automatiques des principaux écrans (outil de développement,
## nécessite un affichage, ex. xvfb-run sous Linux).
## Usage : godot --script res://tools/screenshot.gd -- <dossier_sortie>


const SAVE_PATH := "user://screenshot_save.cfg"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://"
	var main: GameManager = load("res://scenes/main/main.tscn").instantiate()
	main.save_path = SAVE_PATH  # ne touche jamais au vrai record
	root.add_child(main)
	await _wait(20)
	await _save(out_dir.path_join("1_menu.png"))
	main.start_game()
	await _wait(90)
	main.game.player.move_by(-1)
	await _wait(4)
	await _save(out_dir.path_join("2_gameplay.png"))
	main.pause_game()
	await _wait(10)
	await _save(out_dir.path_join("3_pause.png"))
	main.resume_game()
	var p: Array[bool] = [false, false, false]
	p[main.game.player.lane] = true  # mur sur la voie actuelle de l'orbe
	main.game.spawner.spawn_row(p, main.game.player.position.y)
	await _wait(10)
	await _save(out_dir.path_join("4_crash.png"))
	await _wait(60)
	await _save(out_dir.path_join("5_game_over.png"))
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	quit()


func _wait(frames: int) -> void:
	for i in frames:
		await process_frame


func _save(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
	print("Capture : ", path)
