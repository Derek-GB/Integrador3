extends RigidBody3D

var is_rolling: bool = false
var is_locked: bool = false
var _result: int = 0

const FACE_ROTATIONS: Dictionary = {
	1: Vector3(-90,  0,   0),
	2: Vector3(0,    0,  90),
	3: Vector3(180,  0,   0),
	4: Vector3(0,    0,   0),
	5: Vector3(0,    0, -90),
	6: Vector3(90,   0,   0),
}

signal dice_rolled(n: int)
signal roll_started
signal roll_finished(n: int)

# Llamado desde main.gd para inyectar la cámara
var _camera: Camera3D = null

func setup(camera: Camera3D) -> void:
	_camera = camera

func set_locked(value: bool) -> void:
	is_locked = value

func roll() -> void:
	if is_rolling or is_locked:
		return
	roll_started.emit()
	is_rolling = true

	global_position = _get_spawn_position()
	rotation_degrees = Vector3(
		randf_range(0, 360),
		randf_range(0, 360),
		randf_range(0, 360)
	)
	visible = true
	freeze = false

	linear_velocity = Vector3(randf_range(-3, 3), -14.0, randf_range(-3, 3))
	angular_velocity = Vector3(
		randf_range(-20, 20),
		randf_range(-20, 20),
		randf_range(-20, 20)
	)

	await _wait_for_stop()

	# Comprobación de seguridad tras la simulación física
	if not is_inside_tree():
		return

	_result = _get_face_up()
	dice_rolled.emit(_result)
	roll_finished.emit(_result)
	is_rolling = false

# Lanzamiento del CPU: misma animación física que roll() pero con resultado
# predeterminado y sin emitir dice_rolled (el flujo se controla desde _machine_turn).
func roll_cpu() -> void:
	if is_rolling:
		return
	roll_started.emit()
	is_rolling = true

	global_position = _get_spawn_position()
	rotation_degrees = Vector3(
		randf_range(0, 360),
		randf_range(0, 360),
		randf_range(0, 360)
	)
	visible = true
	freeze = false

	linear_velocity = Vector3(randf_range(-3, 3), -14.0, randf_range(-3, 3))
	angular_velocity = Vector3(
		randf_range(-20, 20),
		randf_range(-20, 20),
		randf_range(-20, 20)
	)

	await _wait_for_stop()

	# Comprobación de seguridad tras la simulación física
	if not is_inside_tree():
		return

	_result = _get_face_up()
	roll_finished.emit(_result)
	is_rolling = false

func _get_spawn_position() -> Vector3:
	if _camera == null:
		return Vector3(0, 30, 0)
	var cam_pos := _camera.global_position
	var cam_right := _camera.global_transform.basis.x
	# Entra desde la derecha, a media altura
	return Vector3(
		cam_pos.x + cam_right.x * 10,
		cam_pos.y + 7,
		cam_pos.z + cam_right.z * 10
	)

func _get_face_up() -> int:
	# Normales locales de cada cara (hacia afuera)
	var face_normals: Dictionary = {
		1: Vector3(0,   0,  1),  # era 3
		2: Vector3(1,   0,  0),
		3: Vector3(0,  -1,  0),  # era 1
		4: Vector3(0,   1,  0),
		5: Vector3(-1,  0,  0),
		6: Vector3(0,   0, -1),
	}
	var best_face := 1
	var best_dot := -INF
	for face in face_normals:
		var world_normal: Vector3 = global_transform.basis * face_normals[face]
		var dot: float = world_normal.dot(Vector3.UP)
		if dot > best_dot:
			best_dot = dot
			best_face = face
	return best_face

func _wait_for_stop() -> void:
	if not is_inside_tree():
		return
		
	var tree := get_tree()
	if tree == null:
		return

	# Espera mínimo 0.5s
	await tree.create_timer(0.5).timeout
	
	# Comprobación tras la primera espera
	if not is_inside_tree():
		return
		
	var timeout := 3.0
	var t := 0.0
	while linear_velocity.length() > 0.3 and t < timeout:
		if not is_inside_tree():
			return
			
		await get_tree().process_frame
		
		if not is_inside_tree():
			return
		
		# Opcional: No avanzar el tiempo si el juego está pausado
		if get_tree().paused:
			continue
			
		t += get_process_delta_time()

func _snap_to_face(face: int) -> void:
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	var tween := create_tween()
	tween.tween_property(self, "rotation_degrees", FACE_ROTATIONS[face], 0.35).set_ease(Tween.EASE_OUT)
	await tween.finished
