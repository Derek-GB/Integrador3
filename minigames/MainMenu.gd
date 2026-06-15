extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_10_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	minigame_data.title        = "¡Desmonta la casa!"
	minigame_data.description  = "Un volcán está por hacer erupción, ¡desmontá la casa antes de que sea tarde!"
	minigame_data.instructions = "Tocá todos los tornillos para desmontar cada pieza de la casa."
	minigame_data.video_path   = "res://minigames/minigame_house/assets/House_Instruction.ogv"
	minigame_data.minigame_scene = "res://minigames/minigame_house/HouseMinigame.tscn"
	minigame_data.controls = [
		{ "action": "Tocar tornillo", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
	]
	var minigame_scene = load("res://minigames/ui_global/MinigameIntro.tscn")
	var minigame: Control = minigame_scene.instantiate()
	get_tree().current_scene.add_child(minigame)
	Events.minigame_intro_started.emit()
#func _on_button_10_pressed() -> void:
	#var minigame_data = get_node("/root/MinigameData")
	#minigame_data.title = "¡Ordena el botiquín!"
	#minigame_data.description = "Ayuda a organizar correctamente los implementos médicos dentro del botiquín."
	#minigame_data.instructions = "Selecciona cada implemento médico y arrástralo hacia su espacio correcto dentro del botiquín antes de que se acabe el tiempo."
	#minigame_data.video_path = "res://minigames/minigame_kit/assets/kit_Instruction.ogv"
	#minigame_data.minigame_scene = "res://minigames/minigame_kit/MedicalKitMinigame.tscn"
	#minigame_data.controls = [
		#{ "action": "Arrastrar implemento", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
	#]
	#var minigame_scene = load("res://minigames/ui_global/MinigameIntro.tscn")
	#var minigame:Control = minigame_scene.instantiate()
	#get_tree().current_scene.add_child(minigame)
	#Events.minigame_intro_started.emit()
	##get_tree().change_scene_to_file("res://minigames/ui_global/MinigameIntro.tscn")

func _on_button_4_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	minigame_data.title        = "¡Desmonta la casa!"
	minigame_data.description  = "Un volcán está por hacer erupción, ¡desmontá la casa antes de que sea tarde!"
	minigame_data.instructions = "Tocá todos los tornillos para desmontar cada pieza de la casa."
	minigame_data.video_path   = "res://minigames/minigame_house/assets/House_Instruction.ogv"
	minigame_data.minigame_scene = "res://minigames/minigame_house/HouseMinigame.tscn"
	minigame_data.controls = [
		{ "action": "Tocar tornillo", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
	]
	get_tree().change_scene_to_file("res://minigames/ui_global/MinigameIntro.tscn")

func _on_button_3_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	minigame_data.title        = "¡Esquiva los rayos!"
	minigame_data.description  = "Te protegiste mientras pasaba la tormenta eléctrica."
	minigame_data.instructions = "Muevete de derecha a izquiera esquivando los rayos"
	minigame_data.video_path   = "res://minigames/minigame_storm/assets/Thunder_Instruction.ogv"
	minigame_data.minigame_scene = "res://minigames/minigame_storm/StormMinigame.tscn"
	minigame_data.controls = [
		{ "action": "Moverse derecha", "icon": "res://minigames/ui_global/assets/left-button.png" },
		{ "action": "Moverse izquierda", "icon": "res://minigames/ui_global/assets/right-button.png" },
	]
	get_tree().change_scene_to_file("res://minigames/ui_global/MinigameIntro.tscn")


func _on_button_2_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	minigame_data.title        = "¡Limpia el río!"
	minigame_data.description  = "Ayuda a limpiar el río"
	minigame_data.instructions = "Selecciona una basura y arrastrala al basurero"
	minigame_data.video_path   = "res://minigames/minigame_river/assets/River_Instruction.ogv"
	minigame_data.minigame_scene = "res://minigames/minigame_river/RiverCleanupMinigame.tscn"
	minigame_data.controls = [
		{ "action": "Arrastrar basura", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
	]
	get_tree().change_scene_to_file("res://minigames/ui_global/MinigameIntro.tscn")



func _on_button_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	minigame_data.title        = "¡Ordena el mapa de riesgo escolar!"
	minigame_data.description  = "Participaste en la elaboración del mapa de riesgo"
	minigame_data.instructions = "Tocá una pieza y despúes toca donde la quieres acomodar, para armar el mapa de riesgo"
	minigame_data.video_path   = "res://minigames/minigame_puzzle/assets/Puzzle_Instruction.ogv"
	minigame_data.minigame_scene = "res://minigames/minigame_puzzle/MapPuzzle.tscn"
	minigame_data.controls = [
		{ "action": "Tocar piezas", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
	]
	get_tree().change_scene_to_file("res://minigames/ui_global/MinigameIntro.tscn")

func _on_button_5_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	minigame_data.title        = "¡Reforesta el bosque!"
	minigame_data.description  = "Tu comunidad deforesto el bosque, ayuda a reforestarlo."
	minigame_data.instructions = "Selecciona una semilla y arrástrala hacia un hoyo bueno. 
	Evita los hoyos malos, porque te quitarán vida si sueltas la semilla sobre ellos. 
	Cuando todas las semillas estén plantadas, usa la regadera para regarlas antes de que se acabe el tiempo."
	minigame_data.video_path   = "res://minigames/minigame_defo/sprites/Tree_instruction2.ogv"
	minigame_data.minigame_scene = "res://minigames/minigame_defo/mini_game.tscn"
	minigame_data.controls = [
		{ "action": "Arrastrar semillas y regadera", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
	]
	get_tree().change_scene_to_file("res://minigames/ui_global/MinigameIntro.tscn")
	
	

func _on_button_26_pressed() -> void:
	get_tree().change_scene_to_file("res://age_selector/age_selector.tscn")

func _on_button_9_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	minigame_data.title = "¡Llega a la zona segura!"
	minigame_data.description = "TERREMOTO, Te metiste debajo de la mesa para protegerte."
	minigame_data.instructions = "Manten presionado el botón rojo cuando ocurra un terromoto para ocultarte debajo de la mesa."
	minigame_data.video_path = "res://minigames/minigame_earthquake/assets/EarthquakeInstructions.ogv"
	minigame_data.minigame_scene = "res://minigames/minigame_earthquake/Main.tscn"
	minigame_data.controls = [
	{ "action": "Manten presionado el botón", "icon": "res://minigames/ui_global/assets/ClickIcon.png" },
]
	get_tree().change_scene_to_file("res://minigames/ui_global/MinigameIntro.tscn")

func _on_button_6_pressed() -> void:
	var minigame_data = get_node("/root/MinigameData")
	minigame_data.title = "¡Rescata a tus amigos!"
	minigame_data.description = "Ayuda a tus amigos a llegar a la zona segura durante la inundación."
	minigame_data.instructions = "Muévete por el laberinto, rescata a los dos amigos y llega a la zona segura antes de que se acabe el tiempo."
	minigame_data.video_path = "res://minigames/minigame_laberinto/assets/maze_Instructions.ogv"
	minigame_data.minigame_scene = "res://minigames/minigame_laberinto/maze_minigame.tscn"
	minigame_data.controls = [
	{ "action": "Moverse arriba", "icon": "res://minigames/ui_global/assets/up-button.png" },
	{ "action": "Moverse abajo", "icon": "res://minigames/ui_global/assets/down-button.png" },
	{ "action": "Moverse izquierda", "icon": "res://minigames/ui_global/assets/left-button.png" },
	{ "action": "Moverse derecha", "icon": "res://minigames/ui_global/assets/right-button.png" },
]
	get_tree().change_scene_to_file("res://minigames/ui_global/MinigameIntro.tscn")
