#!/usr/bin/env bash
# Validation complète du projet : import, tests automatisés, lancement du jeu.
# Usage : GODOT=/chemin/vers/godot ./tools/check.sh
# (sur macOS : GODOT=/Applications/Godot.app/Contents/MacOS/Godot ./tools/check.sh)
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
LOG="$(mktemp)"
status=0

echo "== 1/3 Import du projet"
"$GODOT" --headless --import >"$LOG" 2>&1
if grep -E "SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

echo "== 2/3 Tests automatisés"
"$GODOT" --headless --script res://tests/run_tests.gd 2>&1 | tee "$LOG"
if [ "${PIPESTATUS[0]}" -ne 0 ] || grep -qE "SCRIPT ERROR|Parse Error" "$LOG"; then status=1; fi

echo "== 3/3 Lancement du jeu (300 frames, sans écran)"
"$GODOT" --headless --quit-after 300 >"$LOG" 2>&1
if grep -E "SCRIPT ERROR|Parse Error|ERROR:" "$LOG"; then status=1; fi

rm -f "$LOG"
if [ "$status" -eq 0 ]; then echo "== Tout est OK"; else echo "== Des erreurs ont été détectées"; fi
exit "$status"
