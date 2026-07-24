extends Node3D
class_name CardAnimation

var tween: Tween
@onready var fleet_manager: Node3D = $FleetManager
@onready var sprite: Sprite3D = $FleetManager/Sprite3D
var players_in_range: int = 0
var fade_tween: Tween
var visibility_locked := false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_circular_turn()
	begin_float_infinitely()
	sprite.modulate.a = 0.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func start_circular_turn() -> void:
	var turn = create_tween().set_loops()
	turn.tween_callback(func(): rotation.y = 0.0)
	turn.tween_property(self, "rotation:y", TAU, 6.0).set_trans(Tween.TRANS_LINEAR)

func begin_float_infinitely() -> void:
	var tween_float = create_tween().set_loops()
	var original_height = fleet_manager.position.y
	var range_movement = 0.2 # Qué tanto sube y baja (en metros)
	var float_time = 1.5 # Tiempo que tarda en subir y luego en bajar
	tween_float.tween_property(fleet_manager, "position:y", original_height + range_movement, float_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	tween_float.tween_property(fleet_manager, "position:y", original_height - range_movement, float_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

func _forced_set_visible(force_hide: bool):
	visibility_locked = force_hide

	if visibility_locked:
		_fade_out()
	else:
		if players_in_range > 0:
			_fade_in()
		else:
			_fade_out()

func _set_visible(in_range: bool):
	if in_range:
		players_in_range += 1
	else:
		players_in_range = max(players_in_range - 1, 0)

	if visibility_locked:
		_fade_out()
		return

	if players_in_range > 0:
		_fade_in()
	else:
		_fade_out()

func _fade_in():
	if fade_tween:
		fade_tween.kill()

	if not visible:
		visible = true

	process_mode = Node.PROCESS_MODE_INHERIT

	sprite.modulate.a = sprite.modulate.a

	fade_tween = create_tween()
	fade_tween.tween_property(
		sprite,
		"modulate:a",
		1.0,
		0.25
	)

func _fade_out():
	if fade_tween:
		fade_tween.kill()

	fade_tween = create_tween()
	fade_tween.tween_property(
		sprite,
		"modulate:a",
		0.0,
		0.25
	)

	await fade_tween.finished

	if players_in_range == 0:
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
