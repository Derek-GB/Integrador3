extends Node3D

@export var camera_smooth_speed: float = 5.0

# =========================================================
# NODOS DE LA ESCENA (existentes)
# =========================================================
@onready var mapa                               = $Mapa
@onready var ficha                              = $Mapa/Ficha
@onready var camera: Camera3D                   = $Camera3D
@onready var dado                               = $Dado
@onready var dado_label: Label                  = $UI/DadoLabel
@onready var btn_salir: Button                  = $UI/Salir
@onready var btn_tirar: Button                  = $UI/BtnTirar
@onready var btn_tirar_3: Button                = $UI/Tirar_3
@onready var btn_reiniciar: Button              = $UI/Reiniciar
@onready var dice_sound: AudioStreamPlayer      = $UI/DiceSound
@onready var move_sound: AudioStreamPlayer      = $UI/MoveSound

# =========================================================
# ESTADO DEL JUEGO
# =========================================================
var game_over: bool = false
var game_mode: int  = 1
var camera_offset: Vector3 = Vector3.ZERO
var _waypoints: Array[Vector3] = []

# =========================================================
# SEGUNDA FICHA
# =========================================================
var ficha2 = null
const FICHA_SCENE = preload("res://scenes/ficha.tscn")

# =========================================================
# UI DINAMICA
# =========================================================
var turno_label: Label    = null
var posicion_label: Label = null
var _panel_modo: ColorRect = null

# =========================================================
# READY
# =========================================================
func _ready() -> void:
	_waypoints = mapa.get_waypoints()
	print("Main: waypoints =", _waypoints.size())

	dado.setup(camera)
	dado.visible = false
	dado.freeze  = true
	dado.dice_rolled.connect(_on_dice_rolled)

	btn_tirar.pressed.connect(_on_btn_tirar)
	btn_tirar.disabled = true
	btn_salir.pressed.connect(_on_salir)
	btn_tirar_3.pressed.connect(_on_tirar_3)
	btn_reiniciar.pressed.connect(_on_reiniciar)
	GameManager.turn_changed.connect(_on_turn_changed)

	camera_offset = camera.global_position - ficha.global_position

	_crear_ui_extra()
	_crear_panel_modo()

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
# PANEL DE SELECCION DE MODO
# =========================================================
func _crear_panel_modo() -> void:
	_panel_modo = ColorRect.new()
	_panel_modo.name = "PanelModo"
	_panel_modo.color = Color(0.07, 0.04, 0.02, 0.94)
	_panel_modo.set_anchors_preset(Control.PRESET_FULL_RECT)
	$UI.add_child(_panel_modo)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_modo.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(500, 0)
	vbox.add_theme_constant_override("separation", 28)
	center.add_child(vbox)

	var titulo := Label.new()
	titulo.text = "RIESGOLANDIA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 52)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(titulo)

	var sub := Label.new()
	sub.text = "Selecciona el modo de juego"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
	vbox.add_child(sub)

	vbox.add_child(HSeparator.new())

	var btn1 := Button.new()
	btn1.text = "2 Jugadores"
	btn1.custom_minimum_size = Vector2(500, 80)
	btn1.add_theme_font_size_override("font_size", 26)
	btn1.pressed.connect(_on_modo_seleccionado.bind(1))
	vbox.add_child(btn1)

	var btn2 := Button.new()
	btn2.text = "Jugador vs Maquina"
	btn2.custom_minimum_size = Vector2(500, 80)
	btn2.add_theme_font_size_override("font_size", 26)
	btn2.pressed.connect(_on_modo_seleccionado.bind(2))
	vbox.add_child(btn2)

# Llamado por los botones del panel con .bind()
func _on_modo_seleccionado(mode: int) -> void:
	if _panel_modo:
		_panel_modo.queue_free()
		_panel_modo = null
	_iniciar_juego(mode)

