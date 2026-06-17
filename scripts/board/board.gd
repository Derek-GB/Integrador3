extends Node3D

# En el inspector tienes que poner tanto la escena
# de tarjeta roja, como la de azul
@export var red_pointer_scene: PackedScene
@export var blue_pointer_scene: PackedScene

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

	var c: int = 0
	for child in path_node.get_children():
		if child is Marker3D:
			waypoints.append(child.global_position)
			waypoint_rotations.append(child.rotation_degrees.y)
			waypoint_bases.append(child.global_transform.basis)
			print("Board: waypoint[", waypoints.size() - 1, "] =", child.global_position, " rotation_y=", child.rotation_degrees.y)
			
			if c in GameManager.RED_TILE_INDICES:
				_add_pointer(red_pointer_scene, child, "rojo", c)
			elif c in GameManager.BLUE_TILE_INDICES:
				_add_pointer(blue_pointer_scene, child, "azul", c)
			c += 1

	print("Board: build complete, total waypoints =", waypoints.size())

func _add_pointer(pointer_scene: PackedScene, child: Node3D, color: String, c: int) -> void:
	if pointer_scene == null: return
	child.add_child(pointer_scene.instantiate())
	print("Puntero ", color ," en casilla: ", c)

func get_waypoints() -> Array[Vector3]:
	return waypoints

func get_waypoint_rotations() -> Array[float]:
	return waypoint_rotations

func get_waypoint_bases() -> Array[Basis]:
	return waypoint_bases
