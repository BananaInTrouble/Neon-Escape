class_name ScoreManager
extends RefCounted
## Score de la partie en cours et meilleur score.

signal score_changed(score: int)

var score := 0
var best := 0
## Vrai entre reset() et commit() : aucun point ne peut être ajouté hors partie.
var _counting := false


func reset() -> void:
	score = 0
	_counting = true
	score_changed.emit(score)


func add_point() -> void:
	if not _counting:
		return
	score += 1
	score_changed.emit(score)


## Termine la partie : fige le score et met à jour le record.
## Retourne true si un nouveau record vient d'être établi.
func commit() -> bool:
	_counting = false
	if score > best:
		best = score
		return true
	return false
