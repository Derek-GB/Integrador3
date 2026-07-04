extends Node3D

@export var camera_smooth_speed: float = 5.0
@export var turn_camera_delay: float = 0.7
@export var dice_sound: AudioStream
@export var move_sound_old: AudioStream
@export var move_forward_sound: AudioStream
@export var game_over_sound: AudioStream
@export var lobby1: AudioStream
@export var lobby2: AudioStream
@export var victory_sound: AudioStream
@export var move_back_sound: AudioStream
@export var move_sound: AudioStream
@export var board_sound: AudioStream
@export var time_over_sound: AudioStream
# Separación lateral entre fichas cuando comparten casilla
@export var lane_split_offset: float = 1.75

# =========================================================
# NODOS DE LA ESCENA
# =========================================================
@onready var map                            = $Map
@onready var piece                          = $Map/Token
@onready var camera_rig: Node3D             = $Camera_rig
@onready var camera_free_body: CharacterBody3D = $Camera_rig/CameraFreeBody
@onready var camera: Camera3D               = $Camera_rig/CameraFreeBody/MainCamera
@onready var marker_iso: Marker3D           = $Camera_rig/Marker_Iso
@onready var default_cam_position: Marker3D = $Camera_rig/DefaultPosition
@onready var dice_label: Label              = $UI/InfoPanel/DiceLabel
@onready var turn_label: Label              = $UI/InfoPanel/TurnLabel
@onready var position_label: Label          = $UI/InfoPanel/PositionLabel
@onready var btn_pause: Button              = $UI/Pause
@onready var btn_throw: Button              = $UI/BtnThrow
@onready var btn_throw_3: Button            = $UI/Throw_3
@onready var btn_restart: Button            = $UI/Restart
@onready var btn_third: Button              = $UI/Third_person
@onready var btn_iso: Button                = $UI/Iso
@onready var btn_bind_cam: Button           = $UI/BindCam
@onready var pause_menu                     = $UI/PauseMenu
@onready var btn_minigame: Button           = $UI/Test_MG

const DICE_OVERLAY_SCENE = preload("res://scenes/UX/DiceOverlay.tscn")
const STOP_MENU          = preload("res://scenes/UX/PauseMenu.tscn")
const PIECE_SCENE        = preload("res://scenes/board/Token2.tscn")

# =========================================================
# VARIABLES
# =========================================================
var game_over: bool = false
var game_mode: int  = 1
var _waypoints: Array[Vector3]        = []
var _waypoint_rotations: Array[float] = []
var _waypoint_bases: Array[Basis]     = []
var _camera_delay_timer: float  = 0.0
var _camera_delay_active: bool  = false
var _dice_overlay_instance: Node = null
var piece2 = null

# =========================================================
# CICLO DE VIDA
# =========================================================
func _ready() -> void:
	_waypoints          = map.get_waypoints()
	_waypoint_rotations = map.get_waypoint_rotations()
	_waypoint_bases     = map.get_waypoint_bases()
	print("Main: waypoints =", _waypoints.size(), " rotaciones =", _waypoint_rotations.size(), " bases =", _waypoint_bases.size())

	camera.make_current()
	camera_free_body.transform = default_cam_position.transform

	btn_throw.pressed.connect(_on_btn_throw)
	btn_throw.disabled = true
	btn_pause.pressed.connect(_on_pause)
	btn_throw_3.pressed.connect(_on_throw_3)
	btn_restart.pressed.connect(_on_restart)
	btn_third.pressed.connect(switch_camera.bind(default_cam_position))
	btn_iso.pressed.connect(switch_camera.bind(marker_iso))
	btn_minigame.pressed.connect(_on_minigame_test)
	btn_bind_cam.pressed.connect(switch_camera.bind(default_cam_position))

	Events.turn_changed.connect(_on_turn_changed)
	Events.play_sound.connect(_on_play_sound)
	Events.set_minigame.connect(_on_set_minigame)
	Events.minigame_intro_started.connect(_on_minigame_intro_started)
	Events.minigame_confirmed.connect(_on_minigame_confirmed)
	Events.minigame_finished.connect(_on_minigame_finished)

	_dice_overlay_instance = DICE_OVERLAY_SCENE.instantiate()
	_dice_overlay_instance.visible = false
	add_child(_dice_overlay_instance)
	_dice_overlay_instance.overlay_done.connect(_on_dice_rolled)

	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	AudioManager.play_music(board_sound)
	_start_game()

