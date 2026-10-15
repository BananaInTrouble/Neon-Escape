class_name Lanes
extends RefCounted
## Géométrie des voies, partagée par le joueur, les obstacles et le décor.

const COUNT := 3
const LEFT := 0
const CENTER := 1
const RIGHT := 2


## Abscisse du centre de la voie [param lane] pour une zone de jeu de largeur [param width].
static func x_for(lane: int, width: float) -> float:
	return width * (float(lane) + 0.5) / COUNT


static func width_of(total_width: float) -> float:
	return total_width / COUNT


static func clamp_lane(lane: int) -> int:
	return clampi(lane, 0, COUNT - 1)
