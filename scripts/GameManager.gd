extends Node

# =========================================================
# MINIJUEGOS
# =========================================================
const MAP_PUZZLE = preload("res://scenes/minijuegos/MapPuzzle.tscn")
const QUESTION_CARD = preload("res://Scenes/QuestionCard.tscn")
const ACTION_CARD = preload("res://scenes/cards/ActionCard.tscn")

var minijuego_activo: bool = false
var mensaje_label: Label

# =========================================================
# VARIABLES
# =========================================================
var tokens: Array = []
var current_player: int = 0
var is_player_moving: bool = false
var skip_player_index: int = -1
var last_action_type: String = ""

# =========================================================
# MODO DE JUEGO Y NOMBRES
# =========================================================
var game_mode: int = 1  # 1=dos_jugadores  2=vs_maquina
var player_names: Array[String] = ["Jugador", "Jugador 2"]

signal turn_changed(player_index: int)

# =========================================================
# READY
# =========================================================
func _ready() -> void:
	await get_tree().process_frame
	var scene = get_tree().current_scene
	if scene.has_node("UI/MensajeLabel"):
		mensaje_label = scene.get_node("UI/MensajeLabel")
		mensaje_label.visible = false

# =========================================================
# REGISTRAR TOKENS
# =========================================================
func register_token(token: Node) -> void:
	if token in tokens:
		return
	print("GameManager: registrando token:", token)
	tokens.append(token)

# =========================================================
# CUANDO EL DADO TERMINA
# =========================================================
func on_dice_rolled(n: int) -> void:
	if minijuego_activo:
		print("GameManager: minijuego activo")
		return

	if is_player_moving:
		print("GameManager: ya se está moviendo una ficha")
		return

	if tokens.is_empty():
		print("GameManager: no hay tokens registrados")
		return

	# =========================================================
	# CORREGIR ÍNDICE SI SE PASÓ
	# =========================================================
	if current_player >= tokens.size():
		current_player = 0

	is_player_moving = true

	var active_token = tokens[current_player]

	await active_token.move_steps(n)

	print("GameManager: movimiento completado, casilla:", active_token.current_index)

	# =========================================================
	# CASILLA 3 — PUZZLE
	# =========================================================
	if active_token.current_index == 3:
		await activar_casilla_3()
		is_player_moving = false
		_desbloquear_dado()
		_next_turn()
		return

	# =========================================================
	# CASILLA 5 — CARTA EDUCATIVA
	# =========================================================
	if active_token.current_index in [5, 11, 21, 34, 45, 54, 61, 66, 72]:
		var acerto: bool = await mostrar_carta_azul()
		if acerto:
			print("GameManager: respuesta correcta, mismo jugador tira otra vez")
			is_player_moving = false
			_desbloquear_dado()
			turn_changed.emit(current_player)
		else:
			print("GameManager: respuesta incorrecta, pierde proximo turno")
			skip_player_index = current_player
			is_player_moving = false
			_desbloquear_dado()
			_next_turn()
		return

	# =========================================================
	# CASILLA 7 — CARTA DE ACCIÓN
	# =========================================================
	if active_token.current_index in [7,16,32,39,48,58,64,68,76]:
		await mostrar_carta_roja(active_token)
		return

	# =========================================================
	# CASILLA NORMAL
	# =========================================================
	is_player_moving = false
	_desbloquear_dado()
	_next_turn()

# =========================================================
# CASILLA 3 — PUZZLE
# =========================================================
func activar_casilla_3() -> void:
	print("GameManager: jugador cayó en casilla 3")
	minijuego_activo = true

	if mensaje_label:
		mensaje_label.visible = true
		mensaje_label.text = "¡Debes restaurar el mapa!"

	var puzzle = MAP_PUZZLE.instantiate()
	get_tree().current_scene.add_child(puzzle)
	puzzle.position = Vector2.ZERO

	await puzzle.puzzle_completed

	print("GameManager: puzzle completado")
	puzzle.queue_free()

	if mensaje_label:
		mensaje_label.text = "¡Mapa restaurado!"
		await get_tree().create_timer(2.0).timeout
		mensaje_label.visible = false

	minijuego_activo = false

