extends CharacterBody3D

@export var speed := 5.0
@export var min_high := 1.0  # metros sobre el suelo (regla propia, no física)
@onready var raycast_ground: RayCast3D = $GroundCast3D

var can_free_move := true
var twenn: Tween

func _ready() -> void:
	# Cámara libre "voladora": sin snapping de piso/pendientes ni gravedad especial.
	# Trata todas las superficies igual (piso, pared, techo), que es justo lo que
	# necesitás para una cámara que rota y se mueve en cualquier dirección.
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING

func _physics_process(_delta: float) -> void:
	if not can_free_move:
		velocity = Vector3.ZERO
		return

	var dir := Vector3.ZERO
	if Input.is_action_pressed("ui_up"): dir.z -= 1
	if Input.is_action_pressed("ui_down"): dir.z += 1
	if Input.is_action_pressed("ui_left"): dir.x -= 1
	if Input.is_action_pressed("ui_right"): dir.x += 1
	if Input.is_action_pressed("zoom_in"): dir.y -= 1
	if Input.is_action_pressed("zoom_out"): dir.y += 1

	velocity = dir.normalized() * speed
	move_and_slide()  # resuelve paredes, techo y piso físico, con deslizamiento suave

	_correct_ground_high()

func _correct_ground_high() -> void:
	# La posición ya la heredó solo por ser hijo del body.
	# Lo único que hacemos es anular la rotación heredada, para que
	# el rayo siempre mire hacia abajo sin importar cómo rote la cámara.
	raycast_ground.global_rotation = Vector3.ZERO
	raycast_ground.force_raycast_update()

	if raycast_ground.is_colliding():
		var point: Vector3 = raycast_ground.get_collision_point()
		if global_position.y < point.y + min_high:
			if Input.is_action_pressed("zoom_in"):
				global_position.y = point.y + min_high
				if twenn != null and twenn.is_running():
					twenn.kill()
				return
			if twenn == null or not twenn.is_running():
				twenn = create_tween()
				twenn.tween_property(self,"global_position:y",point.y + min_high, 0.4)
			#global_position.y = point.y + min_high
