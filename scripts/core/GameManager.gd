extends Node

# =========================================================
# CONSTANTES
# =========================================================
const QUESTION_CARD = preload("res://scenes/cards/QuestionCard.tscn")
const ACTION_CARD   = preload("res://scenes/cards/ActionCard.tscn")
const MINIGAME_ACTION_DIALOG = preload("res://scenes/board/MinigameActionDialogFinished.tscn")

const MINIGAME_EFFECTS: Dictionary = {
	3:  { "on_win": "spin_again",  "on_lose": "nothing"   },
	9:  { "on_win": "advance",     "on_lose": "nothing",  "value": 5 },
	13: { "on_win": "advance",     "on_lose": "nothing",  "value": 4 },
	15: { "on_win": "nothing",     "on_lose": "go_back",  "value": 1 },
	19: { "on_win": "nothing",     "on_lose": "go_back",  "value": 1 },
	23: { "on_win": "advance",     "on_lose": "nothing",  "value": 4 },
	25: { "on_win": "go_to_space", "on_lose": "nothing",  "value": 30 },
	29: { "on_win": "advance",     "on_lose": "nothing",  "value": 4 },
	31: { "on_win": "advance",     "on_lose": "nothing",  "value": 5 },
	35: { "on_win": "advance",     "on_lose": "nothing",  "value": 3 },
	37: { "on_win": "nothing",     "on_lose": "go_back",  "value": 4 },
	42: { "on_win": "advance",     "on_lose": "nothing",  "value": 1 },
	44: { "on_win": "nothing",     "on_lose": "go_back",  "value": 1 },
	47: { "on_win": "advance",     "on_lose": "nothing",  "value": 2 },
	50: { "on_win": "advance",     "on_lose": "nothing",  "value": 2 },
	53: { "on_win": "nothing",     "on_lose": "go_back",  "value": 1 },
	60: { "on_win": "advance",     "on_lose": "nothing",  "value": 2 },
	63: { "on_win": "advance",     "on_lose": "nothing",  "value": 2 },
	67: { "on_win": "nothing",     "on_lose": "go_back",  "value": 2 },
	70: { "on_win": "advance",     "on_lose": "nothing",  "value": 3 },
	55: { "on_win": "advance",     "on_lose": "nothing",  "value": 4 },
	71: { "on_win": "advance",     "on_lose": "nothing",  "value": 2 },
	73: { "on_win": "advance",     "on_lose": "nothing",  "value": 2 },
	74: { "on_win": "advance",     "on_lose": "nothing",  "value": 1 },
}
const MINIGAME_TILE_INDICES: Array[int] = [3, 9, 13, 15, 19, 23, 25, 29, 31, 35, 37, 42, 44, 47, 50, 53, 55, 60, 63, 67, 70, 71, 73, 74]
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
			{ "action": "Moverse derecha, moverse izquierda", "icon": "res://minigames/ui_global/assets/Left_Right.png" },
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
	23: {
		"title":          "¡Rescata a tus amigos!",
		"description":    "Ayuda a tus amigos a llegar a la zona segura durante la inundación.",
		"instructions":   "Muévete por el laberinto, rescata a los dos amigos y llega a la zona segura antes de que se acabe el tiempo.",
		"video_path":     "res://minigames/minigame_laberinto/assets/maze_Instructions.ogv",
		"minigame_scene": "res://minigames/minigame_laberinto/maze_minigame.tscn",
		"controls": [
			{ "action": "Moverse arriba, abajo, izquierda y derecha", "icon": "res://minigames/ui_global/assets/Movement.png" },
		]
	},
	25: {
		"title":          "¡Protege la ladera!",
		"description":    "Coloca arbolitos en puntos estratégicos para formar barreras naturales y detener las rocas antes de que provoquen un deslizamiento.",
		"instructions":   "Observa la dirección en la que cae cada roca. Cuando aparezca el punto de siembra, arrastra un árbol desde la bandeja de selección y colócalo en el camino de la roca.",
		"video_path":     "res://minigames/minigame_hillside_barrier/assets/instruction.ogv",
		"minigame_scene": "res://minigames/minigame_hillside_barrier/HillsideBarrierMinigame.tscn",
		"controls": [
			{ "action": "Arrastrar y soltar árbol", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
		]
	},
	29: {
		"title":          "¡Llega a la zona segura!",
		"description":    "TERREMOTO. Te metiste debajo de la mesa para protegerte.",
		"instructions":   "Mantén presionado el botón rojo cuando ocurra un terremoto para ocultarte debajo de la mesa.",
		"video_path":     "res://minigames/minigame_earthquake/assets/EarthquakeInstructions.ogv",
		"minigame_scene": "res://minigames/minigame_earthquake/Main.tscn",
		"controls": [
			{ "action": "Mantén presionado el botón", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
		]
	},
	31: {
		"title":          "¡Ordena el botiquín!",
		"description":    "Abre el botiquín y organiza correctamente todos los implementos médicos.",
		"instructions":   "Primero selecciona los dos seguros para abrir el botiquín. Después arrastra cada implemento hacia su espacio correspondiente antes de que se acaben los 30 segundos.",
		"video_path":     "res://minigames/minigame_kit/assets/kit_Instruction.ogv",
		"minigame_scene": "res://minigames/minigame_kit/MedicalKitMinigame.tscn",
		"controls": [
			{ "action": "Abrir los seguros y arrastrar los implementos", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
		]
	},
	35: {
		"title":          "¡Identifica el río diferente!",
		"description":    "Identificaste que el río está creciendo. Observa los ríos y encuentra cuál tiene una característica distinta.",
		"instructions":   "Mira cuidadosamente cada grupo de ríos. Haz clic sobre el río diferente para avanzar de ronda. Ganas si completas las tres rondas antes de quedarte sin vidas o sin tiempo.",
		"video_path":     "res://minigames/minigame_identify_river/assets/videoriver.ogv",
		"minigame_scene": "res://minigames/minigame_identify_river/main.tscn",
		"controls": [
			{ "action": "Seleccionar río", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
		]
	},
	37: {
		"title":          "¡Limpia el río!",
		"description":    "Las fábricas han contaminado el río de tu comunidad.",
		"instructions":   "Mueve el cursor rápidamente sobre los desechos que aparecen en el agua para eliminarlos antes de que se acabe el tiempo.",
		"video_path":     "res://minigames/minigame_river_clean/assets/video/RiverCleanInstructions.ogv",
		"minigame_scene": "res://minigames/minigame_river_clean/RiverCleanMinigame.tscn",
		"controls": [
			{ "action": "Mover guante", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
		]
	},
	47: {
		"title":          "¡Construye la ruta segura!",
		"description":    "Construye un camino seguro desde la escuela hasta la zona de reunión, evitando los obstáculos.",
		"instructions":   "Arrastra las piezas de camino desde el panel derecho y colócalas en las casillas disponibles del mapa. Conecta la escuela con la zona segura antes de que termine el tiempo.",
		"video_path":     "res://minigames/minigame_route/assets/Route_Instruction.ogv",
		"minigame_scene": "res://minigames/minigame_route/SchoolRouteMinigame.tscn",
		"controls": [
			{ "action": "Arrastrar caminos", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
			{ "action": "Quitar caminos",    "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
		]
	},
	44: {
		"title":          "¡Revisa las fechas de vencimiento!",
		"description":    "Olvidaste revisar la fecha de vencimiento de los suministros.",
		"instructions":   "Observa la fecha actual y las fechas de vencimiento de cada producto. Los productos vigentes van a la refrigeradora, los vencidos al basurero.",
		"video_path":     "res://minigames/minigame_expiration/assets/ExpirationInstruction.ogv",
		"minigame_scene": "res://minigames/minigame_expiration/MainExpiration.tscn",
		"controls": [
			{ "action": "Arrastrar comida", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
		]
	},
	53: {
		"title":          "¡Alarma Inclusiva!",
		"description":    "Tu escuela aún no cuenta con un sistema de alarma adecuado para personas con discapacidad auditiva.",
		"instructions":   "Arrastra cada objeto a la categoría correcta. Identifica las luces intermitentes, dispositivos de vibración y señales visuales. Completa la clasificación antes de que se agote el tiempo.",
		"video_path":     "res://minigames/minigame_inclusive_alarms/assets/video/InclusiveAlarmsInstructions.ogv",
		"minigame_scene": "res://minigames/minigame_inclusive_alarms/inclusive_alarms_minigame.tscn",
		"controls": [
			{ "action": "Arrastrar objetos", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
		]
	},
	42: {
		"title":          "¡Apaga el incendio!",
		"description":    "Alguien dejó un cigarrillo en el bosque y provocó un incendio.",
		"instructions":   "Presiona los árboles que están en llamas para apagar el fuego. Tienes 2 segundos antes de que el árbol se queme. Si presionas un árbol sin fuego, perderás una vida.",
		"video_path":     "res://minigames/minigame_fire/assets/Fire_Instruction.ogv",
		"minigame_scene": "res://minigames/minigame_fire/MainFire.tscn",
		"controls": [
			{ "action": "Presionar árboles en llamas", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
		]
	},
	50: {
		"title":          "¡Alerta de deslizamiento!",
		"description":    "Identificaste una amenaza de deslizamiento en la comunidad y debes actuar rápido.",
		"instructions":   "Muévete con las flechitas para esquivar las rocas. Llega al teléfono, presiona E y marca 911. Después dirígete a la cabina segura antes de que se acabe el tiempo.",
		"video_path":     "res://minigames/minigame_landslide/assets/MiniGame13.ogv",
		"minigame_scene": "res://minigames/minigame_landslide/LandslideMinigame.tscn",
		"controls": [
			{ "action": "Mover personaje",           "icon": "res://minigames/ui_global/assets/ArrowKeys.png" },
			{ "action": "Usar teléfono / marcar 911","icon": "res://minigames/ui_global/assets/KeyE.png"      },
		]
	},
		60: {
		"title":          "¡Derechos de la niñez!",
		"description":    "Aprendiste que aún en medio de un desastre, la niñez tiene derechos y debe ser protegida.",
		"instructions":   "Participarás en un juego de preguntas y respuestas relacionado con los derechos de la niñez durante situaciones de desastre.\nEn cada ronda aparecerá una pregunta con diferentes opciones y deberás seleccionar la respuesta correcta.\nGanas si completas correctamente la cantidad requerida de preguntas antes de que se acabe el tiempo.\nPierdes si fallas demasiadas respuestas o si no terminas dentro del tiempo establecido.",
		"video_path":     "res://minigames/minigame_Question/assets/Video.ogv",
		"minigame_scene": "res://minigames/minigame_Question/QuestionMinigame.tscn",
		"controls": [
			{ "action": "Seleccionar respuesta", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
		]
	},
	63: {
		"title":          "¡Alerta de maremoto!",
		"description":    "Evacua a un lugar más alto.",
		"instructions":   "Debes esquivar los obstáculos y evitar que te alcance el maremoto hasta llegar a la zona segura. Con las flechas de arriba y abajo te mueves entre niveles para evitar los obstáculos.",
		"video_path":     "res://minigames/minigame_wave/assets/WaveInstruction.ogv",
		"minigame_scene": "res://minigames/minigame_wave/WaveGame.tscn",
		"controls": [
			{ "action": "Moverse derecha, izquierda, arriba y abajo", "icon": "res://minigames/ui_global/assets/Movement.png" },
		]
	},
	67: {
		"title":          "¡Repara las fugas!",
		"description":    "Evita el desperdicio de agua reparando todas las fugas antes de que el depósito se vacíe.",
		"instructions":   "Arrastra el parche hasta cada fuga de la tubería. Repara todos los chorros antes de que el nivel de agua llegue a cero.",
		"video_path":     "res://minigames/minigame_water_leak/assets/WaterLeak_Instruction.ogv",
		"minigame_scene": "res://minigames/minigame_water_leak/WaterLeakMinigame.tscn",
		"controls": [
			{ "action": "Arrastrar parche", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
		]
	},
	70: {
		"title":          "¡Repara el puente!",
		"description":    "Un puente se rompió y debes arreglarlo antes de que alguien caiga.",
		"instructions":   "Arrastra las tablas al lugar correcto para completar el puente. Si te equivocas, perderás vidas. Luego usa el martillo para terminar la reparación.",
		"video_path":     "res://minigames/minigame_bridge/assets/Bridge_Instruction.ogv",
		"minigame_scene": "res://minigames/minigame_bridge/BridgeMinigame.tscn",
		"controls": [
			{ "action": "Arrastrar tablas, arrastrar martillo", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
		]
	},
	55: {
		"title":          "¡Encuentra a la familia!",
		"description":    "¡Alerta! Debes ir al punto de encuentro acordado con la familia durante una emergencia.",
		"instructions":   "Mueve al rescatista dentro de la casa para encontrar a papá, mamá, hijo e hija. Rescata a los cuatro familiares y llévalos a la zona segura antes de que se acabe el tiempo.",
		"video_path":     "res://minigames/minigame_FamilyMeeting/assets/video/FamilyMeetingInstructions.ogv",
		"minigame_scene": "res://minigames/minigame_FamilyMeeting/FamilyMeetingMinigame.tscn",
		"controls": [
			{ "action": "Moverse derecha, izquierda, arriba y abajo", "icon": "res://minigames/ui_global/assets/Movement.png" },
		]
	},
	71: {
		"title":          "¡Evacuación segura!",
		"description":    "Ayuda a los niños a evacuar de forma ordenada y llegar seguros a la escuela siguiendo el ritmo correcto.",
		"instructions":   "Observa los colores que bajan en pantalla y presiona las flechas correctas o el ratón cuando lleguen a la zona de ritmo. Si fallas demasiadas veces o se acaba el tiempo, perderás la partida.",
		"video_path":     "res://minigames/minigame_evacuation/assets/InstructionsEva.ogv",
		"minigame_scene": "res://minigames/minigame_evacuation/EvacuationRhythmMinigame.tscn",
		"controls": [
			{ "action": "Usa el ratón", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
			{ "action": "Derecha, izquierda, arriba y abajo", "icon": "res://minigames/ui_global/assets/Movement.png" },
		]
	},
	73: {
		"title":          "¡Desafío Matemático!",
		"description":    "Pon a prueba tu rapidez resolviendo operaciones matemáticas antes de que se acabe el tiempo.",
		"instructions":   "Observa la operación que aparece en la pizarra y selecciona el número correcto en el teclado. Completa 10 operaciones antes de que termine el tiempo. Si acumulas 3 errores o se acaba el tiempo, perderás la partida.",
		"video_path":     "res://minigames/minigame_mathChallenge/assets/video/InstructionsMath.ogv",
		"minigame_scene": "res://minigames/minigame_mathChallenge/MathChallengeMinigame.tscn",
		"controls": [
			{ "action": "Seleccionar la respuesta correcta", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
		]
	},
	74: {
		"title":          "¡Comité de emergencias!",
		"description":    "Forma parte del comité de emergencias y organiza correctamente a cada integrante según sus responsabilidades.",
		"instructions":   "Arrastra cada objeto al personaje correcto. El bombero necesita sus herramientas contra incendios, la Cruz Roja necesita objetos médicos, el rescatista necesita equipo de rescate y el comunicador necesita objetos para avisar y coordinar. Si colocas un objeto en el lugar incorrecto, perderás una vida. Si completas todas las asignaciones antes de que se acabe el tiempo, ganarás la partida.",
		"video_path":     "res://minigames/minigame_committee/assets/InstructionsCommittee.ogv",
		"minigame_scene": "res://minigames/minigame_committee/EmergencyCommitteeMinigame.tscn",
		"controls": [
			{ "action": "Arrastrar objetos con el ratón", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
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
var pausers: int = 0

# =========================================================
# CICLO DE VIDA
# =========================================================
func _ready() -> void:
	await get_tree().process_frame
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	
	
	Events.notify_pause.connect(_set_on_pause)
	Events.notify_pause_for_minigame.connect(_set_on_pause_for_minigame)

# =========================================================
# MÉTODOS PÚBLICOS
# =========================================================
func instantiate_message_lbl() -> void:
	var scene := get_tree().current_scene
	if scene.has_node("UI/InfoPanel/MessageLabel"):
		message_label = scene.get_node("UI/InfoPanel/MessageLabel")
		message_label.visible = false

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
	
	# Esperar a que la ficha termine de moverse
	await active_token.move_steps(n)
	
	# COMPROBACIÓN DE SEGURIDAD: ¿Sigue la ficha en el árbol de escena activa?
	if not is_instance_valid(active_token) or not active_token.is_inside_tree():
		is_player_moving = false
		return

	print("GameManager: movimiento completado, casilla:", active_token.current_index)

	if await check_special_tile(active_token):
		return

	# COMPROBACIÓN DE SEGURIDAD: Re-comprobación por si el chequeo especial destruyó la escena
	if not is_instance_valid(active_token) or not active_token.is_inside_tree():
		is_player_moving = false
		return

	is_player_moving = false
	_unlock_dice()
	_next_turn()

func check_special_tile(active_token: Node) -> bool:
	var index: int = active_token.current_index

	if index in MINIGAME_TILE_INDICES:
		await _launch_minigame_for_tile(index)
		is_player_moving = false
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
	card.cpu_mode = is_cpu_turn()
	get_tree().current_scene.add_child(card)
	var result: Array = [false]
	card.answer_result.connect(func(correct: bool):
		result[0] = correct
		if message_label && !correct:
			var nombre := player_names[current_player] if current_player < player_names.size() else "Jugador"
			message_label.visible = true
			message_label.text = "¡%s pierde el siguiente turno!" % nombre
			get_tree().create_timer(5.5).timeout.connect(
				func ():message_label.visible = false)
	)
	await card.tree_exited
	print("GameManager: resultado carta azul =", result[0])
	minigame_active = false
	return result[0]

func show_red_card(active_token: Node) -> void:
	print("GameManager: carta roja activada")
	minigame_active = true
	last_action_type = ""
	var card := ACTION_CARD.instantiate()
	card.cpu_mode = is_cpu_turn()
	get_tree().current_scene.add_child(card)
	var action_result := [last_action_type, 0]
	card.action_completed.connect(func(type: String, value: int) -> void:
		action_result[0] = type
		action_result[1] = value
		print("GameManager: acción guardada:", type, " valor:", value)
	)
	await card.tree_exited
	last_action_type = action_result[0]
	var last_action_value: int = action_result[1]
	await _apply_red_card_action(active_token, last_action_type, last_action_value)

func is_cpu_turn() -> bool:
	return game_mode == 2 and current_player == 1

# =========================================================
# MÉTODOS PRIVADOS
# =========================================================

func _apply_red_card_action(active_token: Node, action: String, value: int) -> void:
	print("GameManager: carta cerrada, acción:", action, " valor:", value)

	if action == "advance":
		await active_token.move_steps(value)
		if await check_special_tile(active_token):
			return

	elif action == "go_back":
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

	elif action == "skip_turn":
		skip_player_index = current_player
		if message_label:
			var nombre := player_names[current_player] if current_player < player_names.size() else "Jugador"
			message_label.visible = true
			message_label.text = "¡%s pierde el siguiente turno!" % nombre
			get_tree().create_timer(5.5).timeout.connect(
				func ():message_label.visible = false)
			

	elif action == "spin_again":
		minigame_active = false
		is_player_moving = false
		_unlock_dice()
		Events.turn_changed.emit(current_player)
		return

	minigame_active = false
	is_player_moving = false
	_unlock_dice()
	_next_turn()

func _launch_minigame_for_tile(tile_index: int) -> void:
	print("GameManager: lanzando minijuego para casilla", tile_index)
	minigame_active = true

	# CPU: omitir minijuego completamente, resultado 50/50
	if is_cpu_turn():
		await get_tree().create_timer(0.8).timeout
		var won_cpu: bool = randi() % 2 == 0
		print("GameManager: CPU minijuego -> resultado automático:", won_cpu)
		minigame_active = false
		await _apply_minigame_effect(tile_index, won_cpu)
		return

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
	
	var minigame_action_dialog = MINIGAME_ACTION_DIALOG.instantiate()
	get_tree().current_scene.add_child(minigame_action_dialog)
	minigame_action_dialog.setup_action(won,effect,current_player)
	var action_result = ["", 0]
	minigame_action_dialog.action_completed.connect(func(type: String, val: int):
		action_result[0] = type
		action_result[1] = val
	)
	
	# CONGELAR LOGICA: Esperamos pacientemente a que el niño cierre la ventana informativa
	await minigame_action_dialog.tree_exited
	
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
		if tile_index == 25:
			await active_token.move_to_alt_path(value)
		else:
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
	var tree := get_tree()
	if tree == null:
		return
		
	var scene := tree.current_scene
	if scene == null:
		return
		
	if scene.has_node("Dado"):
		scene.get_node("Dado").set_locked(false)
		print("GameManager: dado desbloqueado")

func _next_turn() -> void:
	if tokens.is_empty():
		return
	current_player = (current_player + 1) % tokens.size()
	print("GameManager: siguiente turno -> jugador", current_player + 1)
	Events.turn_changed.emit(current_player)
	

func _set_on_pause(notify_pause: bool):
	if notify_pause:
		pausers += 1
	elif pausers > 0:
		pausers -= 1
	
	if pausers > 0:
		get_tree().paused = true
	else:
		get_tree().paused = false

func _set_on_pause_for_minigame(notify_pause: bool):
	if notify_pause:
		pausers += 1
	elif pausers > 0:
		pausers -= 1

	var should_pause: bool = pausers > 0
	var current_scene := get_tree().current_scene
	if current_scene:
		current_scene.process_mode = (
			Node.PROCESS_MODE_DISABLED if should_pause
			else Node.PROCESS_MODE_INHERIT
		)
