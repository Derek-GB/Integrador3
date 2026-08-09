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
@export var earthquake_sound: AudioStream
# Separación lateral entre fichas cuando comparten casilla
@export var lane_split_offset: float = 1.75
@export var earthquake_duration: float = 3.0
@export var earthquake_strength: float = 1.0

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
@onready var info_panel                     = $UI/InfoPanel
@onready var dice_label: Label              = $UI/InfoPanel/DiceLabel
@onready var turn_label: Label              = $UI/InfoPanel/TurnLabel
@onready var position_label: Label          = $UI/InfoPanel/PositionLabel
@onready var position_label2: Label         = $UI/InfoPanel/PositionLabel2
@onready var time_label: Label              = $UI/InfoPanel/Time
@onready var btn_pause: Button              = $UI/Pause
@onready var btn_throw: Button              = $UI/BtnThrow
@onready var btn_throw_3: Button            = $UI/Throw_3
@onready var qa_input: LineEdit             = $UI/QA_Input
@onready var btn_restart: Button            = $UI/Restart
@onready var btn_third: Button              = $UI/Third_person
@onready var btn_iso: Button                = $UI/Iso
@onready var btn_bind_cam: Button           = $UI/BindCam
@onready var pause_menu                     = $UI/PauseMenu
@onready var btn_minigame: Button           = $UI/Test_MG
@onready var game_complet_panel             = $UI/GameCompletionPanel
@onready var turn_banner_label: RichTextLabel = $UI/TurnBannerLabel

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
var _alt_waypoints: Array[Vector3]              = []
var _alt_waypoint_rotations: Array[float]       = []
var _alt_waypoint_bases: Array[Basis]           = []
var _special_waypoints: Dictionary              = {}
var _special_waypoint_rotations: Dictionary     = {}
var _special_waypoint_bases: Dictionary         = {}
var _dice_overlay_instance: Node = null
var _turn_banner_tween: Tween   = null
var _camera_tween: Tween        = null
var _last_turn_player_index: int = -1
var _is_first_turn_p1: bool      = true
var piece2 = null
var time: int = 0

var QA_throw_value: int = 74

# =========================================================
# CICLO DE VIDA
# =========================================================
func _ready() -> void:
	_waypoints                  = map.get_waypoints()
	_waypoint_rotations         = map.get_waypoint_rotations()
	_waypoint_bases             = map.get_waypoint_bases()
	_alt_waypoints              = map.get_alt_waypoints()
	_alt_waypoint_rotations     = map.get_alt_rotations()
	_alt_waypoint_bases         = map.get_alt_bases()
	_special_waypoints          = map.get_special_waypoints()
	_special_waypoint_rotations = map.get_special_rotations()
	_special_waypoint_bases     = map.get_special_bases()
	print("Main: waypoints =", _waypoints.size(), " rotaciones =", _waypoint_rotations.size(), " bases =", _waypoint_bases.size())

	camera.make_current()
	camera_free_body.transform = default_cam_position.transform

	btn_throw.pressed.connect(_on_btn_throw)
	btn_throw.disabled = true
	btn_pause.pressed.connect(_on_pause)
	btn_throw_3.pressed.connect(_on_throw_3)
	if qa_input:
		qa_input.text = str(QA_throw_value)
		qa_input.text_changed.connect(_on_qa_input_text_changed)
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
	Events.earthquake_triggered.connect(_on_earthquake_triggered)
	Events.player_movement_started.connect(_on_player_movement_started)
	Events.player_movement_ended.connect(_on_player_movement_ended)

	_dice_overlay_instance = DICE_OVERLAY_SCENE.instantiate()
	_dice_overlay_instance.visible = false
	add_child(_dice_overlay_instance)
	_dice_overlay_instance.overlay_done.connect(_on_dice_rolled)

	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	AudioManager.play_music(board_sound)
	GameManager.instantiate_message_lbl()
	_start_game()
	GlobalStopwatch.reset()
	GlobalStopwatch.start()

func _process(delta: float) -> void:
	if GameManager.tokens.is_empty():
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
	
	time = GlobalStopwatch.elapsed_time
	time_label.text = time_format(time)

