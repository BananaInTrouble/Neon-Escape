class_name TestCase
extends RefCounted
## Classe de base des tests automatisés (mini-framework sans dépendance).
##
## Chaque méthode commençant par `test_` est exécutée par tests/run_tests.gd.
## Les méthodes peuvent utiliser `await` (ex. attendre des frames).

## Sauvegarde dédiée aux tests : le vrai record du joueur n'est jamais touché.
const TEST_SAVE_PATH := "user://test_save.cfg"
const MAIN_SCENE_PATH := "res://scenes/main/main.tscn"

var tree: SceneTree
var failures: PackedStringArray = []


## Appelée avant chaque test.
func before_each() -> void:
	pass


## Appelée après chaque test (libérer les nœuds créés ici).
func after_each() -> void:
	pass


## Crée la scène principale avec la sauvegarde de test et l'ajoute à l'arbre.
func create_main(keep_save: bool = false) -> GameManager:
	if not keep_save:
		delete_test_save()
	var main: GameManager = load(MAIN_SCENE_PATH).instantiate()
	main.save_path = TEST_SAVE_PATH
	tree.root.add_child(main)
	return main


func delete_test_save() -> void:
	for p in [TEST_SAVE_PATH, TEST_SAVE_PATH + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		failures.append("attendu vrai. " + message)


func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		failures.append("attendu faux. " + message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("attendu <%s>, obtenu <%s>. %s" % [str(expected), str(actual), message])


func assert_almost_eq(actual: float, expected: float, tolerance: float, message: String = "") -> void:
	if absf(actual - expected) > tolerance:
		failures.append("attendu %f ± %f, obtenu %f. %s" % [expected, tolerance, actual, message])


func wait_frames(count: int) -> void:
	for i in count:
		await tree.process_frame


func wait_physics_frames(count: int) -> void:
	for i in count:
		await tree.physics_frame
