extends Node3D

@export var camera_smooth_speed: float = 5.0
@export var turn_camera_delay: float = 0.7

# =========================================================
# NODOS DE LA ESCENA (existentes)
# =========================================================
@onready var mapa                               = $Mapa
@onready var ficha                              = $Mapa/Ficha
@onready var camera_rig: Node3D                 = $Camera_rig
@onready var camera: Camera3D                   = $Camera_rig/Camera3D
@onready var marker_iso: Marker3D               = $Camera_rig/Marker_isometrica
@onready var marker_tercera: Marker3D           = $Camera_rig/Marker_tercera
@onready var dado_label: Label                  = $UI/DadoLabel
@onready var btn_salir: Button                  = $UI/Salir
@onready var btn_tirar: Button                  = $UI/BtnTirar
@onready var btn_tirar_3: Button                = $UI/Tirar_3
@onready var btn_reiniciar: Button              = $UI/Reiniciar
@onready var btn_tercera: Button                = $UI/Tercera_persona
@onready var btn_isometrica: Button             = $UI/Isometrica
@onready var dice_sound: AudioStreamPlayer      = $UI/DiceSound
@onready var move_sound: AudioStreamPlayer      = $UI/MoveSound
@onready var avanzar_casilla: AudioStreamPlayer = $AvanzarCasillas
@onready var juego_perdido: AudioStreamPlayer   = $JuegoPerdido
@onready var lobby1: AudioStreamPlayer          = $Lobby1
@onready var lobby2: AudioStreamPlayer          = $Lobby2
@onready var musica_victoria: AudioStreamPlayer = $MusicaVictoria
@onready var retroceder_casillas: AudioStreamPlayer = $Retrocedercasillas
@onready var saltar: AudioStreamPlayer          = $Saltar
@onready var tablero: AudioStreamPlayer         = $Tablero
@onready var tiempo: AudioStreamPlayer          = $Tiempo

const DICE_OVERLAY_SCENE = preload("res://scenes/UX/DiceOverlay.tscn")
var _dice_overlay_instance = null

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

# =========================================================
# SEGUNDA FICHA
# =========================================================
var ficha2 = null
const FICHA_SCENE = preload("res://scenes/tablero/ficha.tscn")

# =========================================================
# UI DINAMICA
# =========================================================
var turno_label: Label    = null
var posicion_label: Label = null

# =========================================================
# READY
# =========================================================
func _ready() -> void:
	_waypoints = mapa.get_waypoints()
	_waypoint_rotations = mapa.get_waypoint_rotations()
	_waypoint_bases = mapa.get_waypoint_bases()
	print("Main: waypoints =", _waypoints.size(), "rotaciones =", _waypoint_rotations.size(), "bases =", _waypoint_bases.size())
	camera.make_current()

	camera.position = marker_iso.position
	camera.rotation = marker_iso.rotation

	btn_tirar.pressed.connect(_on_btn_tirar)
	btn_tirar.disabled = true
	btn_salir.pressed.connect(_on_salir)
	btn_tirar_3.pressed.connect(_on_tirar_3)
	btn_reiniciar.pressed.connect(_on_reiniciar)
	GameManager.turn_changed.connect(_on_turn_changed)
	btn_tercera.pressed.connect(cambiar_camara.bind(marker_tercera))
	btn_isometrica.pressed.connect(cambiar_camara.bind(marker_iso))

	_dice_overlay_instance = DICE_OVERLAY_SCENE.instantiate()
	_dice_overlay_instance.visible = false
	add_child(_dice_overlay_instance)
	_dice_overlay_instance.overlay_done.connect(_on_dice_rolled)

	_crear_ui_extra()
	_iniciar_juego()
	lobby2.play()        # ← música de fondo inicia aquí
	tablero.play()       # ← sonido ambiente del tablero

func cambiar_camara(marker: Marker3D) -> void:
	var active: Node3D
	if GameManager.current_player < GameManager.tokens.size():
		active = GameManager.tokens[GameManager.current_player]
	else:
		active = ficha

	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(camera, "transform", marker.transform, 0.6)
	tween.tween_property(camera_rig, "rotation:y", deg_to_rad(active.rotation_degrees.y), 0.6)

