class_name MusicTracks
extends RefCounted
## Liste des musiques du jeu et leurs crédits (source unique : lecteur et écran Crédits).
##
## Chaque fichier est attendu dans res://assets/audio/music/<id>.ogg (voir
## tools/import_music.sh). Un morceau dont le fichier est absent est simplement ignoré.
## Licences vérifiées sur la page OpenGameArt de chaque morceau (octobre 2026).

const DIR := "res://assets/audio/music"

const TRACKS: Array[Dictionary] = [
	{"id": "electronic_outlaw", "title": "Electronic Outlaw", "author": "Zane Little Music",
		"license": "CC0", "url": "https://opengameart.org/content/electronic-outlaw"},
	{"id": "synesthesia", "title": "Synesthesia", "author": "Zane Little Music",
		"license": "CC0", "url": "https://opengameart.org/content/synesthesia"},
	{"id": "starlight_city", "title": "Starlight City", "author": "Zane Little Music",
		"license": "CC0", "url": "https://opengameart.org/content/starlight-city-loop-included"},
	{"id": "specular_city", "title": "Specular City", "author": "Vitalezzz",
		"license": "CC0", "url": "https://opengameart.org/content/specular-city"},
	{"id": "energetic_electro_tune", "title": "Energetic Electro Tune", "author": "TinyWorlds",
		"license": "CC0", "url": "https://opengameart.org/content/energetic-electro-tune"},
	{"id": "epic_space_shooter", "title": "8-bit Epic Space Shooter Music", "author": "HydroGene",
		"license": "CC0", "url": "https://opengameart.org/content/8-bit-epic-space-shooter-music"},
	{"id": "rush_point", "title": "8-bit Rush Point", "author": "HydroGene",
		"license": "CC0", "url": "https://opengameart.org/content/8-bit-rush-point"},
	{"id": "space_synth_wave", "title": "Space Synth Wave", "author": "Alex McCulloch (Pro Sensory)",
		"license": "CC0", "url": "https://opengameart.org/content/space-synth-wave"},
	{"id": "cyber_power", "title": "Cyber Power", "author": "Bogart VGM",
		"license": "CC-BY 4.0", "url": "https://opengameart.org/content/cyber-power"},
	{"id": "cybermatic_pulse", "title": "Cybermatic Pulse", "author": "Alexandr Zhelanov",
		"license": "CC-BY 4.0", "url": "https://opengameart.org/content/cybermatic-pulse"},
]


static func path_of(track: Dictionary) -> String:
	return DIR.path_join(String(track["id"]) + ".ogg")


## Chemins des morceaux réellement présents dans le jeu.
static func available_paths() -> PackedStringArray:
	var paths: PackedStringArray = []
	for track in TRACKS:
		var path := path_of(track)
		if ResourceLoader.exists(path):
			paths.append(path)
	return paths


## Texte des crédits musicaux (affiché dans le jeu et repris dans CREDITS.md).
static func credits_text() -> String:
	var lines: PackedStringArray = []
	for track in TRACKS:
		lines.append("« %s » — %s (%s)" % [track["title"], track["author"], track["license"]])
	return "\n".join(lines)
