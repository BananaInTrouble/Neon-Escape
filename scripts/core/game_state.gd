class_name GameState
extends RefCounted
## États autorisés du jeu et règles de transition.
##
## Une seule source de vérité : toute demande de changement d'état passe par
## [method transition_to], qui refuse les transitions incohérentes
## (ex. deux fins de partie de suite, pause depuis le menu).

signal changed(from: State, to: State)

enum State { MENU, PLAYING, PAUSED, GAME_OVER }

## Pour chaque état, la liste des états atteignables.
## PLAYING -> PLAYING n'existe pas : un redémarrage passe par PAUSED ou GAME_OVER.
const TRANSITIONS: Dictionary = {
	State.MENU: [State.PLAYING],
	State.PLAYING: [State.PAUSED, State.GAME_OVER],
	State.PAUSED: [State.PLAYING, State.MENU],
	State.GAME_OVER: [State.PLAYING, State.MENU],
}

var current: State = State.MENU


static func can_transition(from: State, to: State) -> bool:
	return to in TRANSITIONS.get(from, [])


## Change d'état si la transition est autorisée. Retourne false sinon,
## sans rien modifier : l'appelant peut ignorer une demande répétée.
func transition_to(to: State) -> bool:
	if not can_transition(current, to):
		return false
	var from := current
	current = to
	changed.emit(from, to)
	return true


func is_playing() -> bool:
	return current == State.PLAYING


static func name_of(state: State) -> String:
	return State.keys()[state]