func _process(delta: float) -> void:
	if GameManager.tokens.is_empty():
		return

	if _camera_delay_active:
		_camera_delay_timer -= delta
		if _camera_delay_timer <= 0.0:
			_camera_delay_active = false
		else:
			return

	var active: Node3D
	if GameManager.current_player < GameManager.tokens.size():
		active = GameManager.tokens[GameManager.current_player]
	else:
		active = piece

	var follow_weight: float = clamp(delta * camera_smooth_speed, 0.0, 1.0)
	camera_rig.global_position = camera_rig.global_position.lerp(active.global_position, follow_weight)

	var target_yaw: float = deg_to_rad(active.rotation_degrees.y)
	camera_rig.rotation.y = lerp_angle(camera_rig.rotation.y, target_yaw, follow_weight)
	camera_rig.rotation.y = fmod(camera_rig.rotation.y + TAU, TAU)
	if camera_rig.rotation.y < 0.0:
		camera_rig.rotation.y += TAU

# =========================================================
# MÉTODOS PÚBLICOS
# =========================================================
func switch_camera(marker: Marker3D, free_move: bool = true) -> void:
	camera_free_body.can_free_move = false
	var active: Node3D
	if GameManager.current_player < GameManager.tokens.size():
		active = GameManager.tokens[GameManager.current_player]
	else:
		active = piece
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(camera_free_body, "transform", marker.transform, 0.6)
	tween.tween_property(camera_rig, "rotation:y", deg_to_rad(active.rotation_degrees.y), 0.6)
	tween.set_parallel(false)
	tween.tween_callback(func(): camera_free_body.can_free_move = free_move)
# =========================================================
# MÉTODOS PRIVADOS
# =========================================================
func _start_game() -> void:
	var mode := GameManager.game_mode
	game_mode = mode
	GameManager.tokens.clear()
	GameManager.current_player = 0

	if mode == 1:
		GameManager.player_names = ["Jugador 1", "Jugador 2"]
	else:
		GameManager.player_names = ["Jugador", "Maquina"]

	piece.setup(_waypoints, _waypoint_rotations, _waypoint_bases)
	GameManager.register_token(piece)
	piece.reached_end.connect(_on_ficha1_reached_end)
	piece.stepped_on.connect(_on_ficha_stepped)
	piece.lane_side = -1.0
	piece.lane_split_offset = lane_split_offset

	piece2 = PIECE_SCENE.instantiate()
	piece2.name = "Ficha2"
	map.add_child(piece2)
	piece2.setup(_waypoints, _waypoint_rotations, _waypoint_bases)
	GameManager.register_token(piece2)
	piece2.reached_end.connect(_on_ficha2_reached_end)
	piece2.stepped_on.connect(_on_ficha_stepped)
	piece2.lane_side = 1.0
	piece2.lane_split_offset = lane_split_offset

	# Ambas fichas arrancan en la misma casilla (Inicio), así que se separan
	# de una vez, sin animación, antes de que el jugador vea el tablero.
	_update_lane_offsets(false)

	_add_tag(piece, "J1")
	if mode == 2:
		_add_tag(piece2, "CPU")
	else:
		_add_tag(piece2, "J2")

	btn_throw.disabled = false
	dice_label.text = "Tira el dado"
	_update_turn_label(0)
	_update_position_label()
	for i in range(1,7):
		Events.visible_pointer.emit(i,true)
		Events.visible_pointer.emit(i,true)
	print("Main: juego iniciado modo", mode)

func _add_tag(f: Node3D, texto: String) -> void:
	var lbl := Label3D.new()
	lbl.text = texto
	lbl.position = Vector3(0, 8, 0)
	lbl.font_size = 64
	lbl.outline_size = 8
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	f.add_child(lbl)

