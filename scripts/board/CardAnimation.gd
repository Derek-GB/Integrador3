extends Node3D

var tween: Tween
@onready var fleet_manager: Node3D = $FleetManager


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_circular_turn()
	begin_float_infinitely()


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
