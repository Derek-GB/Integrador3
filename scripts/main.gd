extends Node3D

@export var camera_smooth_speed: float = 5.0
@export var turn_camera_delay: float = 0.7

# =========================================================
# NODOS DE LA ESCENA (existentes)
# =========================================================
@onready var map                                   = $Mapa
@onready var piece                                 = $Mapa/Ficha
@onready var camera_rig: Node3D                    = $Camera_rig
@onready var camera: Camera3D                      = $Camera_rig/Camera3D
@onready var marker_iso: Marker3D                  = $Camera_rig/Marker_isometrica
@onready var marker_third: Marker3D                = $Camera_rig/Marker_tercera
@onready var dice_label: Label                     = $UI/DadoLabel
@onready var btn_pause: Button                     = $UI/Salir
@onready var btn_throw: Button                     = $UI/BtnTirar
@onready var btn_throw_3: Button                   = $UI/Tirar_3
@onready var btn_restart: Button                   = $UI/Reiniciar
@onready var btn_third: Button                     = $UI/Tercera_persona
@onready var btn_iso: Button                       = $UI/Isometrica
@onready var dice_sound: AudioStreamPlayer         = $UI/DiceSound
@onready var move_sound_old: AudioStreamPlayer     = $UI/MoveSound
@onready var move_forward_sound: AudioStreamPlayer = $AvanzarCasillas
@onready var game_over_sound: AudioStreamPlayer    = $JuegoPerdido
@onready var lobby1: AudioStreamPlayer             = $Lobby1
@onready var lobby2: AudioStreamPlayer             = $Lobby2
@onready var victory_sound: AudioStreamPlayer      = $MusicaVictoria
@onready var move_back_sound: AudioStreamPlayer    = $Retrocedercasillas
@onready var move_sound: AudioStreamPlayer         = $Saltar
@onready var board_sound: AudioStreamPlayer        = $Tablero
@onready var time_over_sound: AudioStreamPlayer    = $Tiempo
@onready var pause_menu                            = $UI/PauseMenu

const DICE_OVERLAY_SCENE = preload("res://scenes/UX/DiceOverlay.tscn")
const STOP_MENU = preload("res://scenes/UX/PauseMenu.tscn")

# =========================================================
# ESTADO DEL JUEGO
# =========================================================
var game_over: bool = false
var game_mode: int  = 1
var _waypoints: Array[Vector3] = []
var _waypoint_rotations: Array[float] = []
var _waypoint_bases: Array[Basis] = []
var _camera_delay_timer: float = 0.0
var _camera_delay_active: bool = false
var _dice_overlay_instance: Node = null

# =========================================================
# SEGUNDA FICHA
# =========================================================
var piece2 = null
const PIECE_SCENE = preload("res://scenes/tablero/ficha.tscn")

# =========================================================
# UI DINAMICA
# =========================================================
var turn_label: Label    = null
var position_label: Label = null

# =========================================================
# READY
# =========================================================
func _ready() -> void:
	_waypoints = map.get_waypoints()
	_waypoint_rotations = map.get_waypoint_rotations()
	_waypoint_bases = map.get_waypoint_bases()
	print("Main: waypoints =", _waypoints.size(), "rotaciones =", _waypoint_rotations.size(), "bases =", _waypoint_bases.size())
	camera.make_current()

	camera.position = marker_iso.position
	camera.rotation = marker_iso.rotation

	btn_throw.pressed.connect(_on_btn_throw)
	btn_throw.disabled = true
	btn_pause.pressed.connect(_on_pause)
	btn_throw_3.pressed.connect(_on_throw_3)
	btn_restart.pressed.connect(_on_restart)
	GameManager.turn_changed.connect(_on_turn_changed)
	btn_third.pressed.connect(switch_camera.bind(marker_third))
	btn_iso.pressed.connect(switch_camera.bind(marker_iso))

	GameManager.play_sound.connect(_on_play_sound)

	_dice_overlay_instance = DICE_OVERLAY_SCENE.instantiate()
	_dice_overlay_instance.visible = false
	add_child(_dice_overlay_instance)
	_dice_overlay_instance.overlay_done.connect(_on_dice_rolled)

	lobby2.play()        # ← música de fondo inicia aquí
	board_sound.play()       # ← sonido ambiente del board_sound

	_init_ui_extra()
	_start_game()
	

func switch_camera(marker: Marker3D) -> void:
	var active: Node3D
	if GameManager.current_player < GameManager.tokens.size():
		active = GameManager.tokens[GameManager.current_player]
	else:
		active = piece

	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(camera, "transform", marker.transform, 0.6)
	tween.tween_property(camera_rig, "rotation:y", deg_to_rad(active.rotation_degrees.y), 0.6)