# =========================================================
# MÉTODOS PÚBLICOS
# =========================================================
func switch_camera(marker: Marker3D, free_move: bool = true) -> void:
	if _camera_tween and _camera_tween.is_running():
		_camera_tween.kill()

	camera_free_body.can_free_move = false
	_camera_tween = create_tween()
	_camera_tween.tween_property(camera_free_body, "transform", marker.transform, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_camera_tween.tween_callback(_on_camera_switch_completed.bind(free_move))
	await _camera_tween.finished

func _on_camera_switch_completed(free_move: bool) -> void:
	if camera_rig == null or camera_free_body == null:
		return
	camera_rig.rotation.y = fmod(camera_rig.rotation.y + TAU, TAU)
	if camera_rig.rotation.y < 0.0:
		camera_rig.rotation.y += TAU
	if not GameManager.is_player_moving:
		camera_free_body.can_free_move = free_move
	else:
		camera_free_body.can_free_move = false

func _on_player_movement_started() -> void:
	switch_camera(default_cam_position, false)

func _on_player_movement_ended() -> void:
	camera_free_body.can_free_move = true


# =========================================================
# MÉTODOS PRIVADOS
# =========================================================
func _start_game() -> void:
	var mode: int = GameManager.game_mode
	game_mode = mode
	GameManager.tokens.clear()
	GameManager.current_player = 0

	if mode == 1:
		GameManager.player_names = ["Jugador 1", "Jugador 2"]
	else:
		GameManager.player_names = ["Jugador", "Maquina"]

	piece.setup(_waypoints, _waypoint_rotations, _waypoint_bases,
		_special_waypoints, _special_waypoint_rotations, _special_waypoint_bases)
	piece.setup_alt_path(_alt_waypoints, _alt_waypoint_rotations, _alt_waypoint_bases)
	GameManager.register_token(piece)
	piece.reached_end.connect(_on_ficha1_reached_end)
	piece.stepped_on.connect(_on_ficha_stepped)
	piece.lane_side = -1.0
	piece.lane_split_offset = lane_split_offset

	piece2 = PIECE_SCENE.instantiate()
	piece2.name = "Ficha2"
	map.add_child(piece2)
	piece2.setup(_waypoints, _waypoint_rotations, _waypoint_bases,
		_special_waypoints, _special_waypoint_rotations, _special_waypoint_bases)
	piece2.setup_alt_path(_alt_waypoints, _alt_waypoint_rotations, _alt_waypoint_bases)
	GameManager.register_token(piece2)
	piece2.reached_end.connect(_on_ficha2_reached_end)
	piece2.stepped_on.connect(_on_ficha_stepped)
	piece2.lane_side = 1.0
	piece2.lane_split_offset = lane_split_offset

	# Ambas fichas arrancan en la misma casilla (Inicio), así que se separan
	# de una vez, sin animación, antes de que el jugador vea el tablero.
	_update_lane_offsets(false)

	_add_tag(piece, "Jugador 1", Color(1.0, 0.92, 0.3))
	if mode == 2:
		_add_tag(piece2, "Contrincante", Color(0.35, 0.85, 1.0))
	else:
		_add_tag(piece2, "Jugador 2", Color(0.35, 0.85, 1.0))

	btn_throw.disabled = false
	dice_label.text = "Tira el dado"
	_update_turn_label(0)
	_update_position_label()
	_last_turn_player_index = 0
	for i in range(1,7):
		Events.visible_pointer.emit(i,true)
	print("Main: juego iniciado modo", mode)

func _create_borderless_banner_style(bg_color: Color) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	var grad_tex := GradientTexture2D.new()
	var grad := Gradient.new()

	grad.colors = PackedColorArray([
		Color(bg_color.r, bg_color.g, bg_color.b, 0.0),
		Color(bg_color.r, bg_color.g, bg_color.b, bg_color.a),
		Color(bg_color.r, bg_color.g, bg_color.b, bg_color.a),
		Color(bg_color.r, bg_color.g, bg_color.b, 0.0)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.18, 0.82, 1.0])

	grad_tex.gradient = grad
	grad_tex.fill = GradientTexture2D.FILL_LINEAR
	grad_tex.fill_from = Vector2(0.0, 0.5)
	grad_tex.fill_to = Vector2(1.0, 0.5)
	grad_tex.width = 600
	grad_tex.height = 90

	style.texture = grad_tex
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style

func _show_turn_banner(text_to_show: String, message_type: String = "new_turn", fade_duration: float = 1.5) -> void:
	if turn_banner_label == null or game_over or not is_inside_tree() or get_tree() == null:
		return

	if _turn_banner_tween and _turn_banner_tween.is_running():
		_turn_banner_tween.kill()

	var bg_color: Color
	match message_type:
		"new_turn":
			bg_color = Color(0.16, 0.10, 0.06, 0.88)
		"repeat":
			bg_color = Color(0.26, 0.14, 0.03, 0.90)
		"skip":
			bg_color = Color(0.24, 0.04, 0.06, 0.92)
		_:
			bg_color = Color(0.16, 0.10, 0.06, 0.88)

	turn_banner_label.add_theme_stylebox_override("normal", _create_borderless_banner_style(bg_color))
	turn_banner_label.text = text_to_show
	turn_banner_label.visible = true
	turn_banner_label.modulate.a = 1.0
	turn_banner_label.scale = Vector2(1.15, 1.15)

	_turn_banner_tween = create_tween().set_parallel(true)
	_turn_banner_tween.tween_property(turn_banner_label, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_turn_banner_tween.tween_property(turn_banner_label, "modulate:a", 0.0, fade_duration).set_ease(Tween.EASE_IN)

	_turn_banner_tween.chain().tween_callback(func():
		if is_instance_valid(turn_banner_label):
			turn_banner_label.visible = false
	)
	await _turn_banner_tween.finished

func _add_tag(f: Node3D, texto: String, text_color: Color = Color(1.0, 0.95, 0.4)) -> void:
	if f == null:
		return
	var lbl := Label3D.new()
	lbl.text = texto
	lbl.font = preload("res://fonts/Montserrat-Bold.ttf")
	lbl.font_size = 120
	lbl.outline_size = 20
	lbl.outline_modulate = Color(0.08, 0.08, 0.12, 1.0)
	lbl.modulate = text_color
	lbl.position = Vector3(0, 8.5, 0)
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
	var type : String = GameManager.last_action_type
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
	if (_index < piece.current_index || _index < piece2.current_index):
		Events.visible_pointer.emit(_index-6, false)
	
	Events.forced_visible_pointer.emit(_index,true)
	Events.forced_visible_pointer.emit(_index-1,_is_space_occupied(_index-1))
	Events.forced_visible_pointer.emit(_index+1,_is_space_occupied(_index+1))

func _is_space_occupied(index:int) -> bool:
	return piece.current_index == index or piece2.current_index == index

func card_index (index: int, vector: Array ) -> bool:
	var value : bool
	for i in vector:
		value = !(i == index)
	return value


func _on_pause() -> void:
	pause_menu.open_window()
	GlobalStopwatch.stop()

func _on_minigame_test() -> void:
	Events.set_minigame.emit(15)

func _on_qa_input_text_changed(new_text: String) -> void:
	var clean_text := ""
	for c in new_text:
		if c >= "0" and c <= "9":
			clean_text += c
	if clean_text != new_text:
		qa_input.text = clean_text
		qa_input.caret_column = clean_text.length()
	
	if clean_text.is_valid_int():
		var val := clean_text.to_int()
		if val > 0:
			QA_throw_value = val

func _on_throw_3() -> void:
	if game_over:
		return
	
	if game_mode == 2 and GameManager.current_player == 1:
		return
	
	AudioManager.play_sfx(dice_sound)
	dice_label.text = "Tiraste un " + str(QA_throw_value)
	await GameManager.on_dice_rolled(QA_throw_value)


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
	_last_turn_player_index       = -1
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
	if game_over or not is_inside_tree() or get_tree() == null:
		return
	_update_turn_label(player_index)
	btn_throw.disabled = true
	print("Main: turn_changed recibido =", player_index)

	var is_repeat_turn: bool = (_last_turn_player_index == player_index)
	_last_turn_player_index = player_index

	var formatted_name: String
	if game_mode == 1:
		if player_index == 0:
			formatted_name = "[color=#ffe042]Jugador 1[/color]"
		else:
			formatted_name = "[color=#59d9ff]Jugador 2[/color]"
	elif player_index == 0:
		formatted_name = "[color=#ffe042]Jugador 1[/color]"
	else:
		formatted_name = "[color=#59d9ff]Contrincante[/color]"

	var is_skipping: bool = (GameManager.skip_player_index == player_index)

	# 1. Iniciar animación de cambio de cámara (duración 0.6s)
	switch_camera(default_cam_position, true)

	# 2. Esperar 0.4s para que la pancarta aparezca antes de que la cámara se asiente del todo
	if not is_inside_tree() or get_tree() == null:
		return
	await get_tree().create_timer(0.4).timeout
	if game_over or not is_inside_tree() or get_tree() == null:
		return

	# 3. Mostrar la pancarta correspondiente con su estilo y colores temáticos
	if is_skipping:
		GameManager.skip_player_index = -1
		var bb_text := "[center]¡%s pierde este turno![/center]" % formatted_name
		await _show_turn_banner(bb_text, "skip", 0.8)
	elif is_repeat_turn:
		var bb_text := "[center][color=#ffb03b]¡Repites turno![/color][/center]"
		await _show_turn_banner(bb_text, "repeat", 0.6)
	else:
		var bb_text := "[center][color=#fffdf0]Turno de: [/color]%s[/center]" % formatted_name
		await _show_turn_banner(bb_text, "new_turn", 0.9)

	if game_over:
		return

	if is_skipping:
		_apply_skip(player_index)
		return

	# 4. Si es la IA (Contrincante), tira el dado SÓLO después de la pancarta
	if game_mode == 2 and player_index == 1:
		dice_label.text = "Turno del Contrincante..."
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
	# Mantiene el minijuego activo mientras el tablero queda pausado
	_set_process_mode_recursive(mg, Node.PROCESS_MODE_ALWAYS)
	Events.notify_pause_for_minigame.emit(true)

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
		_name = "el Jugador 1"
	else:
		_name = "el Contrincante"

	dice_label.text = "%s pierde este turno" % _name
	if is_instance_valid(GameManager.message_label):
		GameManager.message_label.visible = true
		GameManager.message_label.text    = "¡%s pierde este turno!" % _name
		if get_tree() != null:
			get_tree().create_timer(5.5).timeout.connect(
				func():
					if is_instance_valid(GameManager.message_label):
						GameManager.message_label.visible = false
			)

	if not game_over:
		GameManager._next_turn()

func _machine_turn() -> void:
	await get_tree().create_timer(1).timeout
	if game_over:
		return
	dice_label.text = "El Contrincante esta tirando el dado..."
	get_tree().create_timer(0.5).timeout.connect(AudioManager.play_sfx.bind(dice_sound), CONNECT_ONE_SHOT)
	await _dice_overlay_instance._show()
	if game_over:
		return
	var n: int = _dice_overlay_instance.ultimo_resultado
	dice_label.text = "El Contrincante obtuvo un %d" % n

func _on_ficha1_reached_end() -> void:
	_declare_winner(0)

func _on_ficha2_reached_end() -> void:
	_declare_winner(1)

func _declare_winner(player_index: int) -> void:
	if game_over:
		return
	game_over = true
	if is_instance_valid(turn_banner_label):
		turn_banner_label.visible = false
	if _turn_banner_tween and _turn_banner_tween.is_running():
		_turn_banner_tween.kill()
	AudioManager.stop_music()
	btn_throw.disabled = true

	var message: String
	if game_mode == 1:
		AudioManager.play_sfx(victory_sound)
		message = "¡Gano el Jugador %d!" % (player_index + 1)
	elif player_index == 0:
		AudioManager.play_sfx(victory_sound)
		message = "¡Gano el Jugador 1!"
	else:
		AudioManager.play_sfx(game_over_sound)
		message = "¡Gano el Contrincante!"

	dice_label.text = message
	if turn_label:
		turn_label.text = message
		turn_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	if is_instance_valid(GameManager.message_label):
		GameManager.message_label.visible = true
		GameManager.message_label.text    = message
		if get_tree() != null:
			get_tree().create_timer(5.5).timeout.connect(
				func():
					if is_instance_valid(GameManager.message_label):
						GameManager.message_label.visible = false
			)
	visible_components([info_panel, btn_pause, btn_bind_cam,btn_throw, btn_throw_3], false)
	game_complet_panel.text_name_player("¡Jugador %d!" % (player_index + 1))
	game_complet_panel.text_total_time("Tiempo total: " + time_format(time))
	game_complet_panel.visible = true
	GlobalStopwatch.stop()
	print("Main:", message)

func visible_components (array: Array, value: bool) -> void:
	for com in array:
		com.visible = value


func _update_turn_label(player_index: int) -> void:
	if turn_label == null:
		return
	var _name: String
	if game_mode == 1:
		_name = "Turno del Jugador %d" % (player_index + 1)
	elif player_index == 0:
		_name = "Turno del Jugador 1"
	else:
		_name = "Turno del Contrincante"
	turn_label.text = _name
	turn_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))

