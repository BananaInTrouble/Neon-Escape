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
├── MainMenu (CanvasLayer)    titre, record, Play
├── HUD (CanvasLayer)         score courant, bouton Pause (dans un SafeAreaContainer)
├── PauseMenu (CanvasLayer)   Resume, Restart, Main Menu
└── GameOver (CanvasLayer)    résultat, Retry, Main Menu
```

Les modules communiquent par **signaux**, toujours vers le haut :

```
Obstacle.passed ──> ObstacleSpawner.row_passed ──> Game.row_passed ──> GameManager ──> ScoreManager ──> HUD
Player.hit ──> Game.crashed (une seule fois) ──> GameManager.end_game() ──> GameOverScreen
MainMenu.play_requested / PauseMenu.restart_requested / GameOverScreen.retry_requested ──> GameManager.start_game()
Hud.pause_requested ──> GameManager.pause_game()      PauseMenu.resume_requested ──> GameManager.resume_game()
PauseMenu.main_menu_requested / GameOverScreen.main_menu_requested ──> GameManager.go_to_menu()
```

Aucun nœud enfant ne connaît son parent. Seul le GameManager connaît tout le monde, ce qui évite les
dépendances circulaires et les chemins de nœuds fragiles.

## Modules

| Fichier | Rôle |
|---|---|
| `core/game_state.gd` | États `MENU`, `PLAYING`, `PAUSED`, `GAME_OVER` et table des transitions autorisées. Une transition refusée ne change rien : c'est la protection principale contre les doubles fins de partie. |
| `core/save_manager.gd` | Lit et écrit le record et le réglage du son dans `user://save.cfg` (ConfigFile) ; toutes les données sont réécrites ensemble pour ne jamais en perdre une. Valeurs absentes ou invalides → 0 ; écriture via un fichier temporaire puis renommage, pour qu'une coupure ne corrompe pas la sauvegarde. |
| `core/audio_manager.gd` | Joue les effets sonores avec 4 lecteurs réutilisés (pas de création de nœud à chaque son). Coupable via le réglage du son. |
| `core/music_player.gd` | Musique de fond : tirage du morceau, boucle, pause, fondus. Ignore les fichiers absents. |
| `core/music_tracks.gd` | Liste des 10 morceaux avec titre, auteur, licence, page : source unique pour le lecteur et les crédits. |
| `core/game_manager.gd` | Lance une partie (nouvelle instance de `game.tscn`), la met en pause, la termine, revient au menu. Affiche le bon écran. Relie les signaux. |
| `gameplay/lanes.gd` | Géométrie des 3 voies (partagée). |
| `gameplay/player_controller.gd` | Entrées tactiles et clavier, changement de voie animé, détection de collision. |
| `gameplay/obstacle_spawner.gd` | Génère les rangées (toujours franchissables), les fait descendre, libère celles qui sortent. |
| `gameplay/difficulty_manager.gd` | Calcule vitesse, écart des rangées et proportion de rangées doubles selon le temps de survie, avec limites de sécurité. `Game` applique ces valeurs au générateur à chaque image physique. |
| `gameplay/orb_visual.gd` | Dessin de l'orbe (halo pulsé), séparé de la logique du joueur pour pouvoir l'animer sans toucher à sa collision. |
| `gameplay/effects.gd` | Particules : traînée de l'orbe et explosion (autodétruite). Texture ronde partagée, créée une seule fois. |
| `gameplay/obstacle.gd` | Mouvement d'un bloc et signal de franchissement unique. |
| `gameplay/score_manager.gd` | Score courant et record ; refuse les points hors partie. |
| `gameplay/game.gd` | Assemble une partie ; garantit un seul signal `crashed`. |
| `ui/main_menu.gd`, `ui/hud.gd`, `ui/pause_menu.gd`, `ui/game_over.gd` | Affichage uniquement ; émettent des signaux. |
| `ui/credits_screen.gd` | Écran des crédits (obligatoire pour les morceaux CC-BY). |
| `ui/safe_area_container.gd` | Marges qui évitent l'encoche et la barre d'accueil des téléphones. |

## Décisions techniques

- **Rendu « Compatibility » (OpenGL)** : le plus compatible et le plus léger sur les téléphones modestes.
- **Résolution de référence 720×1280, étirement `canvas_items`, aspect `expand`** : aucune bande noire. Sur un écran
  plus allongé (téléphones récents), la largeur reste 720 px et la hauteur augmente ; sur un écran plus large (Safari
  avec sa barre d'outils, tablettes), la largeur augmente et les voies s'élargissent un peu. Tout le placement est
  calculé à partir de la taille réelle de la zone de jeu.
- **Export web « sans threads »** (`export_presets.cfg`, preset « Web ») : le plus compatible avec Safari sur iPhone et
  avec les hébergements simples (aucun en-tête serveur spécial requis).
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
- **Pause** : `get_tree().paused = true`. La partie (`Game`) est en mode `PAUSABLE` : obstacles, chronomètre de
  difficulté, animations et contrôles du joueur s'arrêtent. Le GameManager et les écrans héritent de son mode
  `ALWAYS` : les menus restent utilisables. Toute sortie de pause (reprise, redémarrage, menu) remet `paused` à faux.
- **Sauvegarde** : le GameManager charge le record au démarrage et ne l'écrit qu'en fin de partie, en cas de nouveau
  record. Le chemin du fichier est une propriété (`save_path`) : les tests utilisent `user://test_save.cfg` et ne
  touchent jamais au vrai record. Le fichier contient un numéro de version pour pouvoir faire évoluer le format.
- **Thème global** : `assets/theme/neon_theme.tres`, déclaré dans `project.godot` (`gui/theme/custom`). Variantes
  `SecondaryButton` (rose) et `RoundButton` (bouton Pause). Les scènes n'ont pas à répéter les styles.
- **Sons** : déclenchés par le GameManager à partir des signaux existants (changement de voie, score, fin de partie,
  boutons) ; le gameplay ne connaît pas l'audio.
- **Libération des obstacles** avec `queue_free()` quand ils sortent de l'écran. Au rythme actuel (≈1 rangée/s), un
  système de recyclage (pool) n'est pas nécessaire ; on pourra l'ajouter si le profilage mobile le justifie.

## Extensions futures (hors MVP)

Publicités, achats, classements, analytics : à brancher plus tard sur les signaux du GameManager (`state.changed`,
fin de partie), sans modifier le gameplay.
