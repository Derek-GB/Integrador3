extends Node2D
@onready var lb_name_player: Label = $Panel/Panel/NamePlayer
@onready var lb_time: Label = $Panel/Panel/Time
@onready var btn_reload: Button = $Panel/Panel/Reload
@onready var btn_exit: Button = $Panel/Panel/Exit

const MAIN_MENU = "res://scenes/UX/MainMenu.tscn"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	btn_exit.pressed.connect (
		exit_game
	)
	
	btn_reload.pressed.connect(
		reload_game
	)
	
	_save_game_completed_achievement()

func _save_game_completed_achievement() -> void:
	var achievements_script = load("res://scripts/core/AchievementsManager.gd")
	if achievements_script and achievements_script.has_method("unlock_game_completed"):
		achievements_script.unlock_game_completed()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func exit_game() -> void:
	Events.notify_pause.emit(false)
	AudioManager.stop_all_sfx()
	get_tree().change_scene_to_file(MAIN_MENU)
	GlobalStopwatch.reset()
	
func reload_game() -> void:
	get_tree().change_scene_to_file("res://scenes/core/Main.tscn")
	GlobalStopwatch.reset()

func text_name_player(text: String) -> void:
	lb_name_player.text = text

func set_player_color(color: Color) -> void:
	if lb_name_player:
		lb_name_player.add_theme_color_override("font_color", color)

func text_total_time(text: String) -> void:
	lb_time.text = text