# =========================================================
# CREAR TurnoLabel Y PosicionLabel
# =========================================================
func _init_ui_extra() -> void:
	turn_label = Label.new()
	turn_label.name = "TurnoLabel"
	turn_label.set_position(Vector2(660, 10))
	turn_label.custom_minimum_size = Vector2(600, 50)
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_label.add_theme_font_size_override("font_size", 26)
	turn_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
	$UI.add_child(turn_label)

	position_label = Label.new()
	position_label.name = "PosicionLabel"
	position_label.set_position(Vector2(660, 62))
	position_label.custom_minimum_size = Vector2(600, 40)
	position_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	position_label.add_theme_font_size_override("font_size", 18)
	position_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	$UI.add_child(position_label)

# =========================================================
# INICIAR JUEGO
# =========================================================
func _start_game() -> void:
	var mode = GameManager.game_mode
	game_mode = GameManager.game_mode
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

	piece2 = PIECE_SCENE.instantiate()
	piece2.name = "Ficha2"
	piece2.lane_offset = Vector3(3.5, 0.0, 0.0)
	map.add_child(piece2)
	piece2.setup(_waypoints, _waypoint_rotations, _waypoint_bases)
	GameManager.register_token(piece2)
	piece2.reached_end.connect(_on_ficha2_reached_end)
	piece2.stepped_on.connect(_on_ficha_stepped)

	_add_tag(piece, "J1")
	if mode == 2:
		_add_tag(piece2, "CPU")
	else:
		_add_tag(piece2, "J2")

	btn_throw.disabled = false
	dice_label.text = "Tira el dado"
	_update_turn_label(0)
	_update_position_label()
	print("Main: juego iniciado modo", mode)

# =========================================================
# ETIQUETA 3D ENCIMA DE LA FICHA
# =========================================================
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
# CAMARA SIGUE AL TOKEN ACTIVO
# =========================================================
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
	camera_rig.global_position = camera_rig.global_position.lerp(
		active.global_position,
		follow_weight
	)

	var target_yaw: float = deg_to_rad(active.rotation_degrees.y)
	camera_rig.rotation.y = lerp_angle(
		camera_rig.rotation.y,
		target_yaw,
		follow_weight
	)

	# Asegura que el giro use siempre el camino angular más corto.
	camera_rig.rotation.y = fmod(camera_rig.rotation.y + TAU, TAU)
	if camera_rig.rotation.y < 0.0:
		camera_rig.rotation.y += TAU

# =========================================================
# SONIDO Y POSICION AL PISAR CASILLA
# =========================================================
func _on_ficha_stepped(_index: int) -> void:
	#move_sound_old.play()
	move_sound.play()
	_update_position_label()

	# Sonido según la acción de carta roja
	var type = GameManager.last_action_type
	if type == "advance":
		move_forward_sound.play()    # ← carta roja: avanzar casillas
	elif type == "go_back":
		move_back_sound.play() # ← carta roja: retroceder casillas
	elif type == "go_to_space":
		move_sound.play()              # ← carta roja: ir a casilla específica

# =========================================================
# BOTON SALIR
# =========================================================
func _on_pause() -> void:
	pause_menu.open_window()
	#get_tree().change_scene_to_packed(STOP_MENU)

# =========================================================
# BOTON TIRAR 3 (DEBUG)
# =========================================================
func _on_throw_3() -> void:
	if game_over:
		return
	if game_mode == 2 and GameManager.current_player == 1:
		return
	dice_sound.play()
	dice_label.text = "Tiraste un 3"
	await GameManager.on_dice_rolled(3)

# =========================================================
# REINICIAR
# =========================================================
func _on_restart() -> void:
	GameManager.tokens.clear()
	GameManager.current_player   = 0
	GameManager.is_player_moving = false
	GameManager.minigame_active = false
	GameManager.skip_player_index = -1
	GameManager.last_action_type = ""
	get_tree().reload_current_scene()

# =========================================================
# DADO FISICO
# =========================================================
func _on_btn_throw() -> void:
	if game_over or _dice_overlay_instance == null:
		return
	btn_throw.disabled = true
	get_tree().create_timer(0.5).timeout.connect(dice_sound.play, CONNECT_ONE_SHOT)
	await _dice_overlay_instance.mostrar()

func _on_dice_rolled(n: int) -> void:
	if game_over:
		return
	#dice_sound.play()
	get_tree().create_timer(0.3).timeout.connect(move_forward_sound.play, CONNECT_ONE_SHOT)
	await get_tree().create_timer(0.15).timeout
	dice_label.text = "Tiraste un %d" % n
	await GameManager.on_dice_rolled(n)