# =========================================================
# INICIAR JUEGO
# =========================================================
func _iniciar_juego(mode: int) -> void:
	game_mode = mode
	GameManager.game_mode = mode

	if mode == 1:
		GameManager.player_names = ["Jugador 1", "Jugador 2"]
	else:
		GameManager.player_names = ["Jugador", "Maquina"]

	ficha.setup(_waypoints)
	GameManager.register_token(ficha)
	ficha.reached_end.connect(_on_ficha1_reached_end)
	ficha.stepped_on.connect(_on_ficha_stepped)

	ficha2 = FICHA_SCENE.instantiate()
	ficha2.name = "Ficha2"
	ficha2.lane_offset = Vector3(3.5, 0.0, 0.0)
	mapa.add_child(ficha2)
	ficha2.setup(_waypoints)
	GameManager.register_token(ficha2)
	ficha2.reached_end.connect(_on_ficha2_reached_end)
	ficha2.stepped_on.connect(_on_ficha_stepped)

	_agregar_etiqueta(ficha, "J1")
	if mode == 2:
		_agregar_etiqueta(ficha2, "CPU")
	else:
		_agregar_etiqueta(ficha2, "J2")

	camera_offset = camera.global_position - ficha.global_position
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
	if not camera:
		return
	var active: Node3D
	if not GameManager.tokens.is_empty() and GameManager.current_player < GameManager.tokens.size():
		active = GameManager.tokens[GameManager.current_player]
	else:
		active = ficha
	var target := active.global_position + camera_offset
	camera.global_position = camera.global_position.lerp(
		target,
		clamp(delta * camera_smooth_speed, 0.0, 1.0)
	)

# =========================================================
# SONIDO Y POSICION AL PISAR CASILLA
# =========================================================
func _on_ficha_stepped(_index: int) -> void:
	move_sound.play()
	_actualizar_posicion()

# =========================================================
# BOTON SALIR
# =========================================================
func _on_salir() -> void:
	get_tree().quit()

# =========================================================
# BOTON TIRAR 3 (DEBUG)
# =========================================================
func _on_tirar_3() -> void:
	if game_over:
		return
	if game_mode == 2 and GameManager.current_player == 1:
		return
	dice_sound.play()
	await get_tree().create_timer(0.15).timeout
	dado_label.text = "Tiraste un 3"
	dado.set_locked(true)
	await GameManager.on_dice_rolled(3)
	if not game_over:
		dado.set_locked(false)

# =========================================================
# REINICIAR
# =========================================================
func _on_reiniciar() -> void:
	GameManager.tokens.clear()
	GameManager.current_player   = 0
	GameManager.is_player_moving = false
	GameManager.minijuego_activo = false
	GameManager.skip_player_index = -1
	GameManager.game_mode        = 0
	GameManager.last_action_type = ""
	get_tree().reload_current_scene()

# =========================================================
# DADO FISICO
# =========================================================
func _on_btn_tirar() -> void:
	if game_over or dado.is_rolling or dado.is_locked:
		return
	btn_tirar.disabled = true
	dado.roll()

func _on_dice_rolled(n: int) -> void:
	if game_over:
		return
	dice_sound.play()
	await get_tree().create_timer(0.15).timeout
	dado_label.text = "Tiraste un %d" % n
	dado.set_locked(true)
	await GameManager.on_dice_rolled(n)
	if not game_over:
		dado.set_locked(false)

# =========================================================
# CAMBIO DE TURNO
# =========================================================
func _on_turn_changed(player_index: int) -> void:
	if game_over:
		return
	_actualizar_turno(player_index)
	dado.set_locked(false)
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

	var n := randi() % 6 + 1
	dado_label.text = "La Maquina esta tirando el dado..."

	await dado.roll_cpu(n)

	if game_over:
		return

	dice_sound.play()
	dado_label.text = "La Maquina obtuvo un %d" % n
	await get_tree().create_timer(0.6).timeout

	if game_over:
		return

	dado.set_locked(true)
	await GameManager.on_dice_rolled(n)
	if not game_over:
		dado.set_locked(false)

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
	dado.set_locked(true)
	btn_tirar.disabled = true

	var mensaje: String
	if game_mode == 1:
		mensaje = "Gano el Jugador %d!" % (player_index + 1)
	elif player_index == 0:
		mensaje = "Gano el Jugador!"
	else:
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
