extends Node3D

# En el inspector tienes que poner tanto la escena
# de tarjeta roja, como la de azul
@export var red_pointer_scene: PackedScene
@export var blue_pointer_scene: PackedScene

var waypoints: Array[Vector3] = []
var waypoint_rotations: Array[float] = []
var waypoint_bases: Array[Basis] = []
var ordered_markers: Array[Node3D] = []

var alt_waypoints: Array[Vector3] = []
var alt_rotations: Array[float] = []
var alt_bases: Array[Basis] = []
var special_waypoints: Dictionary = {}
var special_rotations: Dictionary = {}
var special_bases: Dictionary = {}

@export var path_node: Node3D # Arrastra aquí el nodo "Camino" desde el Inspector
@export var alt_path_node: Node3D

func _ready() -> void:
	_build_waypoints()
	_build_alt_waypoints()
	_build_ordered_markers()  # <-- agregar esto
	Events.visible_pointer.connect(_set_pointer_visible)
	Events.forced_visible_pointer.connect(_set_pointer_visible_forced)
	$Tornado/AnimationTree.play("spinnig")
	$Mapa/Casa3DespuesVolcan.tornado_node = $Tornado
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

			var nested_marker := _find_nested_marker(child)
			if nested_marker != null:
				special_waypoints[c] = nested_marker.global_position
				special_rotations[c] = nested_marker.rotation_degrees.y
				special_bases[c] = nested_marker.global_transform.basis
				print("Board: special waypoint[", c, "] =", nested_marker.global_position)
			
			if c in GameManager.RED_TILE_INDICES:
				_add_pointer(red_pointer_scene, child, "rojo", c)
			elif c in GameManager.BLUE_TILE_INDICES:
				_add_pointer(blue_pointer_scene, child, "azul", c)
			c += 1

	print("Board: build complete, total waypoints =", waypoints.size())

func _build_alt_waypoints() -> void:
	alt_waypoints.clear()
	alt_rotations.clear()
	alt_bases.clear()

	if alt_path_node == null:
		print("Camino alterno vacio")
		return

	for child in alt_path_node.get_children():
		if child is Marker3D:
			alt_waypoints.append(child.global_position)
			alt_rotations.append(child.rotation_degrees.y)
			alt_bases.append(child.global_transform.basis)
	print("AltPath Completo con: ", alt_waypoints.size())

func _add_pointer(pointer_scene: PackedScene, child: Node3D, color: String, c: int) -> void:
	if pointer_scene == null: return
	child.add_child(pointer_scene.instantiate())
	print("Puntero ", color ," en casilla: ", c)

func _set_pointer_visible(pointer: int, can_visible: bool):
	if pointer < 0 or pointer >= ordered_markers.size():
		return
	var marker := ordered_markers[pointer]
	if marker.get_child_count() == 0:
		return
	var pointer_card := marker.get_child(0)
	print("Primero: ", marker)
	print("Segundo: ", pointer_card)
	if pointer_card == null: return
	print("Visibilidad inicial de ", pointer, ": ", pointer_card.visible, " / modo: ", pointer_card.process_mode)
	if pointer_card.has_method("_set_visible"):
		pointer_card._set_visible(can_visible)
	print("Visibilidad despues de ", pointer, ": ", pointer_card.visible, " / modo: ", pointer_card.process_mode)

func _set_pointer_visible_forced(pointer: int, can_visible: bool):
	if pointer < 0 or pointer >= ordered_markers.size():
		return
	var marker := ordered_markers[pointer]
	if marker.get_child_count() == 0:
		return
	var pointer_card := marker.get_child(0)
	print("Primero: ", marker)
	print("Segundo: ", pointer_card)
	if pointer_card == null: return
	print("Visibilidad inicial de ", pointer, ": ", pointer_card.visible, " / modo: ", pointer_card.process_mode)
	if pointer_card.has_method("_forced_set_visible"):
		pointer_card._forced_set_visible(can_visible)
	print("Visibilidad despues de ", pointer, ": ", pointer_card.visible, " / modo: ", pointer_card.process_mode)


func _find_nested_marker(node: Node) -> Marker3D:
	for nested in node.get_children():
		if nested is Marker3D:
			return nested
	return null

func _build_ordered_markers() -> void:
	ordered_markers.clear()
	for child in path_node.get_children():
		if child is Marker3D:
			ordered_markers.append(child)
	print("Board: markers ordenados =", ordered_markers.size())

func get_special_waypoints() -> Dictionary:
	return special_waypoints

func get_special_rotations() -> Dictionary:
	return special_rotations

func get_special_bases() -> Dictionary:
	return special_bases

func get_waypoints() -> Array[Vector3]:
	return waypoints

func get_waypoint_rotations() -> Array[float]:
	return waypoint_rotations

func get_waypoint_bases() -> Array[Basis]:
	return waypoint_bases

func get_alt_waypoints() -> Array[Vector3]:
	return alt_waypoints

func get_alt_rotations() -> Array[float]:
	return alt_rotations

func get_alt_bases() -> Array[Basis]:
	return alt_bases
