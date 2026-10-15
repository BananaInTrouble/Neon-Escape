extends TestCase

const S := GameState.State


func test_starts_in_menu() -> void:
	assert_eq(GameState.new().current, S.MENU)


func test_valid_flow() -> void:
	var gs := GameState.new()
	assert_true(gs.transition_to(S.PLAYING))
	assert_true(gs.transition_to(S.PAUSED))
	assert_true(gs.transition_to(S.PLAYING))
	assert_true(gs.transition_to(S.GAME_OVER))
	assert_true(gs.transition_to(S.PLAYING), "Rejouer depuis Game Over")
	assert_true(gs.transition_to(S.GAME_OVER))
	assert_true(gs.transition_to(S.MENU))


func test_game_over_only_once() -> void:
	var gs := GameState.new()
	gs.transition_to(S.PLAYING)
	assert_true(gs.transition_to(S.GAME_OVER))
	assert_false(gs.transition_to(S.GAME_OVER), "Deuxième fin de partie refusée")


func test_invalid_transitions_are_refused() -> void:
	var gs := GameState.new()
	assert_false(gs.transition_to(S.PAUSED), "Pas de pause depuis le menu")
	assert_false(gs.transition_to(S.GAME_OVER), "Pas de défaite depuis le menu")
	assert_eq(gs.current, S.MENU)


func test_changed_signal_emitted_once_per_transition() -> void:
	var gs := GameState.new()
	var calls: Array = []
	gs.changed.connect(func(from, to): calls.append([from, to]))
	gs.transition_to(S.PLAYING)
	gs.transition_to(S.PLAYING)  # refusée
	assert_eq(calls.size(), 1)
	assert_eq(calls[0], [S.MENU, S.PLAYING])