# =========================================================
# CAMBIO DE TURNO
# =========================================================
func _on_turn_changed(player_index: int) -> void:
	if game_over:
		return
	_camera_delay_timer = turn_camera_delay
	_camera_delay_active = true
	_update_turn_label(player_index)
	btn_throw.disabled = true

	print("Main: turn_changed recibido =", player_index)

	# Turno penalizado: move_sound sin habilitar botón ni iniciar CPU
	if GameManager.skip_player_index == player_index:
		GameManager.skip_player_index = -1
		_apply_skip(player_index)
		return

	var can_throw_human: bool = (game_mode == 1) or (game_mode == 2 and player_index == 0)
	print("Main: habilitar botón =", can_throw_human)

	if game_mode == 2 and player_index == 1:
		dice_label.text = "Turno de la Maquina..."
		print("Main: ejecutando turno CPU")
		_machine_turn()
	else:
		btn_throw.disabled = false
		dice_label.text = "Tira el dado"

func _on_play_sound(sound_name: String) -> void:
	if sound_name == "avanzar":
		move_forward_sound.play()
	elif sound_name == "retroceder":
		move_back_sound.play()

func _apply_skip(player_index: int) -> void:
	var name: String
	if game_mode == 1:
		name = "Jugador %d" % (player_index + 1)
	elif player_index == 0:
		name = "el Jugador"
	else:
		name = "la Maquina"

	dice_label.text = "%s pierde este turno" % name
	if GameManager.message_label:
		GameManager.message_label.visible = true
		GameManager.message_label.text = "¡%s pierde este turno!" % name

	await get_tree().create_timer(2.0).timeout

	if GameManager.message_label:
		GameManager.message_label.visible = false

	if not game_over:
		GameManager._next_turn()

# =========================================================
# IA — TURNO AUTOMATICO
# =========================================================
func _machine_turn() -> void:
	await get_tree().create_timer(1.2).timeout

	if game_over:
		return

	dice_label.text = "La Maquina esta tirando el dado..."

	get_tree().create_timer(0.5).timeout.connect(dice_sound.play, CONNECT_ONE_SHOT)
	await _dice_overlay_instance.mostrar()

	if game_over:
		return

	var n: int = _dice_overlay_instance.ultimo_resultado

	dice_label.text = "La Maquina obtuvo un %d" % n

# =========================================================
# META — FICHA 1
# =========================================================
func _on_ficha1_reached_end() -> void:
	_declare_winner(0)

# META — FICHA 2
func _on_ficha2_reached_end() -> void:
	_declare_winner(1)

# =========================================================
# DECLARAR GANADOR
# =========================================================
func _declare_winner(player_index: int) -> void:
	if game_over:
		return
	game_over = true
	lobby2.stop()         # ← para la música de fondo
	board_sound.stop()        # ← para el sonido ambiente
	btn_throw.disabled = true

	var message: String
	if game_mode == 1:
		victory_sound.play()                              # ← ambos jugadores humanos: victoria
		message = "Gano el Jugador %d!" % (player_index + 1)
	elif player_index == 0:
		victory_sound.play()                              # ← jugador humano gana vs CPU
		message = "Gano el Jugador!"
	else:
		game_over_sound.play()                                # ← CPU gana, jugador pierde
		message = "Gano la Maquina!"

	dice_label.text = message
	if turn_label:
		turn_label.text = message
		turn_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	if GameManager.message_label:
		GameManager.message_label.visible = true
		GameManager.message_label.text    = message
	print("Main:", message)

# =========================================================
# HELPERS UI — sin match, solo if/elif
# =========================================================
func _update_turn_label(player_index: int) -> void:
	if turn_label == null:
		return
	var name: String
	if game_mode == 1:
		name = "Turno del Jugador %d" % (player_index + 1)
	elif player_index == 0:
		name = "Turno del Jugador"
	else:
		name = "Turno de la Maquina"
	turn_label.text = name
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

#func _on_dice_roll_started() -> void:
	#_dice_overlay.visible = true
	#var tween := create_tween().set_parallel(true)
	#tween.tween_property(_dimmer, "color:a", 0.65, 0.3)
	#tween.tween_property(_dice_viewport_rect, "modulate:a", 1.0, 0.3)
#
#func _on_dice_roll_finished(_n: int) -> void:
	#var tween := create_tween().set_parallel(true)
	#tween.tween_property(_dimmer, "color:a", 0.0, 0.4)
	#tween.tween_property(_dice_viewport_rect, "modulate:a", 0.0, 0.4)
	#await tween.finished
	#_dice_overlay.visible = false
