extends Node3D

var waypoints: Array[Vector3] = []
var waypoint_rotations: Array[float] = []
var waypoint_bases: Array[Basis] = []
var current_index: int = 0
@export var speed: float = 8.0
@export var jump_height: float = 1.2

# Desplazamiento lateral para que dos fichas no se superpongan en el mismo waypoint
@export var lane_offset: Vector3 = Vector3.ZERO

signal reached_end
signal stepped_on(index: int)

# =========================================================
# SETUP
# =========================================================
func setup(board_waypoints: Array[Vector3], board_rotations: Array[float] = [], board_bases: Array[Basis] = []) -> void:
	waypoints = board_waypoints
	waypoint_rotations = board_rotations
	waypoint_bases = board_bases
	current_index = 0
	print("Ficha: setup - recibiendo waypoints:", waypoints.size(), " rotaciones:", waypoint_rotations.size())
	if waypoints.size() > 0:
		var start_offset: Vector3 = lane_offset
		if waypoint_bases.size() > 0:
			start_offset = waypoint_bases[0] * lane_offset
		global_position = waypoints[0] + start_offset
		if waypoint_rotations.size() > 0:
			rotation.y = deg_to_rad(waypoint_rotations[0])
	else:
		push_warning("Ficha: no recibió waypoints")

# =========================================================
# MOVER PASOS HACIA ADELANTE
# =========================================================
func move_steps(steps: int) -> void:
	if waypoints.is_empty():
		push_warning("Ficha: no hay waypoints para moverse")
		return
	if steps <= 0:
		return
	print("Ficha: move_steps llamado con pasos =", steps, " current_index =", current_index)
	for i in range(steps):
		# Si ya está en la meta al inicio del paso, emitir y detener
		if current_index >= waypoints.size() - 1:
			reached_end.emit()
			return
		current_index += 1
		print("Ficha: moviendo a índice", current_index, " posición:", waypoints[current_index])
		await _move_to(waypoints[current_index])
		stepped_on.emit(current_index)
		# Si acaba de llegar a la meta, emitir y detener
		if current_index >= waypoints.size() - 1:
			reached_end.emit()
			return

# =========================================================
# MOVER PASOS HACIA ATRÁS
# =========================================================
func move_back(steps: int) -> void:
	if waypoints.is_empty():
		return
	for i in range(steps):
		if current_index <= 0:
			return
		current_index -= 1
		print("Ficha: retrocediendo a índice", current_index)
		await _move_to(waypoints[current_index])

# =========================================================
# MOVER A POSICIÓN CON SALTO
# Aplica lane_offset al destino para mantener el carril
# =========================================================
func _move_to(target: Vector3) -> void:
	var offset := lane_offset
	if current_index < waypoint_bases.size():
		offset = waypoint_bases[current_index] * lane_offset
	var actual_target := target + offset
	var start_rotation_y: float = rotation.y
	var target_rotation_y: float = start_rotation_y
	if current_index < waypoint_rotations.size():
		target_rotation_y = deg_to_rad(waypoint_rotations[current_index])
	if speed <= 0:
		global_position = actual_target
		rotation.y = target_rotation_y
		return
	var start: Vector3 = global_position
	var distance: float = start.distance_to(actual_target)
	var duration: float = max(0.09, distance / speed)
	var elapsed: float = 0.0
	while elapsed < duration:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		var t: float = min(elapsed / duration, 1.0)
		var horizontal: Vector3 = start.lerp(actual_target, t)
		var height: float = sin(t * PI) * jump_height
		global_position = Vector3(horizontal.x, height, horizontal.z)
		var angle: float = lerp_angle(start_rotation_y, target_rotation_y, t)
		rotation.y = angle
	global_position = actual_target
	rotation.y = target_rotation_y
