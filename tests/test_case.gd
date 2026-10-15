class_name TestCase
extends RefCounted
## Classe de base des tests automatisés (mini-framework sans dépendance).
##
## Chaque méthode commençant par `test_` est exécutée par tests/run_tests.gd.
## Les méthodes peuvent utiliser `await` (ex. attendre des frames).

var tree: SceneTree
var failures: PackedStringArray = []


## Appelée avant chaque test.
func before_each() -> void:
	pass


## Appelée après chaque test (libérer les nœuds créés ici).
func after_each() -> void:
	pass


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
