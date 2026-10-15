# Game design — Neon Escape

## Boucle de jeu

Lancer → Play → jouer (sans tutoriel) → éviter les obstacles et marquer des points → collision → score et record → Retry en un appui.

## Règles (prototype actuel)

| Élément | Valeur actuelle | Où la modifier |
|---|---|---|
| Voies | 3, départ au centre | `scripts/gameplay/lanes.gd` |
| Contrôle | toucher moitié gauche/droite (sur appui, pas au relâchement) | `player_controller.gd` |
| Durée d'un changement de voie | 0,09 s | `player_controller.gd` → `move_duration` |
| Vitesse des obstacles | 420 px/s (fixe pour l'instant) | `obstacle_spawner.gd` → `speed` |
| Écart entre rangées | 520 px (≈1,2 s) | `obstacle_spawner.gd` → `row_spacing` |
| Rangée à 2 voies bloquées | 30 % | `obstacle_spawner.gd` → `double_chance` |
| Score | +1 par rangée franchie | `score_manager.gd` |
| Délai avant que Retry réponde | 0,4 s (évite un relancement accidentel) | `game_over.gd` |

Règle de sécurité : une rangée bloque 1 ou 2 voies, **jamais 3**.

## Décisions prises sans précision du cahier des charges

- Un point par **rangée** (même si elle contient 2 blocs), compté quand le haut de la rangée dépasse le bas du joueur.
- Les déplacements se déclenchent à l'**appui** (plus réactif que le relâchement).
- Textes des boutons en anglais (Play, Retry…) comme dans le cahier des charges.

## Prochaines étapes

5. DifficultyManager : vitesse et écart des rangées selon le temps de survie, avec bornes min/max et un temps de
   réaction minimal garanti.
6. Menu principal, bouton et menu Pause, écran Game Over complet (Main Menu), zones de sécurité (encoche).
7. Sauvegarde du record (`user://`), robustesse aux fichiers corrompus.
8. Direction artistique : particules, animations, sons.
9. Vérification complète et préparation des exports Android / iOS.
