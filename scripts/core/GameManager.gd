extends Node

# =========================================================
# MINIJUEGOS
# =========================================================
const MAP_PUZZLE = preload("res://scenes/minigames/MapPuzzle.tscn")
const QUESTION_CARD = preload("res://scenes/cards/QuestionCard.tscn")
const ACTION_CARD = preload("res://scenes/cards/ActionCard.tscn")

var minigame_active: bool = false
var message_label: Label

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

# =========================================================
# READY
# =========================================================
func _ready() -> void:
	await get_tree().process_frame
	var scene = get_tree().current_scene
	if scene.has_node("UI/MessageLabel"):
		message_label = scene.get_node("UI/MessageLabel")
		message_label.visible = false

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
	if minigame_active:
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

	if await check_special_tile(active_token):
		return

	# =========================================================
	# CASILLA 3 — PUZZLE
	# =========================================================
	if active_token.current_index == 3:
		await activate_minigame()
		is_player_moving = false
		_unlock_dice()
		_next_turn()
		return

	# =========================================================
	# CASILLA 5 — CARTA EDUCATIVA
	# =========================================================
	if active_token.current_index in [5, 11, 21, 34, 45, 54, 61, 66, 72]:
		var hit: bool = await show_blue_card()
		if hit:
			print("GameManager: respuesta correcta, mismo jugador tira otra vez")
			is_player_moving = false
			_unlock_dice()
			Events.turn_changed.emit(current_player)
		else:
			print("GameManager: respuesta incorrecta, pierde proximo turno")
			skip_player_index = current_player
			is_player_moving = false
			_unlock_dice()
			_next_turn()
		return

	# =========================================================
	# CASILLA 7 — CARTA DE ACCIÓN
	# =========================================================
	if active_token.current_index in [7,16,32,39,48,58,64,68,76]:
		await show_red_card(active_token)
		return

	# =========================================================
	# CASILLA NORMAL
	# =========================================================
	is_player_moving = false
	_unlock_dice()
	_next_turn()

# =========================================================
# CASILLA 3 — PUZZLE
# =========================================================
func activate_minigame() -> void:
	print("GameManager: jugador cayó en casilla 3")
	minigame_active = true

	if message_label:
		message_label.visible = true
		message_label.text = "¡Debes restaurar el mapa!"

	var puzzle = MAP_PUZZLE.instantiate()
	get_tree().current_scene.add_child(puzzle)
	puzzle.position = Vector2.ZERO

	await puzzle.puzzle_completed

	print("GameManager: puzzle completado")
	puzzle.queue_free()

	if message_label:
		message_label.text = "¡Mapa restaurado!"
		await get_tree().create_timer(2.0).timeout
		message_label.visible = false

	minigame_active = false

func _get_blue_indices() -> Array[int]:
	return [5, 11, 21, 34, 45, 54, 61, 66, 72]

func _get_red_indices() -> Array[int]:
	return [7, 16, 32, 39, 48, 58, 64, 68, 76]

func check_special_tile(active_token: Node) -> bool:
	if active_token.current_index == 3:
		await activate_minigame()
		is_player_moving = false
		_unlock_dice()
		_next_turn()
		return true

	if active_token.current_index in _get_blue_indices():
		var hit: bool = await show_blue_card()
		if hit:
			print("GameManager: respuesta correcta, mismo jugador tira otra vez")
			is_player_moving = false
			_unlock_dice()
			Events.turn_changed.emit(current_player)
		else:
			print("GameManager: respuesta incorrecta, pierde proximo turno")
			skip_player_index = current_player
			is_player_moving = false
			_unlock_dice()
			_next_turn()
		return true

	if active_token.current_index in _get_red_indices():
		await show_red_card(active_token)
		return true

	return false

# =========================================================
# MOSTRAR CARTAS AZULES — CARTA EDUCATIVA
# =========================================================
func show_blue_card() -> bool:
	print("GameManager: jugador cayó en una carta azul")
	minigame_active = true

	var file = FileAccess.open("res://data/cartas_azules.json", FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	json.parse(json_text)
	var data = json.get_data()

	var cards = data["tarjetas"]

	var question = cards[randi() % cards.size()]

	var card = QUESTION_CARD.instantiate()
	
	# Extraer la imagen de fondo (si existe)
	var image_background = ""
	if question.has("imagen"):
		image_background = question["imagen"]
	
	card.setup(question, image_background)  # ← Ahora pasa la imagen
	card.cpu_mode = (game_mode == 2 and current_player == 1)
	get_tree().current_scene.add_child(card)

	print("GameManager: esperando resultado de carta azul")
	var result: Array = [false]
	card.answer_result.connect(func(correct: bool): result[0] = correct)

	await card.tree_exited

	print("GameManager: carta educativa cerrada")
	print("GameManager: resultado recibido carta azul =", result[0])
	minigame_active = false
	return result[0]

# =========================================================
# CASILLA 7 — CARTA DE ACCIÓN
# =========================================================
func show_red_card(active_token) -> void:
	print("GameManager: jugador cayó en carta de accion!")
	minigame_active = true
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
		Events.play_sound.emit("avanzar")
		print("GameManager: avanzando", last_action_value, "casillas")
		await active_token.move_steps(last_action_value)
		if await check_special_tile(active_token):
			return

	elif last_action_type == "go_back":
		Events.play_sound.emit("retroceder")
		print("GameManager: retrocediendo", last_action_value, "casillas")
		await active_token.move_back(last_action_value)
		if await check_special_tile(active_token):
			return

	elif last_action_type == "go_to_space":
		print("GameManager: yendo a casilla", last_action_value)
		var steps_needed = last_action_value - active_token.current_index
		if steps_needed > 0:
			await active_token.move_steps(steps_needed)
		elif steps_needed < 0:
			await active_token.move_back(-steps_needed)
		if await check_special_tile(active_token):
			return

	elif last_action_type == "skip_turn":
		skip_player_index = current_player
		if message_label:
			var nombre := player_names[current_player] if current_player < player_names.size() else "Jugador"
			message_label.visible = true
			message_label.text = "¡%s pierde el siguiente turno!" % nombre
			await get_tree().create_timer(2.0).timeout
			message_label.visible = false

	elif last_action_type == "spin_again":
		minigame_active = false
		is_player_moving = false
		_unlock_dice()
		Events.turn_changed.emit(current_player)
		return

	minigame_active = false
	is_player_moving = false
	_unlock_dice()
	_next_turn()

# =========================================================
# DESBLOQUEAR DADO
# =========================================================
func is_cpu_turn() -> bool:
	return game_mode == 2 and current_player == 1

func _unlock_dice() -> void:
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
	Events.turn_changed.emit(current_player)
