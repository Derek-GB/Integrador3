extends Node

# =========================================================
# CONSTANTES
# =========================================================
const QUESTION_CARD = preload("res://scenes/cards/QuestionCard.tscn")
const ACTION_CARD   = preload("res://scenes/cards/ActionCard.tscn")

const MINIGAME_EFFECTS: Dictionary = {
	3:  { "on_win": "spin_again",  "on_lose": "nothing"   },
	9:  { "on_win": "advance",     "on_lose": "nothing",  "value": 6 },
	13: { "on_win": "nothing",     "on_lose": "go_back",  "value": 3 },
	15: { "on_win": "nothing",     "on_lose": "go_back",  "value": 2 },
	19: { "on_win": "nothing",     "on_lose": "go_to_space", "value": 1 },
}
const MINIGAME_TILE_INDICES: Array[int] = [3, 9, 13, 15, 19]
const BLUE_TILE_INDICES: Array[int]     = [5, 11, 21, 34, 45, 54, 61, 66, 72]
const RED_TILE_INDICES: Array[int]      = [7, 16, 32, 39, 48, 58, 64, 68, 76]

const MINIGAMES: Dictionary = {
	3: {
		"title":          "¡Ordena el mapa de riesgo escolar!",
		"description":    "Participaste en la elaboración del mapa de riesgo",
		"instructions":   "Tocá una pieza y después toca donde la quieres acomodar, para armar el mapa de riesgo",
		"video_path":     "res://minigames/minigame_puzzle/assets/Puzzle_Instruction.ogv",
		"minigame_scene": "res://minigames/minigame_puzzle/MapPuzzle.tscn",
		"controls": [
			{ "action": "Tocar piezas", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
		]
	},
	9: {
		"title":          "¡Limpia el río!",
		"description":    "Ayuda a limpiar el río",
		"instructions":   "Selecciona una basura y arrástrala al basurero",
		"video_path":     "res://minigames/minigame_river/assets/River_Instruction.ogv",
		"minigame_scene": "res://minigames/minigame_river/RiverCleanupMinigame.tscn",
		"controls": [
			{ "action": "Arrastrar basura", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
		]
	},
	13: {
		"title":          "¡Esquiva los rayos!",
		"description":    "Te protegiste mientras pasaba la tormenta eléctrica.",
		"instructions":   "Muévete de derecha a izquierda esquivando los rayos",
		"video_path":     "res://minigames/minigame_storm/assets/Thunder_Instruction.ogv",
		"minigame_scene": "res://minigames/minigame_storm/StormMinigame.tscn",
		"controls": [
			{ "action": "Moverse derecha",   "icon": "res://minigames/ui_global/assets/left-button.png"  },
			{ "action": "Moverse izquierda", "icon": "res://minigames/ui_global/assets/right-button.png" },
		]
	},
	15: {
		"title":          "¡Desmonta la casa!",
		"description":    "Un volcán está por hacer erupción, ¡desmontá la casa antes de que sea tarde!",
		"instructions":   "Tocá todos los tornillos para desmontar cada pieza de la casa.",
		"video_path":     "res://minigames/minigame_house/assets/House_Instruction.ogv",
		"minigame_scene": "res://minigames/minigame_house/HouseMinigame.tscn",
		"controls": [
			{ "action": "Tocar tornillo", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
		]
	},
	19: {
		"title":          "¡Reforesta el bosque!",
		"description":    "Tu comunidad deforestó el bosque, ayuda a reforestarlo.",
		"instructions":   "Selecciona una semilla y arrástrala hacia un hoyo bueno.\nEvita los hoyos malos, te quitarán vida.\nCuando todas las semillas estén plantadas, usa la regadera antes de que se acabe el tiempo.",
		"video_path":     "res://minigames/minigame_defo/sprites/Tree_instruction2.ogv",
		"minigame_scene": "res://minigames/minigame_defo/mini_game.tscn",
		"controls": [
			{ "action": "Arrastrar semillas y regadera", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
		]
	},
}

# =========================================================
# VARIABLES
# =========================================================
var tokens: Array            = []
var current_player: int      = 0
var is_player_moving: bool   = false
var minigame_active: bool    = false
var skip_player_index: int   = -1
var last_action_type: String = ""
var message_label: Label     = null

var game_mode: int             = 1
var player_names: Array[String] = ["Jugador", "Jugador 2"]

# =========================================================
# CICLO DE VIDA
# =========================================================
func _ready() -> void:
	await get_tree().process_frame
	var scene := get_tree().current_scene
	if scene.has_node("UI/MessageLabel"):
		message_label = scene.get_node("UI/MessageLabel")
		message_label.visible = false

# =========================================================
# MÉTODOS PÚBLICOS
# =========================================================
func register_token(token: Node) -> void:
	if token in tokens:
		return
	print("GameManager: registrando token:", token)
	tokens.append(token)

func on_dice_rolled(n: int) -> void:
	if minigame_active:
		print("GameManager: minijuego activo, ignorando dado")
		return
	if is_player_moving:
		print("GameManager: ficha en movimiento, ignorando dado")
		return
	if tokens.is_empty():
		print("GameManager: no hay tokens registrados")
		return
	if current_player >= tokens.size():
		current_player = 0

	is_player_moving = true
	var active_token: Node = tokens[current_player]
	await active_token.move_steps(n)
	print("GameManager: movimiento completado, casilla:", active_token.current_index)

	if await check_special_tile(active_token):
		return

	is_player_moving = false
	_unlock_dice()
	_next_turn()

func check_special_tile(active_token: Node) -> bool:
	var index: int = active_token.current_index

	if index in MINIGAME_TILE_INDICES:
		await _launch_minigame_for_tile(index)
		is_player_moving = false
		_unlock_dice()
		_next_turn()
		return true

	if index in BLUE_TILE_INDICES:
		var hit: bool = await show_blue_card()
		if hit:
			print("GameManager: respuesta correcta, mismo jugador tira otra vez")
			is_player_moving = false
			_unlock_dice()
			Events.turn_changed.emit(current_player)
		else:
			print("GameManager: respuesta incorrecta, pierde próximo turno")
			skip_player_index = current_player
			is_player_moving = false
			_unlock_dice()
			_next_turn()
		return true

	if index in RED_TILE_INDICES:
		await show_red_card(active_token)
		return true

	return false

func show_blue_card() -> bool:
	print("GameManager: carta azul activada")
	minigame_active = true

	var file := FileAccess.open("res://data/cartas_azules.json", FileAccess.READ)
	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	json.parse(json_text)	
	var data: Dictionary = json.get_data()
	var cards: Array = data["tarjetas"]
	var question = cards[randi() % cards.size()]

	var image_background := ""
	if question.has("imagen"):
		image_background = question["imagen"]

	var card := QUESTION_CARD.instantiate()
	card.setup(question, image_background)
	card.cpu_mode = (game_mode == 2 and current_player == 1)
	get_tree().current_scene.add_child(card)

	var result: Array = [false]
	card.answer_result.connect(func(correct: bool): result[0] = correct)
	await card.tree_exited

	print("GameManager: resultado carta azul =", result[0])
	minigame_active = false
	return result[0]

func show_red_card(active_token: Node) -> void:
	print("GameManager: carta roja activada")
	minigame_active  = true
	last_action_type = ""

	var card := ACTION_CARD.instantiate()
	card.cpu_mode = (game_mode == 2 and current_player == 1)
	get_tree().current_scene.add_child(card)

	var action_result := [last_action_type, 0]
	card.action_completed.connect(func(type: String, value: int) -> void:
		action_result[0] = type
		action_result[1] = value
		print("GameManager: acción guardada:", type, " valor:", value)
	)

	await card.tree_exited

	last_action_type           = action_result[0]
	var last_action_value: int = action_result[1]
	print("GameManager: carta cerrada, acción:", last_action_type, " valor:", last_action_value)

	if last_action_type == "advance":
		Events.play_sound.emit("avanzar")
		await active_token.move_steps(last_action_value)
		if await check_special_tile(active_token):
			return

	elif last_action_type == "go_back":
		Events.play_sound.emit("retroceder")
		await active_token.move_back(last_action_value)
		if await check_special_tile(active_token):
			return

	elif last_action_type == "go_to_space":
		var steps_needed: int = last_action_value - active_token.current_index
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
			message_label.text    = "¡%s pierde el siguiente turno!" % nombre
			await get_tree().create_timer(2.0).timeout
			message_label.visible = false

	elif last_action_type == "spin_again":
		minigame_active  = false
		is_player_moving = false
		_unlock_dice()
		Events.turn_changed.emit(current_player)
		return

	minigame_active  = false
	is_player_moving = false
	_unlock_dice()
	_next_turn()

func is_cpu_turn() -> bool:
	return game_mode == 2 and current_player == 1

# =========================================================
# MÉTODOS PRIVADOS
# =========================================================
func _launch_minigame_for_tile(tile_index: int) -> void:
	print("GameManager: lanzando minijuego para casilla", tile_index)
	minigame_active = true
	Events.set_minigame.emit(tile_index)

	var won: bool = await Events.minigame_result

	minigame_active = false
	print("GameManager: minijuego casilla", tile_index, " resultado:", won)

	await _apply_minigame_effect(tile_index, won)

func _apply_minigame_effect(tile_index: int, won: bool) -> void:
	if not MINIGAME_EFFECTS.has(tile_index):
		return

	var effect: Dictionary = MINIGAME_EFFECTS[tile_index]
	var action: String     = effect["on_win"] if won else effect["on_lose"]
	var value: int         = effect.get("value", 0)
	var active_token: Node = tokens[current_player]

	print("GameManager: efecto minijuego =", action, " valor =", value)

	if action == "spin_again":
		is_player_moving = false
		_unlock_dice()
		Events.turn_changed.emit(current_player)
		return

	elif action == "advance":
		Events.play_sound.emit("avanzar")
		await active_token.move_steps(value)
		if await check_special_tile(active_token):
			return

	elif action == "go_back":
		Events.play_sound.emit("retroceder")
		await active_token.move_back(value)
		if await check_special_tile(active_token):
			return

	elif action == "go_to_space":
		var steps_needed: int = value - active_token.current_index
		if steps_needed > 0:
			await active_token.move_steps(steps_needed)
		elif steps_needed < 0:
			await active_token.move_back(-steps_needed)
		if await check_special_tile(active_token):
			return

	# "nothing" y cualquier otro caso: solo pasar turno
	is_player_moving = false
	_unlock_dice()
	_next_turn()

func _unlock_dice() -> void:
	var scene := get_tree().current_scene
	if scene.has_node("Dado"):
		scene.get_node("Dado").set_locked(false)
		print("GameManager: dado desbloqueado")

func _next_turn() -> void:
	if tokens.is_empty():
		return
	current_player = (current_player + 1) % tokens.size()
	print("GameManager: siguiente turno -> jugador", current_player + 1)
	Events.turn_changed.emit(current_player)
