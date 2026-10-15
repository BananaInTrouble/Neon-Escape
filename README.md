# Neon Escape

Jeu d'arcade 2D minimaliste en portrait : un noyau lumineux esquive des obstacles sur trois voies.
Moteur : **Godot 4** (projet créé et testé avec Godot **4.3-stable**, s'ouvre aussi dans les versions 4.x plus récentes).

## État actuel : prototype jouable (étapes 1 à 5)

- Trois voies, joueur au centre au départ.
- Toucher la moitié gauche ou droite de l'écran pour changer de voie (sur ordinateur : clic, flèches ← → ou A / D).
- Des rangées d'obstacles descendent ; chaque rangée laisse toujours au moins une voie libre.
- La vitesse et le rythme des obstacles augmentent progressivement pendant 90 s, puis plafonnent.
- +1 point par rangée franchie. Une collision termine la partie, et **RETRY** relance une partie propre.
- Pas encore : menu principal, pause, sauvegarde du record, sons (voir [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md)).

## Lancer le jeu sur Mac

1. Installer Godot 4 (gratuit) :
   - avec Homebrew : `brew install --cask godot`
   - ou en téléchargeant la version « Standard » sur https://godotengine.org/download/macos/ puis en glissant `Godot.app` dans Applications.
2. Récupérer le projet :
   ```bash
   git clone https://github.com/BananaInTrouble/neon-escape.git
   cd neon-escape
   ```
3. Jouer directement (sans ouvrir l'éditeur) :
   ```bash
   /Applications/Godot.app/Contents/MacOS/Godot --path .
   ```
4. Ou ouvrir l'éditeur, puis appuyer sur ▶ (ou `Cmd+B`) :
   ```bash
   /Applications/Godot.app/Contents/MacOS/Godot --path . --editor
   ```
   La première ouverture importe le projet (quelques secondes). Si une version plus récente de Godot propose de
   convertir ou mettre à jour le projet, accepte.

## Vérifier le projet (tests automatisés)

```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot ./tools/check.sh
```

Ce script importe le projet, exécute tous les tests automatisés, puis lance le jeu sans fenêtre pendant 300 images.
Il affiche `== Tout est OK` ou la liste des erreurs. Détails et vérifications manuelles : [tests/README.md](tests/README.md).

## Organisation

| Dossier | Contenu |
|---|---|
| `scenes/` | Scènes Godot (`.tscn`) : principale, partie, joueur, obstacle, interface |
| `scripts/core/` | Orchestration : états du jeu, GameManager |
| `scripts/gameplay/` | Joueur, obstacles, générateur, score, voies |
| `scripts/ui/` | Affichage (HUD, Game Over) : aucune règle de jeu |
| `tests/` | Tests automatisés (`tests/unit/test_*.gd`) et lanceur |
| `tools/` | `check.sh` (validation), `screenshot.gd` (captures d'écran automatiques) |
| `docs/` | Game design et architecture |

Explications techniques : [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
