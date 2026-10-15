extends SceneTree
## Captures d'écran automatiques des principaux écrans (outil de développement,
## nécessite un affichage, ex. xvfb-run sous Linux).
## Usage : godot --script res://tools/screenshot.gd -- <dossier_sortie>


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://"
	var main: GameManager = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await _wait(20)
	await _save(out_dir.path_join("1_menu.png"))
	main.start_game()
	await _wait(100)
	await _save(out_dir.path_join("2_gameplay.png"))
	main.pause_game()
	await _wait(10)
	await _save(out_dir.path_join("3_pause.png"))
	main.resume_game()
	var p: Array[bool] = [false, true, false]
	main.game.spawner.spawn_row(p, main.game.player.position.y)
	await _wait(40)
	await _save(out_dir.path_join("4_game_over.png"))
	quit()


func _wait(frames: int) -> void:
	for i in frames:
		await process_frame


func _save(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
	print("Capture : ", path)
