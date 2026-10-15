extends SceneTree
## Lanceur de tests en ligne de commande.
##
## Usage (depuis le dossier NeonEscape) :
##   godot --headless --script res://tests/run_tests.gd
## Code de sortie 0 si tout passe, 1 sinon.

const TEST_DIR := "res://tests/unit"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var passed := 0
	var failed := 0
	for file in _test_files():
		var script: GDScript = load(TEST_DIR.path_join(file))
		for method in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			var test: TestCase = script.new()
			test.tree = self
			test.before_each()
			await test.call(name)
			test.after_each()
			# Laisse Godot libérer les nœuds en attente (queue_free).
			await process_frame
			if test.failures.is_empty():
				passed += 1
				print("  OK    %s::%s" % [file, name])
			else:
				failed += 1
				print("  ÉCHEC %s::%s" % [file, name])
				for f in test.failures:
					print("        - " + f)
	print("\n%d test(s) réussi(s), %d échec(s)." % [passed, failed])
	quit(1 if failed > 0 else 0)


func _test_files() -> PackedStringArray:
	var files: PackedStringArray = []
	for file in DirAccess.get_files_at(TEST_DIR):
		if file.begins_with("test_") and file.ends_with(".gd"):
			files.append(file)
	files.sort()
	return files
