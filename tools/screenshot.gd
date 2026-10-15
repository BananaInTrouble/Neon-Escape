extends SceneTree
## Capture d'écran automatique (outil de développement, nécessite un affichage).
## Usage : godot --script res://tools/screenshot.gd -- <dossier_sortie>

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out_dir: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	var main: GameManager = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	for i in 150:
		await process_frame
	await _save(out_dir.path_join("1_gameplay.png"))
	var p: Array[bool] = [false, true, false]
	main.game.spawner.spawn_row(p, main.game.player.position.y)
	for i in 40:
		await process_frame
	await _save(out_dir.path_join("2_game_over.png"))
	quit()


func _save(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
	print("Capture : ", path)