# =========================================================
# CREAR TurnoLabel Y PosicionLabel
# =========================================================
func _crear_ui_extra() -> void:
	turno_label = Label.new()
	turno_label.name = "TurnoLabel"
	turno_label.set_position(Vector2(660, 10))
	turno_label.custom_minimum_size = Vector2(600, 50)
	turno_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turno_label.add_theme_font_size_override("font_size", 26)
	turno_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
	$UI.add_child(turno_label)

	posicion_label = Label.new()
	posicion_label.name = "PosicionLabel"
	posicion_label.set_position(Vector2(660, 62))
	posicion_label.custom_minimum_size = Vector2(600, 40)
	posicion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	posicion_label.add_theme_font_size_override("font_size", 18)
	posicion_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	$UI.add_child(posicion_label)

# =========================================================
# INICIAR JUEGO
# =========================================================
func _iniciar_juego() -> void:
	var mode = GameManager.game_mode
	game_mode = GameManager.game_mode
	GameManager.tokens.clear()
	GameManager.current_player = 0

	if mode == 1:
		GameManager.player_names = ["Jugador 1", "Jugador 2"]
	else:
		GameManager.player_names = ["Jugador", "Maquina"]

	ficha.setup(_waypoints, _waypoint_rotations, _waypoint_bases)
	GameManager.register_token(ficha)
	ficha.reached_end.connect(_on_ficha1_reached_end)
	ficha.stepped_on.connect(_on_ficha_stepped)

	ficha2 = FICHA_SCENE.instantiate()
	ficha2.name = "Ficha2"
	ficha2.lane_offset = Vector3(3.5, 0.0, 0.0)
	mapa.add_child(ficha2)
	ficha2.setup(_waypoints, _waypoint_rotations, _waypoint_bases)
	GameManager.register_token(ficha2)
	ficha2.reached_end.connect(_on_ficha2_reached_end)
	ficha2.stepped_on.connect(_on_ficha_stepped)

	_agregar_etiqueta(ficha, "J1")
	if mode == 2:
		_agregar_etiqueta(ficha2, "CPU")
	else:
		_agregar_etiqueta(ficha2, "J2")

	btn_tirar.disabled = false
	dado_label.text = "Tira el dado"
	_actualizar_turno(0)
	_actualizar_posicion()
	print("Main: juego iniciado modo", mode)

# =========================================================
# ETIQUETA 3D ENCIMA DE LA FICHA
# =========================================================
func _agregar_etiqueta(f: Node3D, texto: String) -> void:
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
		active = ficha

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
	move_sound.play()
	_actualizar_posicion()

	# Sonido según la acción de carta roja
	var tipo = GameManager.last_action_type
	if tipo == "advance":
		avanzar_casilla.play()    # ← carta roja: avanzar casillas
	elif tipo == "go_back":
		retroceder_casillas.play() # ← carta roja: retroceder casillas
	elif tipo == "go_to_space":
		saltar.play()              # ← carta roja: ir a casilla específica

# =========================================================
# BOTON SALIR
# =========================================================
func _on_salir() -> void:
	get_tree().change_scene_to_file("res://scenes/UX/menuPrincipal.tscn")

# =========================================================
# BOTON TIRAR 3 (DEBUG)
# =========================================================
func _on_tirar_3() -> void:
	if game_over:
		return
	if game_mode == 2 and GameManager.current_player == 1:
		return
	dice_sound.play()
	dado_label.text = "Tiraste un 3"
	await GameManager.on_dice_rolled(3)

# =========================================================
# REINICIAR
# =========================================================
func _on_reiniciar() -> void:
	GameManager.tokens.clear()
	GameManager.current_player   = 0
	GameManager.is_player_moving = false
	GameManager.minijuego_activo = false
	GameManager.skip_player_index = -1
	GameManager.last_action_type = ""
	get_tree().reload_current_scene()

# =========================================================
# DADO FISICO
# =========================================================
func _on_btn_tirar() -> void:
	if game_over or _dice_overlay_instance == null:
		return
	btn_tirar.disabled = true
	await _dice_overlay_instance.mostrar()

func _on_dice_rolled(n: int) -> void:
	if game_over:
		return
	dice_sound.play()
	await get_tree().create_timer(0.15).timeout
	dado_label.text = "Tiraste un %d" % n
	await GameManager.on_dice_rolled(n)

