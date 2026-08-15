extends Node2D
class_name WaterLeakStaticLayer

# =========================================================
# CAPA ESTÁTICA DEL MINIJUEGO DE FUGAS DE AGUA
# =========================================================
# Este archivo dibuja solo lo que NO cambia constantemente:
# fondo, pared y tuberías.
# Se redibuja una vez en _ready() y cuando cambia el tamaño de ventana.

const PIPE_ROUTES: Array = [
	[
		Vector2(0.05, 0.16), Vector2(0.34, 0.16), Vector2(0.34, 0.31),
		Vector2(0.68, 0.31), Vector2(0.68, 0.16), Vector2(0.94, 0.16)
	],
	[
		Vector2(0.05, 0.43), Vector2(0.27, 0.43), Vector2(0.27, 0.56),
		Vector2(0.52, 0.56), Vector2(0.52, 0.42), Vector2(0.77, 0.42),
		Vector2(0.77, 0.56), Vector2(0.94, 0.56)
	],
	[
		Vector2(0.05, 0.76), Vector2(0.37, 0.76), Vector2(0.37, 0.88),
		Vector2(0.71, 0.88), Vector2(0.71, 0.72), Vector2(0.94, 0.72)
	],
	[
		Vector2(0.12, 0.16), Vector2(0.12, 0.76)
	],
	[
		Vector2(0.61, 0.31), Vector2(0.61, 0.72)
	]
]


func _ready() -> void:
	queue_redraw()


func force_static_redraw() -> void:
	queue_redraw()


func _draw() -> void:
	_draw_background()
	_draw_board_surface()
	_draw_pipe_network()


func _draw_background() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var viewport_rect: Rect2 = Rect2(Vector2.ZERO, viewport_size)
	var visual_scale: float = _get_visual_scale()

	_draw_vertical_gradient(
		viewport_rect,
		Color8(20, 132, 142),
		Color8(6, 67, 84),
		24
	)

	# Círculos decorativos estáticos. No usan animación para evitar gasto constante de CPU.
	for index: int in range(12):
		var progress: float = float(index) / 11.0
		var circle_position: Vector2 = Vector2(
			progress * viewport_size.x,
			48.0 * visual_scale + sin(float(index) * 0.9) * 10.0 * visual_scale
		)
		draw_circle(
			circle_position,
			34.0 * visual_scale,
			Color(0.24, 0.78, 0.79, 0.075)
		)


func _draw_board_surface() -> void:
	var board_rect: Rect2 = _get_board_rect()
	var visual_scale: float = _get_visual_scale()

	_draw_rounded_rect(
		Rect2(board_rect.position + Vector2(12.0, 14.0) * visual_scale, board_rect.size),
		30.0 * visual_scale,
		Color(0.01, 0.08, 0.10, 0.55)
	)

	_draw_rounded_rect(
		board_rect,
		31.0 * visual_scale,
		Color8(135, 69, 31)
	)

	_draw_rounded_rect(
		board_rect.grow(-7.0 * visual_scale),
		26.0 * visual_scale,
		Color8(224, 149, 76)
	)

	var inner_rect: Rect2 = board_rect.grow(-15.0 * visual_scale)
	_draw_wall_gradient(inner_rect)
	# La textura de ladrillos quedó desactivada porque era de lo más pesado.
	# _draw_wall_texture(inner_rect)


func _draw_wall_gradient(rect: Rect2) -> void:
	var visual_scale: float = _get_visual_scale()
	var steps: int = 22
	var strip_height: float = rect.size.y / float(steps)

	for index: int in range(steps):
		var progress: float = float(index) / float(steps - 1)
		var color: Color = Color8(255, 226, 181).lerp(
			Color8(231, 190, 141),
			progress
		)
		var strip_rect: Rect2 = Rect2(
			Vector2(rect.position.x, rect.position.y + strip_height * float(index)),
			Vector2(rect.size.x, strip_height + 1.0)
		)
		draw_rect(strip_rect, color, true)

	var border_points: PackedVector2Array = _rounded_rect_points(
		rect,
		20.0 * visual_scale,
		8
	)
	var closed_points: PackedVector2Array = _close_polyline(border_points)
	draw_polyline(closed_points, Color8(194, 126, 62), 4.0 * visual_scale, true)


