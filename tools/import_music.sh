#!/usr/bin/env bash
# Convertit les musiques téléchargées en OGG Vorbis prêts pour le jeu.
#
# Usage : ./tools/import_music.sh <dossier_des_fichiers_téléchargés>
# Chaque fichier source doit être nommé d'après l'identifiant du morceau
# (voir scripts/core/music_tracks.gd), ex. cyber_power.mp3, synesthesia.wav.
#
# - Volume harmonisé (loudnorm) : tous les morceaux sonnent aussi fort.
# - Stéréo 44,1 kHz, qualité Vorbis 3 (~110 kbit/s) : bon compromis taille/qualité
#   pour un téléphone (environ 0,8 Mo par minute).
set -euo pipefail
SRC="${1:?Indique le dossier des fichiers téléchargés}"
DEST="$(cd "$(dirname "$0")/.." && pwd)/assets/audio/music"
mkdir -p "$DEST"
shopt -s nullglob
count=0
for f in "$SRC"/*.{mp3,wav,ogg,flac}; do
	id="$(basename "${f%.*}")"
	echo "→ $id"
	ffmpeg -hide_banner -loglevel error -y -i "$f" \
		-af "loudnorm=I=-16:TP=-1.5:LRA=11" -ac 2 -ar 44100 \
		-c:a libvorbis -q:a 3 "$DEST/$id.ogg"
	count=$((count + 1))
done
echo "$count morceau(x) converti(s) dans $DEST"
ls -la "$DEST"