# =========================================================
# CARRIL LATERAL ENTRE FICHAS
# Si ambas fichas están en la misma casilla, se separan
# (J1 hacia -x, J2 hacia +x). Si no, ambas van por el centro.
# =========================================================
func _update_lane_offsets(animate: bool = true) -> void:
	if piece == null or piece2 == null:
		return
	if piece.current_index == piece2.current_index:
		piece.update_lane_offset(Vector3(-lane_split_offset, 0.0, 0.0), animate)
		piece2.update_lane_offset(Vector3(lane_split_offset, 0.0, 0.0), animate)
	else:
		piece.update_lane_offset(Vector3.ZERO, animate)
		piece2.update_lane_offset(Vector3.ZERO, animate)

func _on_ficha_stepped(_index: int) -> void:
	AudioManager.play_sfx(move_sound)
	_update_position_label()
	_update_lane_offsets()
	var type := GameManager.last_action_type
	if type == "advance":
		AudioManager.play_sfx(move_forward_sound)
		GameManager.last_action_type = ""
	elif type == "go_back":
		AudioManager.play_sfx(move_back_sound)
		GameManager.last_action_type = ""
	elif type == "go_to_space":
		AudioManager.play_sfx(move_sound)
		GameManager.last_action_type = ""
	Events.visible_pointer.emit(_index+6,true)
	Events.visible_pointer.emit(_index-6,false)

func _on_pause() -> void:
	pause_menu.open_window()

func _on_minigame_test() -> void:
	Events.set_minigame.emit(15)

func _on_throw_3() -> void:
	if game_over:
		return
	if game_mode == 2 and GameManager.current_player == 1:
		return
	AudioManager.play_sfx(dice_sound)
	dice_label.text = "Tiraste un 3"
	await GameManager.on_dice_rolled(15)


func _on_restart() -> void:
	var mg := get_node_or_null("ActiveMinigame")
	if mg:
		mg.queue_free()
	if GameManager.minigame_active:
		Events.minigame_result.emit(false)  # false = perdió por rendirse
	GameManager.tokens.clear()
	GameManager.current_player    = 0
	GameManager.is_player_moving  = false
	GameManager.minigame_active   = false
	GameManager.skip_player_index = -1
	GameManager.last_action_type  = ""
	get_tree().reload_current_scene()
	for i in range(1,7):
		Events.visible_pointer.emit(i,true)

func _on_btn_throw() -> void:
	if game_over or _dice_overlay_instance == null:
		return
	btn_throw.disabled = true
	get_tree().create_timer(0.5).timeout.connect(AudioManager.play_sfx.bind(dice_sound), CONNECT_ONE_SHOT)
	await _dice_overlay_instance._show()

func _on_dice_rolled(n: int) -> void:
	if game_over:
		return
	await get_tree().create_timer(0.15).timeout
	dice_label.text = "Tiraste un %d" % n
	await GameManager.on_dice_rolled(n)

func _on_turn_changed(player_index: int) -> void:
	if game_over:
		return
	_camera_delay_timer  = turn_camera_delay
	_camera_delay_active = true
	_update_turn_label(player_index)
	btn_throw.disabled = true
	print("Main: turn_changed recibido =", player_index)

	if GameManager.skip_player_index == player_index:
		GameManager.skip_player_index = -1
		_apply_skip(player_index)
		return

	if game_mode == 2 and player_index == 1:
		dice_label.text = "Turno de la Maquina..."
		print("Main: ejecutando turno CPU")
		_machine_turn()
	else:
		btn_throw.disabled = false
		dice_label.text = "Tira el dado"

func _on_play_sound(sound_name: String) -> void:
	if sound_name == "avanzar":
		AudioManager.play_sfx(move_forward_sound)
	elif sound_name == "retroceder":
		AudioManager.play_sfx(move_back_sound)

# Recibe el índice de casilla, llena MinigameData e instancia MinigameIntro
func _on_set_minigame(tile_index: int) -> void:
	if not GameManager.MINIGAMES.has(tile_index):
		push_warning("Main: no hay minijuego definido para casilla %d" % tile_index)
		return
	var data: Dictionary = GameManager.MINIGAMES[tile_index]
	var minigame_data := get_node("/root/MinigameData")
	minigame_data.title          = data["title"]
	minigame_data.description    = data["description"]
	minigame_data.instructions   = data["instructions"]
	minigame_data.video_path     = data["video_path"]
	minigame_data.minigame_scene = data["minigame_scene"]
	minigame_data.controls       = data["controls"]
	var intro: Control = load("res://minigames/ui_global/MinigameIntro.tscn").instantiate()
	add_child(intro)
	Events.minigame_intro_started.emit()

