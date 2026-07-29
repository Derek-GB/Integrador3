extends Node3D

@export var route: Node3D
@export var speed: float = 6.0
@export_range(0.0, 1.0) var curve_strength: float = 0.25

var _points: Array[Vector3] = []
var _current_segment := 0
var _t := 0.0


func _ready() -> void:
	if route == null:
		push_error("No se asignó una ruta al tornado.")
		return

	for child in route.get_children():
		if child is Marker3D:
			_points.append(child.global_position)

	if _points.size() < 2:
		push_error("La ruta necesita al menos 2 Marker3D.")
		return

	global_position = _points[0]


func _process(delta: float) -> void:
	if _points.size() < 2:
		return

	var start := _points[_current_segment]
	var end := _points[(_current_segment + 1) % _points.size()]

	var distance := start.distance_to(end)

	if distance <= 0.001:
		_next_segment()
		return

	_t += delta * speed / distance

	if _t >= 1.0:
		_t = 0.0
		_next_segment()

		start = _points[_current_segment]
		end = _points[(_current_segment + 1) % _points.size()]

	global_position = _get_arc_position(start, end, _t)

	# Hace que el tornado mire hacia donde se mueve
	var future := _get_arc_position(start, end, min(_t + 0.02, 1.0))
	# Evita error si origen y destino son virtualmente iguales
	if not global_position.is_equal_approx(future):
		look_at(future, Vector3.UP)


func _next_segment() -> void:
	_current_segment = (_current_segment + 1) % _points.size()


func _get_arc_position(start: Vector3, end: Vector3, t: float) -> Vector3:
	var midpoint := (start + end) * 0.5

	var direction := (end - start).normalized()

	# Perpendicular horizontal
	var perpendicular := Vector3(-direction.z, 0.0, direction.x)

	# Cambia el signo (+ o -) para invertir la dirección de la curva.
	var control := midpoint + perpendicular * start.distance_to(end) * curve_strength
	# Ejemplo para invertirla:
	# var control := midpoint - perpendicular * start.distance_to(end) * curve_strength

	return _quadratic_bezier(start, control, end, t)


func _quadratic_bezier(a: Vector3, c: Vector3, b: Vector3, t: float) -> Vector3:
	var u := 1.0 - t

	return (
		u * u * a +
		2.0 * u * t * c +
		t * t * b
	)
