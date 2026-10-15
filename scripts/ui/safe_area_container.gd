class_name SafeAreaContainer
extends MarginContainer
## Conteneur plein écran qui garde son contenu hors de l'encoche et de la barre
## d'accueil des téléphones. Sur ordinateur, seule la marge de base s'applique.

@export var base_margin := 24


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(_update_margins)
	_update_margins()


func _update_margins() -> void:
	var insets: Array[float] = [0.0, 0.0, 0.0, 0.0]
	if OS.has_feature("mobile"):
		insets = insets_in_viewport(
			Rect2(DisplayServer.get_display_safe_area()),
			Vector2(DisplayServer.screen_get_size()),
			get_viewport().get_visible_rect().size
		)
	add_theme_constant_override("margin_left", base_margin + int(insets[0]))
	add_theme_constant_override("margin_top", base_margin + int(insets[1]))
	add_theme_constant_override("margin_right", base_margin + int(insets[2]))
	add_theme_constant_override("margin_bottom", base_margin + int(insets[3]))


## Convertit la zone sûre de l'écran (pixels physiques) en marges gauche, haut,
## droite, bas exprimées dans les unités de la zone de jeu.
static func insets_in_viewport(safe: Rect2, screen: Vector2, viewport_size: Vector2) -> Array[float]:
	var insets: Array[float] = [0.0, 0.0, 0.0, 0.0]
	if screen.x <= 0.0 or screen.y <= 0.0 or safe.size == Vector2.ZERO:
		return insets
	var sx := viewport_size.x / screen.x
	var sy := viewport_size.y / screen.y
	insets[0] = maxf(safe.position.x, 0.0) * sx
	insets[1] = maxf(safe.position.y, 0.0) * sy
	insets[2] = maxf(screen.x - safe.end.x, 0.0) * sx
	insets[3] = maxf(screen.y - safe.end.y, 0.0) * sy
	return insets
