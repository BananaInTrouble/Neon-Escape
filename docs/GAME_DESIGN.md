# Game design — Neon Escape

## Boucle de jeu

Lancer → Play → jouer (sans tutoriel) → éviter les obstacles et marquer des points → collision → score et record → Retry en un appui.

## Règles (prototype actuel)

| Élément | Valeur actuelle | Où la modifier |
|---|---|---|
| Voies | 3, départ au centre | `scripts/gameplay/lanes.gd` |
| Contrôle | toucher moitié gauche/droite (sur appui, pas au relâchement) | `player_controller.gd` |
| Durée d'un changement de voie | 0,09 s | `player_controller.gd` → `move_duration` |
| Vitesse des obstacles | 420 → 900 px/s | `difficulty_manager.gd` |
| Temps entre deux rangées | 1,25 s → 0,62 s | `difficulty_manager.gd` |
| Rangées à 2 voies bloquées | 15 % → 55 % | `difficulty_manager.gd` |
| Durée de la montée en difficulté | 90 s, puis plafond | `difficulty_manager.gd` → `ramp_duration` |
| Score | +1 par rangée franchie | `score_manager.gd` |
| Délai avant que Retry réponde | 0,4 s (évite un relancement accidentel) | `game_over.gd` |

## Difficulté

Tous les réglages sont dans `scripts/gameplay/difficulty_manager.gd`, et modifiables sans code dans l'éditeur
(scène `scenes/game/game.tscn` → nœud **DifficultyManager** → Inspecteur).

- La difficulté dépend du **temps de survie** (pas du score) : elle progresse sans à-coups, même pour un joueur qui
  esquive bien ou mal. Le chronomètre s'arrête en pause et à la fin de partie, et repart de 0 à chaque partie.
- Elle monte de façon linéaire pendant 90 s, puis reste au maximum : pas de difficulté incontrôlable.

## Règles de sécurité (garanties par le code et vérifiées par les tests)

- Une rangée bloque 1 ou 2 voies, **jamais 3**.
- Au moins **0,5 s** entre deux rangées, même si on règle des valeurs extrêmes : c'est assez pour traverser deux voies.
- Au moins **260 px** entre deux rangées (obstacle + orbe + marge).
- À vitesse maximale, un obstacle avance de 15 px par image : impossible qu'il « traverse » l'orbe sans collision.

## Décisions prises sans précision du cahier des charges

- Un point par **rangée** (même si elle contient 2 blocs), compté quand le haut de la rangée dépasse le bas du joueur.
- Les déplacements se déclenchent à l'**appui** (plus réactif que le relâchement).
- Textes des boutons en anglais (Play, Retry…) comme dans le cahier des charges.

## Prochaines étapes

6. Menu principal, bouton et menu Pause, écran Game Over complet (Main Menu), zones de sécurité (encoche).
7. Sauvegarde du record (`user://`), robustesse aux fichiers corrompus.
8. Direction artistique : particules, animations, sons.
9. Vérification complète et préparation des exports Android / iOS.
