extends Node

var elapsed_time: float = 0.0
var is_running: bool = false

func _process(delta: float) -> void:
	if is_running:
		elapsed_time += delta

func start() -> void:
	is_running = true

func stop() -> void:
	is_running = false

func reset() -> void:
	elapsed_time = 0.0
	is_running = false
