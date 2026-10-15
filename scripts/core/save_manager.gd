class_name SaveManager
extends RefCounted
## Sauvegarde locale du record (fichier ConfigFile dans user://).
##
## - Fichier absent, illisible ou valeur invalide : on repart de 0, sans erreur bloquante.
## - Écriture dans un fichier temporaire puis renommage : une coupure pendant
##   l'écriture ne peut pas abîmer la sauvegarde existante.
## - Appelé seulement en fin de partie, jamais à chaque image.

const DEFAULT_PATH := "user://save.cfg"
const SECTION := "scores"
const KEY_BEST := "best"
## Version du format, pour pouvoir le faire évoluer plus tard sans perdre de données.
const FORMAT_VERSION := 1
## Au-delà, la valeur est considérée comme corrompue.
const MAX_VALID_SCORE := 1_000_000_000

var path: String
## Nombre d'écritures réalisées (utile pour vérifier qu'on n'écrit pas trop souvent).
var write_count := 0


func _init(save_path: String = DEFAULT_PATH) -> void:
	path = save_path


## Lit le record. Retourne 0 si rien n'est sauvegardé ou si la donnée est invalide.
func load_best() -> int:
	if not FileAccess.file_exists(path):
		return 0
	var config := ConfigFile.new()
	if config.load(path) != OK:
		push_warning("Sauvegarde illisible (%s) : record remis à 0." % path)
		return 0
	return sanitize_score(config.get_value(SECTION, KEY_BEST, 0))


## Enregistre le record. Retourne true si l'écriture a réussi.
func save_best(best: int) -> bool:
	var config := ConfigFile.new()
	config.set_value("meta", "version", FORMAT_VERSION)
	config.set_value(SECTION, KEY_BEST, sanitize_score(best))
	var tmp_path := path + ".tmp"
	if config.save(tmp_path) != OK:
		push_warning("Impossible d'écrire la sauvegarde (%s)." % tmp_path)
		return false
	if DirAccess.rename_absolute(tmp_path, path) != OK:
		push_warning("Impossible de finaliser la sauvegarde (%s)." % path)
		DirAccess.remove_absolute(tmp_path)
		return false
	write_count += 1
	return true


## Accepte un entier (ou un nombre décimal entier) entre 0 et MAX_VALID_SCORE ; sinon 0.
static func sanitize_score(value: Variant) -> int:
	match typeof(value):
		TYPE_INT:
			return value if value >= 0 and value <= MAX_VALID_SCORE else 0
		TYPE_FLOAT:
			if is_finite(value) and value == floorf(value) and value >= 0.0 and value <= MAX_VALID_SCORE:
				return int(value)
	return 0