func _draw_pipe_network() -> void:
	var visual_scale: float = _get_visual_scale()
	var pipe_width: float = 30.0 * visual_scale

	for route_index: int in range(PIPE_ROUTES.size()):
		var route: Array = PIPE_ROUTES[route_index]
		var points: PackedVector2Array = PackedVector2Array()

		for normalized_point: Vector2 in route:
			points.append(_normalized_to_board(normalized_point))

		var shadow_points: PackedVector2Array = _offset_points(
			points,
			Vector2(7.0, 9.0) * visual_scale
		)
		var lower_shade_points: PackedVector2Array = _offset_points(
			points,
			Vector2(0.0, 4.5) * visual_scale
		)
		var upper_highlight_points: PackedVector2Array = _offset_points(
			points,
			Vector2(0.0, -5.0) * visual_scale
		)

		draw_polyline(shadow_points, Color(0.12, 0.08, 0.05, 0.38), pipe_width + 17.0 * visual_scale, true)
		draw_polyline(points, Color8(45, 53, 57), pipe_width + 14.0 * visual_scale, true)
		draw_polyline(points, Color8(107, 133, 142), pipe_width + 7.0 * visual_scale, true)
		draw_polyline(lower_shade_points, Color8(80, 108, 119), pipe_width * 0.72, true)
		draw_polyline(points, Color8(169, 196, 202), pipe_width * 0.78, true)
		draw_polyline(upper_highlight_points, Color8(230, 243, 243), pipe_width * 0.24, true)

		for segment_index: int in range(points.size() - 1):
			_draw_pipe_segment_details(
				points[segment_index],
				points[segment_index + 1],
				pipe_width,
				segment_index
			)

		for point: Vector2 in points:
			_draw_pipe_joint(point, pipe_width)


func _draw_pipe_segment_details(
	start: Vector2,
	end: Vector2,
	pipe_width: float,
	segment_index: int
) -> void:
	var visual_scale: float = _get_visual_scale()
	var direction: Vector2 = (end - start).normalized()
	var perpendicular: Vector2 = Vector2(-direction.y, direction.x)
	var segment_length: float = start.distance_to(end)

	if segment_length < 80.0 * visual_scale:
		return

	var collar_count: int = 1 if segment_length < 220.0 * visual_scale else 2
	for collar_index: int in range(collar_count):
		var t: float = float(collar_index + 1) / float(collar_count + 1)
		var center: Vector2 = start.lerp(end, t)
		var half_length: float = pipe_width * 0.70
		var outer_a: Vector2 = center - perpendicular * half_length
		var outer_b: Vector2 = center + perpendicular * half_length
		draw_line(outer_a, outer_b, Color8(53, 61, 63), 8.0 * visual_scale, true)
		draw_line(outer_a, outer_b, Color8(190, 207, 209), 4.0 * visual_scale, true)
		draw_line(
			outer_a + direction * 3.0 * visual_scale,
			outer_b + direction * 3.0 * visual_scale,
			Color8(98, 119, 125),
			2.0 * visual_scale,
			true
		)

	# Menos óxido que la versión original para bajar el costo del dibujo.
	var rust_seed: float = float(segment_index * 7 + 3)
	var rust_center: Vector2 = start.lerp(end, 0.45 + fmod(rust_seed * 0.173, 0.20))
	rust_center += perpendicular * sin(rust_seed) * pipe_width * 0.18
	draw_circle(rust_center, 3.5 * visual_scale, Color(0.53, 0.24, 0.08, 0.55))


