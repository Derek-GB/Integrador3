extends Node

func _ready():
	var pieces = [
		"res://minigames/minigame_house/assets/roof.png",
		"res://minigames/minigame_house/assets/wall_windows.png",
		"res://minigames/minigame_house/assets/wall_main.png",
		"res://minigames/minigame_house/assets/door.png",
		"res://minigames/minigame_house/assets/fence.png",
	]
	for p in pieces:
		var tex = load(p)
		print(p.get_file(), " -> ", tex.get_size())