# =========================================================
# MOSTRAR CARTAS AZULES — CARTA EDUCATIVA
# =========================================================
func mostrar_carta_azul() -> bool:
	print("GameManager: jugador cayó en una carta azul")
	minijuego_activo = true

	var file = FileAccess.open("res://data/cartas_azules.json", FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	json.parse(json_text)
	var data = json.get_data()

	var tarjetas = data["tarjetas"]

	var pregunta = tarjetas[randi() % tarjetas.size()]

	var card = QUESTION_CARD.instantiate()
	card.setup(pregunta)
	card.cpu_mode = (game_mode == 2 and current_player == 1)
	get_tree().current_scene.add_child(card)

	# GDScript 4 captura primitivos (bool) por valor en lambdas.
	# Usamos Array como contenedor por referencia para que el callback
	# pueda modificar el resultado que leeremos después del await.
	print("GameManager: esperando resultado de carta azul")
	var result: Array = [false]
	card.answer_result.connect(func(correct: bool): result[0] = correct)

	await card.tree_exited

	print("GameManager: carta educativa cerrada")
	print("GameManager: resultado recibido carta azul =", result[0])
	minijuego_activo = false
	return result[0]

# =========================================================
# CASILLA 7 — CARTA DE ACCIÓN
# =========================================================
func mostrar_carta_roja(active_token) -> void:
	print("GameManager: jugador cayó en carta de accion!")
	minijuego_activo = true
	last_action_type = ""

	var card = ACTION_CARD.instantiate()
	card.cpu_mode = (game_mode == 2 and current_player == 1)
	get_tree().current_scene.add_child(card)

	var action_result = [last_action_type, 0]
	card.action_completed.connect(func(type, value):
		action_result[0] = type
		action_result[1] = value
		print("GameManager: acción guardada:", action_result[0], " valor:", action_result[1])
	)

	await card.tree_exited

	print("GameManager: carta cerrada, acción:", action_result[0], " valor:", action_result[1])
	last_action_type = action_result[0]
	var last_action_value: int = action_result[1]

	if last_action_type == "advance":
		print("GameManager: avanzando", last_action_value, "casillas")
		await active_token.move_steps(last_action_value)

	elif last_action_type == "go_back":
		print("GameManager: retrocediendo", last_action_value, "casillas")
		await active_token.move_back(last_action_value)

	elif last_action_type == "go_to_space":
		print("GameManager: yendo a casilla", last_action_value)
		var steps_needed = last_action_value - active_token.current_index
		if steps_needed > 0:
			await active_token.move_steps(steps_needed)
		elif steps_needed < 0:
			await active_token.move_back(-steps_needed)

	elif last_action_type == "skip_turn":
		skip_player_index = current_player
		if mensaje_label:
			var nombre := player_names[current_player] if current_player < player_names.size() else "Jugador"
			mensaje_label.visible = true
			mensaje_label.text = "¡%s pierde el siguiente turno!" % nombre
			await get_tree().create_timer(2.0).timeout
			mensaje_label.visible = false

	elif last_action_type == "spin_again":
		minijuego_activo = false
		is_player_moving = false
		_desbloquear_dado()
		turn_changed.emit(current_player)
		return

	minijuego_activo = false
	is_player_moving = false
	_desbloquear_dado()
	_next_turn()

# =========================================================
# DESBLOQUEAR DADO
# =========================================================
func is_cpu_turn() -> bool:
	return game_mode == 2 and current_player == 1

func _desbloquear_dado() -> void:
	print("GameManager: current_player antes de desbloquear =", current_player)
	print("GameManager: es turno CPU =", is_cpu_turn())
	var scene = get_tree().current_scene
	if scene.has_node("Dado"):
		scene.get_node("Dado").set_locked(false)
		print("GameManager: dado desbloqueado")

# =========================================================
# CAMBIAR TURNO
# =========================================================
func _next_turn() -> void:
	if tokens.is_empty():
		return
	current_player = (current_player + 1) % tokens.size()
	print("GameManager: siguiente turno -> jugador", current_player + 1)
	turn_changed.emit(current_player)
