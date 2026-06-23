extends Node3D
var waypoints: Array[Vector3] = []
var waypoint_rotations: Array[float] = []
var waypoint_bases: Array[Basis] = []
var current_index: int = 0
@export var speed: float = 8.0
@export var jump_height: float = 1.2
# Desplazamiento lateral actual (se recalcula solo, ver _resolve_lane_offset)
@export var lane_offset: Vector3 = Vector3.ZERO
# Magnitud del desplazamiento cuando esta ficha comparte casilla con otra
@export var lane_split_offset: float = 1.75
# Lado de carril de esta ficha cuando hay que compartir casilla: -1 = -x, 1 = +x
@export var lane_side: float = -1.0
var _lane_tween: Tween = null
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
		lane_offset = _resolve_lane_offset(current_index)
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
		lane_offset = _resolve_lane_offset(current_index)
		print("Ficha: retrocediendo a índice", current_index)
		await _move_to(waypoints[current_index])
# =========================================================
# MOVER A POSICIÓN CON SALTO
# Aplica lane_offset al destino para mantener el carril
# =========================================================
func _move_to(target: Vector3) -> void:
	if _lane_tween and _lane_tween.is_valid():
		_lane_tween.kill()
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
		var arc: float = sin(t * PI) * jump_height
		global_position = Vector3(horizontal.x, horizontal.y + arc, horizontal.z)
		var angle: float = lerp_angle(start_rotation_y, target_rotation_y, t)
		rotation.y = angle
	global_position = actual_target
	rotation.y = target_rotation_y
# =========================================================
# AJUSTAR CARRIL LATERAL (cuando comparte casilla con otra ficha)
# No mueve current_index ni hace el salto, solo desliza
# la ficha entre el centro del waypoint y su offset lateral.
# =========================================================
func update_lane_offset(new_offset: Vector3, animate: bool = true) -> void:
	if lane_offset.is_equal_approx(new_offset):
		return
	lane_offset = new_offset
	if waypoints.is_empty() or current_index >= waypoints.size():
		return
	var base: Basis = Basis.IDENTITY
	if current_index < waypoint_bases.size():
		base = waypoint_bases[current_index]
	var target_pos: Vector3 = waypoints[current_index] + base * lane_offset
	if not animate or speed <= 0:
		global_position = target_pos
		return
	if _lane_tween and _lane_tween.is_valid():
		_lane_tween.kill()
	_lane_tween = create_tween()
	_lane_tween.tween_property(self, "global_position", target_pos, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
# =========================================================
# RESOLVER OFFSET LATERAL SEGÚN OCUPACIÓN DE LA CASILLA DESTINO
# Si otra ficha registrada ya está parada en target_index, esta
# ficha usa su carril (lane_side) y, además, le avisa a esa otra
# ficha que se haga a un lado YA MISMO -- así ambas se desplazan
# en paralelo (una saltando, la otra deslizándose) en vez de que
# el acomodo lateral pase recién después de aterrizar.
# Se llama ANTES de cada _move_to para hornear el desplazamiento
# propio directamente en el salto (sin Tween paralelo para uno mismo).
# =========================================================
func _resolve_lane_offset(target_index: int) -> Vector3:
	for t in GameManager.tokens:
		if t == self or not is_instance_valid(t):
			continue
		if t.current_index == target_index:
			if t.has_method("update_lane_offset"):
				t.update_lane_offset(Vector3(t.lane_side * t.lane_split_offset, 0.0, 0.0), true)
			return Vector3(lane_side * lane_split_offset, 0.0, 0.0)
	return Vector3.ZERO

func travel_alt_path(
	path_points: Array[Vector3],
	path_rotations: Array[float],
	path_bases: Array[Basis],
	exit_position: Vector3,
	exit_rotation: float
) -> void:

	for i in range(path_points.size()):
		var save_rotations := waypoint_rotations
		var save_bases := waypoint_bases

		waypoint_rotations = path_rotations
		waypoint_bases = path_bases

		await _move_to(path_points[i])

		waypoint_rotations = save_rotations
		waypoint_bases = save_bases

	var old_rotations := waypoint_rotations
	var old_bases := waypoint_bases

	waypoint_rotations = [exit_rotation]
	waypoint_bases = [Basis.IDENTITY]

	await _move_to(exit_position)

	waypoint_rotations = old_rotations
	waypoint_bases = old_bases
