# Architecture

## Vue d'ensemble

```
Main (GameManager)            scenes/main/main.tscn — toujours actif, même en pause
├── Game (instanciée à chaque partie)   scenes/game/game.tscn — mis en pause avec l'arbre
│   ├── DifficultyManager     réglages de difficulté selon le temps de survie
│   ├── Background            décor des voies
│   ├── ObstacleSpawner       crée, déplace et libère les obstacles
│   │   └── Obstacle ×N       scenes/obstacles/obstacle.tscn
│   └── Player                scenes/player/player.tscn
├── HUD (CanvasLayer)         score courant
└── GameOver (CanvasLayer)    résultat + Retry
```

Les modules communiquent par **signaux**, toujours vers le haut :

```
Obstacle.passed ──> ObstacleSpawner.row_passed ──> Game.row_passed ──> GameManager ──> ScoreManager ──> HUD
Player.hit ──> Game.crashed (une seule fois) ──> GameManager.end_game() ──> GameOverScreen
GameOverScreen.retry_requested ──> GameManager.start_game()
```

Aucun nœud enfant ne connaît son parent. Seul le GameManager connaît tout le monde, ce qui évite les
dépendances circulaires et les chemins de nœuds fragiles.

## Modules

| Fichier | Rôle |
|---|---|
| `core/game_state.gd` | États `MENU`, `PLAYING`, `PAUSED`, `GAME_OVER` et table des transitions autorisées. Une transition refusée ne change rien : c'est la protection principale contre les doubles fins de partie. |
| `core/game_manager.gd` | Lance une partie (nouvelle instance de `game.tscn`) et la termine. Relie les signaux. |
| `gameplay/lanes.gd` | Géométrie des 3 voies (partagée). |
| `gameplay/player_controller.gd` | Entrées tactiles et clavier, changement de voie animé, détection de collision. |
| `gameplay/obstacle_spawner.gd` | Génère les rangées (toujours franchissables), les fait descendre, libère celles qui sortent. |
| `gameplay/difficulty_manager.gd` | Calcule vitesse, écart des rangées et proportion de rangées doubles selon le temps de survie, avec limites de sécurité. `Game` applique ces valeurs au générateur à chaque image physique. |
| `gameplay/obstacle.gd` | Mouvement d'un bloc et signal de franchissement unique. |
| `gameplay/score_manager.gd` | Score courant et record ; refuse les points hors partie. |
| `gameplay/game.gd` | Assemble une partie ; garantit un seul signal `crashed`. |
| `ui/hud.gd`, `ui/game_over.gd` | Affichage uniquement ; émettent des signaux. |

## Décisions techniques

- **Rendu « Compatibility » (OpenGL)** : le plus compatible et le plus léger sur les téléphones modestes.
- **Résolution de référence 720×1280, étirement `canvas_items`, aspect `keep_width`** : la largeur logique vaut toujours
  720 px (les 3 voies ont donc toujours la même taille), et la hauteur s'adapte aux écrans plus ou moins allongés.
- **Rangées créées selon la distance parcourue**, pas selon le temps : tous les obstacles descendent ensemble, donc
  l'écart entre deux rangées est exactement `row_spacing` pixels, même si la vitesse change. Le DifficultyManager
  calcule cet écart à partir d'un temps entre rangées, jamais inférieur au minimum de sécurité.
- **Une nouvelle instance de partie à chaque « Retry »** : impossible d'hériter d'obstacles ou d'états de la partie précédente.
- **Zones de collision plus petites que le dessin** (orbe : rayon 26 contre 34 affiché ; obstacle : 152×42 contre 168×56),
  pour que les frôlements ne soient pas punis.
- **Formes dessinées par code** (`_draw`) : aucune image externe, donc aucune question de licence.
- **Entrées** : `_unhandled_input` ne reçoit que les touchers non consommés par l'interface. Un bouton (Pause, Retry) ne
  peut donc pas déplacer le joueur. Les conteneurs d'interface plein écran sont en `mouse_filter = Ignore` pour ne pas
  bloquer les touchers de jeu.
- **Libération des obstacles** avec `queue_free()` quand ils sortent de l'écran. Au rythme actuel (≈1 rangée/s), un
  système de recyclage (pool) n'est pas nécessaire ; on pourra l'ajouter si le profilage mobile le justifie.

## Extensions futures (hors MVP)

Publicités, achats, classements, analytics : à brancher plus tard sur les signaux du GameManager (`state.changed`,
fin de partie), sans modifier le gameplay.
