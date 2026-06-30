extends Control

const MAIN_MENU = "res://scenes/UX/MainMenu.tscn"
const HIDDEN_POSITION: Vector2 = Vector2(2000,0)
const VISIBLE_POSITION: Vector2 = Vector2(0,0)

@onready var btn_exit = $Panel/Panel/Exit
@onready var btn_play = $Panel/Panel/Play
@onready var sound_control_panel = $Panel/Panel/SoundControlPanel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global_position = HIDDEN_POSITION
	btn_exit.pressed.connect (
		exit_game
	)
	
	btn_play.pressed.connect (
		self.close_window
	)
	
	sound_control_panel.visible_panel(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func exit_game() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU)

func open_window():
	if get_parent():
		print(get_parent())
		# Mueve el menú de pausa al último lugar dentro de $UI para que quede encima del dado
		get_parent().move_child(self, -1)
		
	global_position = VISIBLE_POSITION
	show()
	set_process(true)
	get_tree().paused = true

func close_window():
	# Mueve este control al final del contenedor para dibujarse sobre los demás
	if get_parent():
		get_parent().move_child(self, -1)
	global_position = HIDDEN_POSITION
	hide()
	set_process(false)
	get_tree().paused = false