func _update_position_label() -> void:
	if position_label == null:
		return
	var pos1: int = piece.current_index
	var pos2: int = piece2.current_index if piece2 != null else 0

	position_label.text = "Jugador 1:\ncasilla %d" % pos1

	if position_label2 != null:
		if game_mode == 1:
			position_label2.text = "Jugador 2:\ncasilla %d" % pos2
		else:
			position_label2.text = "Contrincante:\ncasilla %d" % pos2

func _on_earthquake_triggered() -> void:
	AudioManager.play_sfx(earthquake_sound)
	await _shake_camera(earthquake_duration, earthquake_strength)
	await get_tree().create_timer(0.5).timeout
	Events.earthquake_finished.emit()

func _shake_camera(duration: float, strength: float) -> void:
	var original_position: Vector3 = camera.position
	var elapsed: float = 0.0

	while elapsed < duration:
		await get_tree().process_frame
		if not is_inside_tree():
			return
		elapsed += get_process_delta_time()
		var falloff: float = 1.0 - (elapsed / duration)
		camera.position = original_position + Vector3(
			randf_range(-strength, strength) * falloff,
			randf_range(-strength, strength) * falloff,
			0.0
		)
	camera.position = original_position

func time_format(total_seconds: float) -> String:
	var min: int = int(total_seconds) / 60
	var sec: int = int(total_seconds) % 60
	return "%02d:%02d" % [min, sec]
