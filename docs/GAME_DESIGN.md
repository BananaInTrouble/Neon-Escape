# Game design — Neon Escape

## Boucle de jeu

Lancer → Play → jouer (sans tutoriel) → éviter les obstacles et marquer des points → collision → score et record → Retry en un appui.

## Règles (prototype actuel)

| Élément | Valeur actuelle | Où la modifier |
|---|---|---|
| Voies | 3, départ au centre | `scripts/gameplay/lanes.gd` |
| Contrôle | toucher moitié gauche/droite (sur appui, pas au relâchement) | `player_controller.gd` |
| Durée d'un changement de voie | 0,09 s | `player_controller.gd` → `move_duration` |
| Vitesse des obstacles | 560 → 1150 px/s | `difficulty_manager.gd` |
| Temps entre deux rangées | 0,95 s → 0,52 s | `difficulty_manager.gd` |
| Rangées à 2 voies bloquées | 30 % → 70 % | `difficulty_manager.gd` |
| Durée de la montée en difficulté | 75 s, puis plafond | `difficulty_manager.gd` → `ramp_duration` |
| Score | +1 par rangée franchie | `score_manager.gd` |
| Délai avant que Retry réponde | 0,4 s (évite un relancement accidentel) | `game_over.gd` |

## Difficulté

Réglages durcis après le premier essai sur iPhone (jugé trop facile).

Tous les réglages sont dans `scripts/gameplay/difficulty_manager.gd`, et modifiables sans code dans l'éditeur
(scène `scenes/game/game.tscn` → nœud **DifficultyManager** → Inspecteur).

- La difficulté dépend du **temps de survie** (pas du score) : elle progresse sans à-coups, même pour un joueur qui
  esquive bien ou mal. Le chronomètre s'arrête en pause et à la fin de partie, et repart de 0 à chaque partie.
- Elle monte de façon linéaire pendant 75 s, puis reste au maximum : pas de difficulté incontrôlable.

## Sauvegarde du record

- Seul le meilleur score est sauvegardé, dans `user://save.cfg` (dossier de données de l'application).
- Écriture uniquement en fin de partie, et seulement si un nouveau record vient d'être établi.
- Fichier absent, illisible ou valeur invalide : le jeu démarre normalement avec un record de 0.
- Version web : le record est conservé par le navigateur. Safari peut effacer les données d'un site non visité
  pendant 7 jours ; un jeu ajouté à l'écran d'accueil n'est en principe pas concerné.

## Règles de sécurité (garanties par le code et vérifiées par les tests)

- Une rangée bloque 1 ou 2 voies, **jamais 3**.
- Au moins **0,5 s** entre deux rangées, même si on règle des valeurs extrêmes : c'est assez pour traverser deux voies.
- Au moins **260 px** entre deux rangées (obstacle + orbe + marge).
- À vitesse maximale, un obstacle avance d'environ 19 px par image : impossible qu'il « traverse » l'orbe sans collision.

## Décisions prises sans précision du cahier des charges

- Un point par **rangée** (même si elle contient 2 blocs), compté quand le haut de la rangée dépasse le bas du joueur.
- Les déplacements se déclenchent à l'**appui** (plus réactif que le relâchement).
- Textes des boutons en anglais (Play, Retry…) comme dans le cahier des charges.
- Pas de bouton Settings pour l'instant : aucun réglage n'existe encore (le son arrivera à l'étape 8).
- Pause automatique quand l'application passe en arrière-plan, pour ne jamais perdre une partie à cause d'un appel.
- Le bouton Pause est semi-transparent pour ne pas cacher les obstacles qui apparaissent dans la voie de droite.

## Prochaines étapes

8. Direction artistique : particules, animations, sons.
9. Vérification complète et préparation des exports Android / iOS.
