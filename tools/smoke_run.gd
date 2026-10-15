extends SceneTree
## Lancement de contrôle : démarre le jeu sans écran pendant ~300 images, joue une
## partie, puis ferme proprement (comme une vraie fermeture) pour repérer les erreurs.
## Usage : godot --headless --script res://tools/smoke_run.gd

const SAVE_PATH := "user://smoke_save.cfg"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var main: GameManager = load("res://scenes/main/main.tscn").instantiate()
	main.save_path = SAVE_PATH  # ne touche jamais au vrai record
	root.add_child(main)
	await _wait(100)  # menu (avec musique)
	main.start_game()
	await _wait(200)  # partie
	main.queue_free()
	await _wait(30)  # laisse le moteur audio libérer les sons
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	print("Lancement de contrôle terminé.")
	quit()


func _wait(frames: int) -> void:
	for i in frames:
		await process_frame