# =========================================================
# CAMBIO DE TURNO
# =========================================================
func _on_turn_changed(player_index: int) -> void:
	if game_over:
		return
	_camera_delay_timer = turn_camera_delay
	_camera_delay_active = true
	_actualizar_turno(player_index)
	btn_tirar.disabled = true

	print("Main: turn_changed recibido =", player_index)

	# Turno penalizado: saltar sin habilitar botón ni iniciar CPU
	if GameManager.skip_player_index == player_index:
		GameManager.skip_player_index = -1
		_apply_skip(player_index)
		return

	var puede_tirar_humano: bool = (game_mode == 1) or (game_mode == 2 and player_index == 0)
	print("Main: habilitar botón =", puede_tirar_humano)

	if game_mode == 2 and player_index == 1:
		dado_label.text = "Turno de la Maquina..."
		print("Main: ejecutando turno CPU")
		_machine_turn()
	else:
		btn_tirar.disabled = false
		dado_label.text = "Tira el dado"

func _apply_skip(player_index: int) -> void:
	var nombre: String
	if game_mode == 1:
		nombre = "Jugador %d" % (player_index + 1)
	elif player_index == 0:
		nombre = "el Jugador"
	else:
		nombre = "la Maquina"

	dado_label.text = "%s pierde este turno" % nombre
	if GameManager.mensaje_label:
		GameManager.mensaje_label.visible = true
		GameManager.mensaje_label.text = "¡%s pierde este turno!" % nombre

	await get_tree().create_timer(2.0).timeout

	if GameManager.mensaje_label:
		GameManager.mensaje_label.visible = false

	if not game_over:
		GameManager._next_turn()

# =========================================================
# IA — TURNO AUTOMATICO
# =========================================================
func _machine_turn() -> void:
	await get_tree().create_timer(1.2).timeout

	if game_over:
		return

	dado_label.text = "La Maquina esta tirando el dado..."

	await _dice_overlay_instance.mostrar()

	if game_over:
		return

	var n: int = _dice_overlay_instance.ultimo_resultado

	dice_sound.play()
	dado_label.text = "La Maquina obtuvo un %d" % n

# =========================================================
# META — FICHA 1
# =========================================================
func _on_ficha1_reached_end() -> void:
	_declarar_ganador(0)

# META — FICHA 2
func _on_ficha2_reached_end() -> void:
	_declarar_ganador(1)

# =========================================================
# DECLARAR GANADOR
# =========================================================
func _declarar_ganador(player_index: int) -> void:
	if game_over:
		return
	game_over = true
	lobby2.stop()         # ← para la música de fondo
	tablero.stop()        # ← para el sonido ambiente
	btn_tirar.disabled = true

	var mensaje: String
	if game_mode == 1:
		musica_victoria.play()                              # ← ambos jugadores humanos: victoria
		mensaje = "Gano el Jugador %d!" % (player_index + 1)
	elif player_index == 0:
		musica_victoria.play()                              # ← jugador humano gana vs CPU
		mensaje = "Gano el Jugador!"
	else:
		juego_perdido.play()                                # ← CPU gana, jugador pierde
		mensaje = "Gano la Maquina!"

	dado_label.text = mensaje
	if turno_label:
		turno_label.text = mensaje
		turno_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	if GameManager.mensaje_label:
		GameManager.mensaje_label.visible = true
		GameManager.mensaje_label.text    = mensaje
	print("Main:", mensaje)

# =========================================================
# HELPERS UI — sin match, solo if/elif
# =========================================================
func _actualizar_turno(player_index: int) -> void:
	if turno_label == null:
		return
	var nombre: String
	if game_mode == 1:
		nombre = "Turno del Jugador %d" % (player_index + 1)
	elif player_index == 0:
		nombre = "Turno del Jugador"
	else:
		nombre = "Turno de la Maquina"
	turno_label.text = nombre
	turno_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))

func _actualizar_posicion() -> void:
	if posicion_label == null:
		return
	var pos1: int = ficha.current_index
	var pos2: int = ficha2.current_index if ficha2 != null else 0
	if game_mode == 1:
		posicion_label.text = "J1: casilla %d     J2: casilla %d" % [pos1, pos2]
	else:
		posicion_label.text = "Jugador: casilla %d     CPU: casilla %d" % [pos1, pos2]

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
