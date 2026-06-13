extends Node3D

var waypoints: Array[Vector3] = []
var waypoint_rotations: Array[float] = []
var waypoint_bases: Array[Basis] = []

@export var path_node: Node3D # Arrastra aquí el nodo "Camino" desde el Inspector

func _ready() -> void:
	_build_waypoints()
	print("Board: waypoints cargados =", waypoints.size())

func _build_waypoints() -> void:
	waypoints.clear()
	waypoint_rotations.clear()
	waypoint_bases.clear()

	if path_node == null:
		push_error("Board: path_node está vacío. Arrastra el nodo Camino en el Inspector.")
		return

	for child in path_node.get_children():
		if child is Marker3D:
			waypoints.append(child.global_position)
			waypoint_rotations.append(child.rotation_degrees.y)
			waypoint_bases.append(child.global_transform.basis)
			print("Board: waypoint[", waypoints.size() - 1, "] =", child.global_position, " rotation_y=", child.rotation_degrees.y)

	print("Board: build complete, total waypoints =", waypoints.size())

func get_waypoints() -> Array[Vector3]:
	return waypoints

func get_waypoint_rotations() -> Array[float]:
	return waypoint_rotations

func get_waypoint_bases() -> Array[Basis]:
	return waypoint_bases
