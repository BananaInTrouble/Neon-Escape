# Tests

## Tests automatisés

Mini-framework sans dépendance : `tests/test_case.gd` (assertions) et `tests/run_tests.gd` (lanceur).
Chaque fichier `tests/unit/test_*.gd` contient des fonctions `test_...`.

```bash
# Depuis le dossier du projet (remplacer godot par le chemin de ton exécutable)
godot --headless --import                         # une fois, ou après ajout de scripts
godot --headless --script res://tests/run_tests.gd
# ou tout en une fois :
GODOT=godot ./tools/check.sh
```

| Fichier | Ce qui est vérifié |
|---|---|
| `test_game_state.gd` | Transitions autorisées et refusées ; une seule fin de partie |
| `test_player.gd` | Position des voies, impossible de sortir des 3 voies, toucher gauche/droite, clavier, contrôles désactivés |
| `test_obstacles.gd` | 5 000 rangées générées toutes franchissables ; un seul point par rangée ; espacement constant ; libération des obstacles ; score |
| `test_difficulty.gd` | Valeurs de départ et plafond, progression sans baisse ni saut brutal, limites de sécurité même avec des réglages extrêmes, pas d'obstacle « traversant » à vitesse max, simulation de 2 min de jeu |
| `test_menus.gd` | Démarrage sur le menu, Play, pause qui fige réellement obstacles et difficulté, demandes de pause invalides refusées, Restart et Main Menu depuis la pause et la fin de partie, toucher sur le bouton Pause sans déplacer le joueur, Échap, pause automatique en arrière-plan, calcul des zones de sécurité |
| `test_save.gd` | Fichier absent, sauvegarde/relecture, fichier corrompu, valeurs invalides (négatif, texte, énorme, décimal), record conservé après « redémarrage » de la scène principale, écriture seulement en cas de nouveau record, lancement normal malgré une sauvegarde corrompue |
| `test_game_flow.gd` | Sur la vraie scène : les obstacles apparaissent et descendent, une collision → une seule fin de partie, score affiché, Retry repart d'une partie propre (difficulté comprise), la difficulté pilote le générateur et s'arrête à la fin |

## Vérifications manuelles (impossibles à automatiser ici)

À faire dans l'éditeur (▶) et sur téléphone :

- [ ] Le jeu s'affiche en portrait ; le fond est bleu nuit, l'orbe cyan, les obstacles roses.
- [ ] Toucher à gauche / à droite déplace l'orbe d'une voie, sans délai perceptible.
- [ ] Deux touchers rapides depuis une voie du bord amènent bien à l'autre bord.
- [ ] Une collision visible arrête immédiatement le jeu ; aucune collision « invisible » (contact sans chevauchement visible).
- [ ] Frôler un obstacle sans le toucher visuellement ne fait pas perdre.
- [ ] RETRY relance une partie à 0, sans anciens obstacles, à la vitesse de départ.
- [ ] Le bouton Pause répond au doigt et ne déplace jamais l'orbe ; pendant la pause, rien ne bouge.
- [ ] Changer d'application (ou d'onglet) pendant une partie : au retour, le jeu est en pause.
- [ ] Sur iPhone avec encoche : le score et le bouton Pause ne sont pas cachés.
- [ ] Faire un record, fermer complètement le jeu (ou l'onglet), le rouvrir : le record s'affiche dans le menu.
- [ ] Après ~1 min 15, le jeu est nettement plus rapide mais toujours jouable ; il n'accélère plus ensuite.
- [ ] Sur un écran très allongé (iPhone récent) et sur une tablette : les voies restent centrées et tout est visible.
