extends Area2D
class_name Lightning

@export var fall_speed := 430.0
@export var spin_speed := 0.0

# FIX: radio propio del rayo para la detección manual.
# Ajusta según el tamaño visual real del sprite del rayo.
@export var hit_radius: float = 40.0

var _screen_height := 720.0
var _already_hit_player := false


func _ready():
	monitoring = true
	monitorable = true
	fall_speed = randf_range(380.0, 520.0)
	rotation_degrees = randf_range(-8.0, 8.0)
	scale = Vector2.ONE * randf_range(0.85, 1.15)

	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# Dejamos la señal conectada por si en algún momento el pause deja de
	# usarse y el sistema automático de Godot vuelve a funcionar normal.
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _physics_process(delta):
	_screen_height = get_viewport_rect().size.y
	position.y += fall_speed * delta
	if spin_speed != 0:
		rotation_degrees += spin_speed * delta

	# FIX PRINCIPAL: en vez de depender de get_overlapping_bodies()
	# (que no es confiable con get_tree().paused = true en este proyecto),
	# comprobamos manualmente la distancia contra el/los jugadores del
	# grupo "storm_player". Esto corre en _physics_process, que ya
	# confirmamos que SÍ se sigue ejecutando en pausa gracias a
	# process_mode = WHEN_PAUSED.
	_check_manual_hit()

	if position.y > _screen_height + 100:
		queue_free()


func _check_manual_hit() -> void:
	if _already_hit_player:
		return

	var players := get_tree().get_nodes_in_group("storm_player")
	for player in players:
		if player == null or not is_instance_valid(player):
			continue

		var player_hit_radius: float = 45.0
		if player.has_method("get") and ("hit_radius" in player):
			player_hit_radius = player.hit_radius

		var distance: float = global_position.distance_to(player.global_position)
		var combined_radius: float = hit_radius + player_hit_radius

		if distance <= combined_radius:
			_damage_player(player)
			return


# Se mantiene por compatibilidad, en caso de que la detección automática
# de Godot funcione en algún momento (por ejemplo, si luego quitan el pause).
func _on_body_entered(body):
	_damage_player(body)


func _damage_player(body):
	if _already_hit_player:
		return
	if body == null:
		return
	if body.has_method("take_damage"):
		_already_hit_player = true
		body.take_damage()
		queue_free()
