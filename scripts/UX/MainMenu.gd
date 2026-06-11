extends Control

const MAIN = preload("res://scenes/main.tscn")
const POS_CENTER = 910.0
const POS_OUTSIDE_RIGHT = 2000.0
const HOME_BUTTONS = 178.0
const SIDE_BUTTONS = 150.0
const DURATION = 1.3

var current_menu: Control = null

@onready var button_menu: Control = $ButtonMenu
@onready var game_selection: Control = $GameSelection
@onready var game_rules: Control = $GameRules

@onready var btn_play_menu: Button = $ButtonMenu/Play
@onready var btn_rule_menu: Button = $ButtonMenu/Rules
@onready var btn_credits_menu: Button = $ButtonMenu/Credits
@onready var btn_exit_menu: Button = $ButtonMenu/Exit
@onready var btn_1vs1: Button = $"GameSelection/1Vs1"
@onready var btn_1vsbot: Button = $"GameSelection/1VsBot"
@onready var btn_close_selection: Button = $GameSelection/CloseSelection
@onready var btn_close_rules: Button = $GameRules/CloseRules

@onready var lobby1: AudioStreamPlayer = $Lobby1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	lobby1.play()

	btn_exit_menu.pressed.connect (
		exit_game
	)

	btn_play_menu.pressed.connect(
		func(): 
			open_menu(game_selection)
	)

	btn_close_selection.pressed.connect(
		func(): 
			close_all()
	)

	btn_rule_menu.pressed.connect(
		func(): 
			open_menu(game_rules)
	)

	btn_close_rules.pressed.connect(
		func(): 
			close_all()
	)

	btn_1vs1.pressed.connect(
		func():
			GameManager.game_mode = 1
			get_tree().change_scene_to_packed(MAIN)
	)

	btn_1vsbot.pressed.connect(
		func():
			GameManager.game_mode = 2
			get_tree().change_scene_to_packed(MAIN)
	)

	for i in $ButtonMenu.get_children():
		if i is Button:
			connect_hover(i)
			i.pivot_offset = i.position

func exit_game() -> void:
	get_tree().quit()

func connect_hover(btn: Control) -> void:
	btn.mouse_entered.connect(resize_up.bind(btn))
	btn.mouse_exited.connect(resize_down.bind(btn))

func resize_up(btn: Control) -> void:
	btn.scale = Vector2(1.05, 1.05)

func resize_down(btn: Control) -> void:
	btn.scale = Vector2.ONE

func open_menu(new_menu: Control) -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(button_menu, "position:x", SIDE_BUTTONS, DURATION)
	if current_menu and current_menu != new_menu:
		tween.tween_property(current_menu, "position:x", POS_OUTSIDE_RIGHT, DURATION)
	new_menu.position.x = POS_OUTSIDE_RIGHT
	tween.tween_property(new_menu, "position:x", POS_CENTER, DURATION)
	current_menu = new_menu

func close_all() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(button_menu, "position:x", HOME_BUTTONS, DURATION)
	if current_menu:
		tween.tween_property(current_menu, "position:x", POS_OUTSIDE_RIGHT, DURATION)
		current_menu = null
