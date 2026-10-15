class_name Effects
extends RefCounted
## Effets visuels ponctuels (particules), créés à la demande et autodétruits.

const CYAN := Color(0.0, 0.898, 1.0)
const PINK := Color(1.0, 0.168, 0.839)

## Point lumineux rond et doux, partagé par toutes les particules (créé une seule fois).
static var _dot: GradientTexture2D


## Traînée continue derrière l'orbe : les particules filent vers le bas (vitesse).
static func create_trail() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = 28
	p.lifetime = 0.35
	p.local_coords = false
	p.direction = Vector2(0, 1)
	p.spread = 10.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 260.0
	p.initial_velocity_max = 380.0
	p.texture = soft_dot()
	p.scale_amount_min = 1.0
	p.scale_amount_max = 1.5
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 12.0
	p.color_ramp = _fade(CYAN, 0.8)
	p.scale_amount_curve = _shrink()
	return p


## Explosion unique (collision). Se libère toute seule à la fin.
static func spawn_burst(parent: Node, at: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = at
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 56
	p.lifetime = 0.8
	p.spread = 180.0
	p.gravity = Vector2(0, 300)
	p.initial_velocity_min = 220.0
	p.initial_velocity_max = 700.0
	p.damping_min = 120.0
	p.damping_max = 220.0
	p.texture = soft_dot()
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.6
	p.color_ramp = _burst_colors()
	p.scale_amount_curve = _shrink()
	p.finished.connect(p.queue_free)
	parent.add_child(p)
	p.emitting = true
	return p


static func soft_dot() -> GradientTexture2D:
	if _dot == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		_dot = GradientTexture2D.new()
		_dot.gradient = g
		_dot.fill = GradientTexture2D.FILL_RADIAL
		_dot.fill_from = Vector2(0.5, 0.5)
		_dot.fill_to = Vector2(1.0, 0.5)
		_dot.width = 32
		_dot.height = 32
	return _dot


static func _fade(color: Color, alpha: float) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(color, alpha))
	g.set_color(1, Color(color, 0.0))
	return g


static func _burst_colors() -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(PINK, 0.0))
	g.add_point(0.25, CYAN)
	return g


static func _shrink() -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0, 1))
	c.add_point(Vector2(1, 0))
	return c
