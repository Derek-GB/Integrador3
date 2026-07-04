extends Node3D

@export var speed = 5.0
@export var min_high = 1.0 # metros sobre el suelo

var can_free_move = true

@onready var raycast = $RayCast3D
@onready var main_camera = $MainCamera
@onready var default_pos: Marker3D = $DefaultPosition

func _physics_process(delta):
	if not can_free_move: return
	
	var dir = Vector3.ZERO
	if Input.is_action_pressed("ui_up"):
		dir.z -= 1
	if Input.is_action_pressed("ui_down"):
		dir.z += 1
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1
	if Input.is_action_pressed("ui_right"):
		dir.x += 1
	if Input.is_action_pressed("zoom_in"):
		dir.y -= 1
	if Input.is_action_pressed("zoom_out"):
		dir.y += 1
	
	# Mover TODO el rig, no solo la cámara
	main_camera.global_position += dir.normalized() * speed * delta
	raycast.global_position += dir.normalized() * speed * delta

	# Forzar actualización del raycast antes de leerlo
	raycast.force_raycast_update()
	
	# Ajustar altura mínima contra el suelo
	if raycast.is_colliding():
		var collision_point = raycast.get_collision_point()
		if main_camera.global_position.y < collision_point.y + min_high:
			main_camera.global_position.y = collision_point.y + min_high
			raycast.global_position.y = collision_point.y + min_high
