class_name SaveManager
extends RefCounted
## Sauvegarde locale (fichier ConfigFile dans user://) : record et réglages.
##
## - Fichier absent, illisible ou valeur invalide : valeurs par défaut, sans erreur bloquante.
## - Toutes les données sont gardées en mémoire et réécrites ensemble : enregistrer
##   le record ne fait jamais perdre un réglage (et inversement).
## - Écriture dans un fichier temporaire puis renommage : une coupure pendant
##   l'écriture ne peut pas abîmer la sauvegarde existante.
## - Écrit seulement sur demande (fin de partie, changement de réglage), jamais à chaque image.

const DEFAULT_PATH := "user://save.cfg"
const SECTION_SCORES := "scores"
const KEY_BEST := "best"
const SECTION_SETTINGS := "settings"
const KEY_SOUND := "sound_enabled"
## Version du format, pour pouvoir le faire évoluer plus tard sans perdre de données.
const FORMAT_VERSION := 1
## Au-delà, la valeur est considérée comme corrompue.
const MAX_VALID_SCORE := 1_000_000_000

var path: String
## Nombre d'écritures réalisées (utile pour vérifier qu'on n'écrit pas trop souvent).
var write_count := 0
var _config := ConfigFile.new()
var _loaded := false


func _init(save_path: String = DEFAULT_PATH) -> void:
	path = save_path


## Lit le record sur le disque. Retourne 0 si rien n'est sauvegardé ou si la donnée est invalide.
func load_best() -> int:
	_read_file()
	return sanitize_score(_config.get_value(SECTION_SCORES, KEY_BEST, 0))


## Enregistre le record. Retourne true si l'écriture a réussi.
func save_best(best: int) -> bool:
	_ensure_loaded()
	_config.set_value(SECTION_SCORES, KEY_BEST, sanitize_score(best))
	return _write()


## Lit sur le disque si le son est activé (oui par défaut, et si la valeur est invalide).
func load_sound_enabled() -> bool:
	_read_file()
	var value: Variant = _config.get_value(SECTION_SETTINGS, KEY_SOUND, true)
	return value if typeof(value) == TYPE_BOOL else true


func save_sound_enabled(enabled: bool) -> bool:
	_ensure_loaded()
	_config.set_value(SECTION_SETTINGS, KEY_SOUND, enabled)
	return _write()


## Avant une écriture : charge le fichier une fois pour ne rien écraser d'autre.
func _ensure_loaded() -> void:
	if not _loaded:
		_read_file()


func _read_file() -> void:
	_loaded = true
	_config = ConfigFile.new()
	if not FileAccess.file_exists(path):
		return
	if _config.load(path) != OK:
		push_warning("Sauvegarde illisible (%s) : valeurs par défaut." % path)
		_config = ConfigFile.new()  # on repart d'un contenu propre, réécrit à la prochaine sauvegarde


func _write() -> bool:
	_config.set_value("meta", "version", FORMAT_VERSION)
	var tmp_path := path + ".tmp"
	if _config.save(tmp_path) != OK:
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
