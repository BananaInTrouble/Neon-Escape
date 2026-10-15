extends TestCase

var d: DifficultyManager


func before_each() -> void:
	d = DifficultyManager.new()


func after_each() -> void:
	d.free()


func test_starts_at_start_values() -> void:
	assert_eq(d.speed(0.0), d.start_speed)
	assert_eq(d.row_interval(0.0), d.start_row_interval)
	assert_eq(d.double_chance(0.0), d.start_double_chance)


func test_reaches_and_never_exceeds_maximum() -> void:
	for t in [d.ramp_duration, d.ramp_duration * 2.0, 100000.0]:
		assert_eq(d.speed(t), d.max_speed, "Vitesse plafonnée à t=%s" % t)
		assert_eq(d.row_interval(t), d.min_row_interval, "Intervalle plancher à t=%s" % t)
		assert_eq(d.double_chance(t), d.max_double_chance)


func test_progression_is_monotonic_and_smooth() -> void:
	var prev_speed := d.speed(0.0)
	var prev_interval := d.row_interval(0.0)
	var prev_chance := d.double_chance(0.0)
	var t := 0.0
	while t < d.ramp_duration + 10.0:
		t += 0.5
		var s := d.speed(t)
		assert_true(s >= prev_speed, "La vitesse ne baisse jamais (t=%s)" % t)
		assert_true(s - prev_speed < 5.0, "Pas de saut brutal de vitesse (t=%s)" % t)
		assert_true(d.row_interval(t) <= prev_interval, "Les rangées ne ralentissent pas")
		assert_true(d.double_chance(t) >= prev_chance)
		prev_speed = s
		prev_interval = d.row_interval(t)
		prev_chance = d.double_chance(t)


func test_safety_limits_hold_even_with_extreme_settings() -> void:
	d.max_speed = 5000.0
	d.min_row_interval = 0.05
	d.max_double_chance = 3.0
	for t in [0.0, 30.0, 90.0, 1000.0]:
		var interval := d.row_spacing(t) / d.speed(t)
		assert_true(interval >= d.safety_min_row_interval - 0.0001, "Temps de réaction garanti (t=%s)" % t)
		assert_true(d.row_spacing(t) >= d.safety_min_row_spacing)
		assert_true(d.double_chance(t) <= 1.0)


func test_zero_ramp_duration_does_not_crash() -> void:
	d.ramp_duration = 0.0
	assert_eq(d.speed(0.0), d.max_speed)


func test_obstacles_cannot_tunnel_through_player_at_max_speed() -> void:
	# Distance parcourue en une image physique, comparée à l'épaisseur cumulée
	# des zones de collision (obstacle 42 px + orbe 2 × 26 px).
	var per_frame := d.speed(100000.0) / Engine.physics_ticks_per_second
	assert_true(per_frame < (42.0 + 52.0) * 0.5, "%s px par image" % per_frame)


func test_two_minutes_of_play_stay_fair() -> void:
	# Simulation déterministe : le générateur piloté par la difficulté pendant 120 s.
	var spawner := ObstacleSpawner.new()
	tree.root.add_child(spawner)
	spawner.setup(Vector2(720, 1280), 1000.0)
	spawner.rng.seed = 42
	var spawn_times: Array[float] = []
	var spawn_count := [0]
	spawner.child_entered_tree.connect(func(n):
		if n is Obstacle and n.awards_point:
			spawn_count[0] += 1)
	d.start()
	d.apply_to(spawner)
	spawner.start()
	var dt := 1.0 / 60.0
	var last: int = spawn_count[0]
	for frame in 120 * 60:
		d.elapsed += dt
		d.apply_to(spawner)
		spawner.step(spawner.speed * dt)
		if spawn_count[0] != last:
			last = spawn_count[0]
			spawn_times.append(d.elapsed)
	for i in range(1, spawn_times.size()):
		var gap := spawn_times[i] - spawn_times[i - 1]
		assert_true(gap >= d.safety_min_row_interval - dt, "Rangées trop proches : %.3f s" % gap)
	var first_gap := spawn_times[1] - spawn_times[0]
	var last_gap := spawn_times[-1] - spawn_times[-2]
	assert_true(last_gap < first_gap, "Le rythme accélère (%.2f s -> %.2f s)" % [first_gap, last_gap])
	assert_true(spawner.active_count() < 15, "Les obstacles sortis sont libérés")
	spawner.queue_free()
