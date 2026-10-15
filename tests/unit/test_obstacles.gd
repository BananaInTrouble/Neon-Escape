extends TestCase

var spawner: ObstacleSpawner


func before_each() -> void:
	spawner = ObstacleSpawner.new()
	tree.root.add_child(spawner)
	spawner.setup(Vector2(720, 1280), 1000.0)
	spawner.rng.seed = 1234


func after_each() -> void:
	spawner.queue_free()


func _pattern(values: Array) -> Array[bool]:
	var p: Array[bool] = []
	p.assign(values)
	return p


func test_generated_patterns_are_always_passable() -> void:
	var rng := RandomNumberGenerator.new()
	var seen_double := false
	var seen_single := false
	for i in 5000:
		rng.seed = i
		var p := ObstacleSpawner.generate_pattern(rng, 0.5)
		assert_true(ObstacleSpawner.is_passable(p), "Graine %d : %s" % [i, p])
		var blocked := p.count(true)
		assert_true(blocked == 1 or blocked == 2, "1 ou 2 voies bloquées")
		seen_double = seen_double or blocked == 2
		seen_single = seen_single or blocked == 1
	assert_true(seen_double and seen_single, "Les deux types de rangées existent")


func test_full_wall_is_not_passable() -> void:
	assert_false(ObstacleSpawner.is_passable(_pattern([true, true, true])))
	assert_true(ObstacleSpawner.is_passable(_pattern([true, false, true])))


func test_spawn_row_creates_one_obstacle_per_blocked_lane() -> void:
	spawner.spawn_row(_pattern([true, false, true]), 0.0)
	assert_eq(spawner.active_count(), 2)
	var scorers := 0
	for child in spawner.get_children():
		if child is Obstacle and child.awards_point:
			scorers += 1
	assert_eq(scorers, 1, "Un seul point par rangée")


func test_rows_keep_exact_spacing() -> void:
	spawner.row_spacing = 500.0
	spawner.start()
	for i in 100:
		spawner.step(7.3)  # pas irrégulier volontairement
	var ys: Array[float] = []
	for child in spawner.get_children():
		if child is Obstacle and child.awards_point:
			ys.append(child.position.y)
	ys.sort()
	assert_true(ys.size() >= 2, "Plusieurs rangées créées")
	for i in range(1, ys.size()):
		assert_almost_eq(ys[i] - ys[i - 1], 500.0, 0.01, "Espacement constant")


func test_each_row_scores_exactly_once_and_is_freed() -> void:
	spawner.row_spacing = 1.0e9  # pas de création automatique pendant ce test
	var points := [0]
	spawner.row_passed.connect(func(): points[0] += 1)
	spawner.spawn_row(_pattern([true, true, false]), 0.0)
	spawner.spawn_row(_pattern([false, true, false]), -500.0)
	# Fait descendre tout le monde bien au-delà de l'écran, par petits pas.
	for i in 400:
		spawner.step(10.0)
	assert_eq(points[0], 2, "2 rangées -> 2 points")
	assert_eq(spawner.active_count(), 0, "Obstacles sortis de l'écran retirés")
	await wait_frames(1)
	assert_eq(spawner.get_child_count(), 0, "Et réellement libérés")


func test_obstacle_passed_signal_only_once() -> void:
	var o: Obstacle = ObstacleSpawner.OBSTACLE_SCENE.instantiate()
	o.awards_point = true
	var count := [0]
	o.passed.connect(func(): count[0] += 1)
	for i in 50:
		o.advance(50.0, 500.0, 5000.0)
	assert_eq(count[0], 1)
	o.free()


func test_score_manager() -> void:
	var s := ScoreManager.new()
	s.add_point()
	assert_eq(s.score, 0, "Aucun point hors partie")
	s.reset()
	s.add_point()
	s.add_point()
	assert_eq(s.score, 2)
	assert_true(s.commit(), "Premier score = record")
	s.add_point()
	assert_eq(s.score, 2, "Score figé après la fin")
	s.reset()
	s.add_point()
	assert_false(s.commit(), "1 < 2 : pas de record")
	assert_eq(s.best, 2)