func _on_minigame_intro_started() -> void:
	$UI.visible = false
	AudioManager.stop_music()

func _on_minigame_confirmed() -> void:
	var path: String = MinigameData.minigame_scene
	print("Cargando minijuego:", path)
	var mg_scene = load(path)
	if mg_scene == null:
		print("ERROR: no se pudo cargar la escena en:", path)
		return
	var mg: Node = mg_scene.instantiate()
	mg.name = "ActiveMinigame"
	add_child(mg)
	if mg.has_signal("minigame_finished"):
		mg.minigame_finished.connect(func(): Events.minigame_finished.emit(), CONNECT_ONE_SHOT)
	# Aplica el modo a todo el árbol del minijuego
	#_set_process_mode_recursive(mg, Node.PROCESS_MODE_WHEN_PAUSED)
	#Events.notify_pause.emit(true)

func _on_minigame_finished() -> void:
	var mg := get_node_or_null("ActiveMinigame")
	if mg:
		mg.queue_free()
	$UI.visible = true
	AudioManager.play_music(board_sound)

func _set_process_mode_recursive(node: Node, mode: int) -> void:
	node.process_mode = mode
	for child in node.get_children():
		_set_process_mode_recursive(child, mode)

func _apply_skip(player_index: int) -> void:
	var _name: String
	if game_mode == 1:
		_name = "Jugador %d" % (player_index + 1)
	elif player_index == 0:
		_name = "el Jugador"
	else:
		_name = "la Maquina"

	dice_label.text = "%s pierde este turno" % _name
	if GameManager.message_label:
		GameManager.message_label.visible = true
		GameManager.message_label.text    = "¡%s pierde este turno!" % _name

	await get_tree().create_timer(2.0).timeout

	if GameManager.message_label:
		GameManager.message_label.visible = false

	if not game_over:
		GameManager._next_turn()

func _machine_turn() -> void:
	await get_tree().create_timer(0.3).timeout
	if game_over:
		return
	dice_label.text = "La Maquina esta tirando el dado..."
	get_tree().create_timer(0.5).timeout.connect(AudioManager.play_sfx.bind(dice_sound), CONNECT_ONE_SHOT)
	await _dice_overlay_instance._show()
	if game_over:
		return
	var n: int = _dice_overlay_instance.ultimo_resultado
	dice_label.text = "La Maquina obtuvo un %d" % n

func _on_ficha1_reached_end() -> void:
	_declare_winner(0)

func _on_ficha2_reached_end() -> void:
	_declare_winner(1)

func _declare_winner(player_index: int) -> void:
	if game_over:
		return
	game_over = true
	AudioManager.stop_music()
	btn_throw.disabled = true

	var message: String
	if game_mode == 1:
		AudioManager.play_sfx(victory_sound)
		message = "Gano el Jugador %d!" % (player_index + 1)
	elif player_index == 0:
		AudioManager.play_sfx(victory_sound)
		message = "Gano el Jugador!"
	else:
		AudioManager.play_sfx(game_over_sound)
		message = "Gano la Maquina!"

	dice_label.text = message
	if turn_label:
		turn_label.text = message
		turn_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	if GameManager.message_label:
		GameManager.message_label.visible = true
		GameManager.message_label.text    = message
	print("Main:", message)

func _update_turn_label(player_index: int) -> void:
	if turn_label == null:
		return
	var _name: String
	if game_mode == 1:
		_name = "Turno del Jugador %d" % (player_index + 1)
	elif player_index == 0:
		_name = "Turno del Jugador"
	else:
		_name = "Turno de la Maquina"
	turn_label.text = _name
	turn_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))

func _update_position_label() -> void:
	if position_label == null:
		return
	var pos1: int = piece.current_index
	var pos2: int = piece2.current_index if piece2 != null else 0
	if game_mode == 1:
		position_label.text = "J1: casilla %d     J2: casilla %d" % [pos1, pos2]
	else:
		position_label.text = "Jugador: casilla %d     CPU: casilla %d" % [pos1, pos2]