func _draw_pipe_joint(position: Vector2, pipe_width: float) -> void:
	var visual_scale: float = _get_visual_scale()
	var outer_radius: float = pipe_width * 0.72

	draw_circle(
		position + Vector2(5.0, 6.0) * visual_scale,
		outer_radius,
		Color(0.10, 0.07, 0.05, 0.38)
	)
	draw_circle(position, outer_radius, Color8(46, 56, 60))
	draw_circle(position, outer_radius * 0.83, Color8(109, 135, 143))
	draw_circle(position, outer_radius * 0.63, Color8(177, 199, 204))
	draw_circle(
		position - Vector2(4.0, 5.0) * visual_scale,
		outer_radius * 0.24,
		Color8(235, 246, 246)
	)

	# Solo 2 tornillos en vez de 4 para reducir dibujo.
	for index: int in range(2):
		var angle: float = float(index) * PI + PI * 0.25
		var bolt_position: Vector2 = position + Vector2.RIGHT.rotated(angle) * outer_radius * 0.62
		draw_circle(bolt_position, 3.0 * visual_scale, Color8(45, 55, 59))
		draw_circle(
			bolt_position - Vector2(0.8, 0.8) * visual_scale,
			1.2 * visual_scale,
			Color8(204, 222, 224)
		)


func _get_board_rect() -> Rect2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var visual_scale: float = _get_visual_scale()
	var margin: float = 28.0 * visual_scale
	var top_margin: float = 30.0 * visual_scale
	var right_panel_width: float = 294.0 * visual_scale

	return Rect2(
		Vector2(margin, top_margin),
		Vector2(
			viewport_size.x - right_panel_width - margin * 2.0,
			viewport_size.y - top_margin - margin
		)
	)


func _normalized_to_board(normalized_position: Vector2) -> Vector2:
	var board_rect: Rect2 = _get_board_rect()
	return board_rect.position + Vector2(
		normalized_position.x * board_rect.size.x,
		normalized_position.y * board_rect.size.y
	)


func _get_visual_scale() -> float:
	var viewport_size: Vector2 = get_viewport_rect().size
	return clampf(
		minf(viewport_size.x / 1536.0, viewport_size.y / 1024.0),
		0.65,
		1.30
	)


func _draw_vertical_gradient(
	rect: Rect2,
	top_color: Color,
	bottom_color: Color,
	steps: int
) -> void:
	if steps <= 0 or rect.size.y <= 0.0:
		return

	var strip_height: float = rect.size.y / float(steps)
	for index: int in range(steps):
		var progress: float = float(index) / float(maxi(steps - 1, 1))
		var strip_color: Color = top_color.lerp(bottom_color, progress)
		draw_rect(
			Rect2(
				Vector2(rect.position.x, rect.position.y + strip_height * float(index)),
				Vector2(rect.size.x, strip_height + 1.0)
			),
			strip_color,
			true
		)


func _draw_rounded_rect(rect: Rect2, radius: float, color: Color) -> void:
	var points: PackedVector2Array = _rounded_rect_points(rect, radius, 9)
	if points.size() >= 3:
		draw_colored_polygon(points, color)


func _rounded_rect_points(
	rect: Rect2,
	radius: float,
	segments_per_corner: int
) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var safe_radius: float = minf(
		radius,
		minf(rect.size.x, rect.size.y) * 0.5
	)
	var corner_centers: Array[Vector2] = [
		rect.position + Vector2(safe_radius, safe_radius),
		Vector2(rect.end.x - safe_radius, rect.position.y + safe_radius),
		rect.end - Vector2(safe_radius, safe_radius),
		Vector2(rect.position.x + safe_radius, rect.end.y - safe_radius)
	]
	var start_angles: Array[float] = [PI, -PI * 0.5, 0.0, PI * 0.5]

	for corner_index: int in range(4):
		for segment_index: int in range(segments_per_corner + 1):
			var progress: float = float(segment_index) / float(segments_per_corner)
			var angle: float = start_angles[corner_index] + progress * PI * 0.5
			points.append(
				corner_centers[corner_index]
				+ Vector2(cos(angle), sin(angle)) * safe_radius
			)

	return points


func _close_polyline(points: PackedVector2Array) -> PackedVector2Array:
	var closed_points: PackedVector2Array = PackedVector2Array(points)
	if points.size() > 0:
		closed_points.append(points[0])
	return closed_points


func _offset_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var result: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in points:
		result.append(point + offset)
	return result
