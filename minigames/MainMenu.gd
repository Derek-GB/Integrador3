extends Control

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func _on_button_pressed() -> void:
	Events.set_minigame.emit(3)

func _on_button_2_pressed() -> void:
	Events.set_minigame.emit(9)

func _on_button_3_pressed() -> void:
	Events.set_minigame.emit(13)

func _on_button_4_pressed() -> void:
	Events.set_minigame.emit(15)

func _on_button_5_pressed() -> void:
	Events.set_minigame.emit(19)

func _on_button_6_pressed() -> void:
	Events.set_minigame.emit(9)

func _on_button_9_pressed() -> void:
	Events.set_minigame.emit(13)

func _on_button_10_pressed() -> void:
	Events.set_minigame.emit(15)

func _on_button_26_pressed() -> void:
	get_tree().change_scene_to_file("res://age_selector/age_selector.tscn")
