extends Node3D

@export var tornado_node: Node3D
@export var orbit_speed: float = -360 # grados por segundo

# Guardamos nodo + su offset propio (relativo al centro) + su altura original
var orbit_data: Array = []

func _ready() -> void:
	orbit_data.clear()
	var sum_x: float = 0.0
	var sum_z: float = 0.0
	var count: int = 0
	var raw_children: Array[Node3D] = []

	for child in get_children():
		if child is Node3D and child.name.contains("_"):
			raw_children.append(child)
			var pos_x: float = child.global_position.x if child.is_inside_tree() else child.position.x
			var pos_z: float = child.global_position.z if child.is_inside_tree() else child.position.z
			sum_x += pos_x
			sum_z += pos_z
			count += 1

	if count == 0:
		return

	_disable_shadows(raw_children)

	var center_xz := Vector3(sum_x / count, 0.0, sum_z / count)

	for child in raw_children:
		var pos: Vector3 = child.global_position if child.is_inside_tree() else child.position
		var offset := Vector3(pos.x - center_xz.x, 0.0, pos.z - center_xz.z)
		orbit_data.append({
			"node": child,
			"offset": offset,
			"y": pos.y
		})

func _disable_shadows(targets: Array[Node3D]) -> void:
	for node in targets:
		if node is GeometryInstance3D:
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _process(delta: float) -> void:
	if not is_inside_tree() or tornado_node == null or not tornado_node.is_inside_tree() or orbit_data.is_empty():
		return

	var tornado_center: Vector3 = tornado_node.global_position
	var angle: float = deg_to_rad(orbit_speed * delta)

	for data in orbit_data:
		if data["offset"].length_squared() <= 0.00001:
			continue
		# Rotamos el offset guardado (no lo recalculamos desde la posición)
		data["offset"] = data["offset"].rotated(Vector3.UP, angle)
		var node: Node3D = data["node"]
		node.global_position = Vector3(
			tornado_center.x + data["offset"].x,
			data["y"],
			tornado_center.z + data["offset"].z
		)
