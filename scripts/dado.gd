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
	_result = randi() % 6 + 1

	var spawn_pos := _get_spawn_position()
	global_position = spawn_pos

	# Orientación de rombo: inclinado 45° en dos ejes
	rotation_degrees = Vector3(45, 45, 45)

	visible = true
	freeze = false

	# Entra desde el lado con velocidad horizontal + caída fuerte
	linear_velocity = Vector3(randf_range(-4, 4), -12.0, randf_range(-4, 4))

	# Giro pronunciado para que se vea rodando/girando al caer
	angular_velocity = Vector3(
		randf_range(-15, 15),
		randf_range(-15, 15),
		randf_range(-15, 15)
	)

	await _wait_for_stop()
	await _snap_to_face(_result)
	dice_rolled.emit(_result)
	roll_finished.emit(_result)
	is_rolling = false

# Lanzamiento del CPU: misma animación física que roll() pero con resultado
# predeterminado y sin emitir dice_rolled (el flujo se controla desde _machine_turn).
func roll_cpu(forced_result: int) -> void:
	if is_rolling:
		return
	roll_started.emit()
	is_rolling = true
	_result = forced_result

	var spawn_pos := _get_spawn_position()
	global_position = spawn_pos
	rotation_degrees = Vector3(45, 45, 45)
	visible = true
	freeze = false

	linear_velocity = Vector3(randf_range(-4, 4), -12.0, randf_range(-4, 4))
	angular_velocity = Vector3(
		randf_range(-15, 15),
		randf_range(-15, 15),
		randf_range(-15, 15)
	)

	await _wait_for_stop()
	await _snap_to_face(_result)
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

func _wait_for_stop() -> void:
	# Espera mínimo 0.5s y luego hasta que pare
	await get_tree().create_timer(0.5).timeout
	var timeout := 3.0
	var t := 0.0
	while linear_velocity.length() > 0.5 and t < timeout:
		await get_tree().process_frame
		t += get_process_delta_time()

func _snap_to_face(face: int) -> void:
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	var tween := create_tween()
	tween.tween_property(self, "rotation_degrees", FACE_ROTATIONS[face], 0.35).set_ease(Tween.EASE_OUT)
	await tween.finished
