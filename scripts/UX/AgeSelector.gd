extends Control

# ── Señal que emites al padre cuando el usuario confirma la edad
signal age_selected(age: int)

# ── Referencias a los nodos (ajusta rutas si cambiaste los nombres)
@onready var panda_display: TextureRect = $PandaDisplay
@onready var age_label: Label = $AgeLabel
@onready var stone: TextureButton = $StoneSlider
@onready var bar: TextureRect = $Bar
@onready var step_label: Label = $PlayerStepLabel
@onready var name_input: LineEdit = $NameInput
@onready var color_grid: HBoxContainer = $ColorGrid

# ── Solo 5 imágenes de panda disponibles
var panda_textures: Array[Texture2D] = []

# ── Rangos de edad (6 tramos, pero comparten solo 5 texturas)
# Formato: [edad_minima, edad_maxima]
const AGE_RANGES = [
	[0,  7],    # Tramo1 — <= 7   -> Etapa1
	[8,  8],    # Tramo2 — 8      -> Etapa2
	[9,  9],    # Tramo3 — 9      -> Etapa3
	[10, 10],   # Tramo4 — 10     -> Etapa4
	[11, 11],   # Tramo5 — 11     -> Etapa5
	[12, 99],   # Tramo6 — >= 12  -> Etapa5 (comparte con el tramo anterior)
]

# ── Mapeo de cada tramo a su índice de textura (0..4, solo 5 imágenes)
const STAGE_TO_TEXTURE = [0, 1, 2, 3, 4, 4]

const MIN_AGE = 7    # La barra empieza en 7
const MAX_AGE = 12   # 12 = "12 o más"

# ── Estado interno
var current_age: int = MIN_AGE
var dragging: bool = false
var drag_offset: float = 0.0

# ── Estado de paso para 1Vs1 (paso 0 = Jugador 1, paso 1 = Jugador 2)
var current_step: int = 0

# ── Datos guardados del Jugador 1
var p1_name: String = ""
var p1_color: Color
var p1_color_index: int = 0
var p1_age: int = MIN_AGE

# ── Estado de selección de colores
var selected_color_index: int = 0
var color_buttons: Array[Button] = []

func _ready() -> void:
	# Cargar las 5 texturas
	panda_textures = [
		load("res://images/UX/Etapa1.png"),
		load("res://images/UX/Etapa2.png"),
		load("res://images/UX/Etapa3.png"),
		load("res://images/UX/Etapa4.png"),
		load("res://images/UX/Etapa5.png"),
	]
	
	# Conectar señales del botón Continuar
	$BtnContinuar.pressed.connect(_on_continuar_pressed)
	_setup_step(0)

# ────────────────────────────────────────────
#  CONFIGURACIÓN DE CADA PASO DE SELECCIÓN
# ────────────────────────────────────────────
func _setup_step(step: int) -> void:
	current_step = step
	_update_display(MIN_AGE)
	
	# Restablecer la posición de la piedra slider al mínimo
	stone.global_position.x = bar.global_position.x
	
	if step == 0:
		step_label.text = "DATOS DEL JUGADOR 1"
		name_input.text = "Jugador 1"
		selected_color_index = 0
	else:
		step_label.text = "DATOS DEL JUGADOR 2"
		name_input.text = "Jugador 2"
		if p1_color_index == 1:
			selected_color_index = 0
		else:
			selected_color_index = 1
			
	_build_color_swatches()

func _build_color_swatches() -> void:
	for child in color_grid.get_children():
		child.queue_free()
	color_buttons.clear()
	var palette = GameManager.COLOR_PALETTE
	for i in range(palette.size()):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(70, 70)
		btn.focus_mode = Control.FOCUS_NONE
		
		var is_taken = (current_step == 1 and i == p1_color_index)
		btn.disabled = is_taken
		
		_apply_button_style(btn, palette[i], i == selected_color_index, is_taken)
		
		var idx = i
		btn.pressed.connect(func(): _on_color_button_pressed(idx))
		
		color_grid.add_child(btn)
		color_buttons.append(btn)

func _apply_button_style(btn: Button, color: Color, is_selected: bool, is_disabled: bool) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 35
	style.corner_radius_top_right = 35
	style.corner_radius_bottom_left = 35
	style.corner_radius_bottom_right = 35
	
	if is_disabled:
		style.bg_color.a = 0.2
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = Color(0.3, 0.3, 0.3, 0.4)
	elif is_selected:
		style.border_width_left = 6
		style.border_width_top = 6
		style.border_width_right = 6
		style.border_width_bottom = 6
		style.border_color = Color(1.0, 1.0, 1.0, 1.0)
	else:
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.1, 0.1, 0.1, 0.5)
		
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("disabled", style)

func _on_color_button_pressed(idx: int) -> void:
	selected_color_index = idx
	var palette = GameManager.COLOR_PALETTE
	for i in range(color_buttons.size()):
		var is_taken = (current_step == 1 and i == p1_color_index)
		_apply_button_style(color_buttons[i], palette[i], i == selected_color_index, is_taken)

func _on_continuar_pressed() -> void:
	var current_name = name_input.text.strip_edges()
	if current_name.is_empty():
		current_name = "Jugador 1" if current_step == 0 else "Jugador 2"
		
	var current_color = GameManager.COLOR_PALETTE[selected_color_index]
	
	if current_step == 0:
		p1_name = current_name
		p1_color = current_color
		p1_color_index = selected_color_index
		p1_age = current_age
		
		if GameManager.game_mode == 1:
			_setup_step(1)
		else:
			var bot_color_index = 1
			if p1_color_index == 1:
				bot_color_index = 0
			var bot_color = GameManager.COLOR_PALETTE[bot_color_index]
			
			# Guardar la edad seleccionada en el Autoload MinigameData
			MinigameData.player_age = p1_age
			GameManager.player_names = [p1_name, "Contrincante"]
			GameManager.player_colors = [p1_color, bot_color]
			
			emit_signal("age_selected", p1_age)
			print("AgeSelector (1VsBot): J1 =", p1_name, ", Bot = Contrincante, edad =", p1_age)
			# Cargar el tablero principal
			get_tree().change_scene_to_file("res://scenes/core/Main.tscn")
	else:
		var p2_name = current_name
		var p2_color = current_color
		var p2_age = current_age
		
		# Guardar la EDAD MAYOR entre ambos jugadores en MinigameData
		var max_age = max(p1_age, p2_age)
		MinigameData.player_age = max_age
		GameManager.player_names = [p1_name, p2_name]
		GameManager.player_colors = [p1_color, p2_color]
		
		emit_signal("age_selected", max_age)
		print("AgeSelector (1Vs1): J1 =", p1_name, ", J2 =", p2_name, ", edad máxima =", max_age)
		# Cargar el tablero principal
		get_tree().change_scene_to_file("res://scenes/core/Main.tscn")

# ────────────────────────────────────────────
#  LÓGICA DE ARRASTRE DE LA PIEDRA
# ────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _is_over_stone(event.position):
				dragging = true
				drag_offset = event.position.x - stone.global_position.x
			else:
				dragging = false
	if event is InputEventMouseMotion and dragging:
		_move_stone(event.position.x - drag_offset)

func _is_over_stone(pos: Vector2) -> bool:
	# El tamaño visual real de la piedra incluye su escala
	var stone_size := stone.size * stone.scale
	var rect = Rect2(stone.global_position, stone_size)
	return rect.has_point(pos)

func _move_stone(target_x: float) -> void:
	# Anchos visuales reales (tamaño local * escala), no el tamaño sin escalar
	var bar_width_visual: float   = bar.size.x * bar.scale.x
	var stone_width_visual: float = stone.size.x * stone.scale.x

	# Límites de la barra (en coordenadas globales)
	var bar_left: float  = bar.global_position.x
	var bar_right: float = bar.global_position.x + bar_width_visual - stone_width_visual
	
	# Clampear dentro de la barra
	var new_x = clamp(target_x, bar_left, bar_right)
	stone.global_position.x = new_x
	
	# Convertir posición a edad (rango 7 a 12)
	var t = (new_x - bar_left) / (bar_right - bar_left)  # 0.0 … 1.0
	var age = int(round(lerp(float(MIN_AGE), float(MAX_AGE), t)))
	_update_display(age)

# ────────────────────────────────────────────
#  ACTUALIZAR LABEL Y PANDA
# ────────────────────────────────────────────
func _update_display(age: int) -> void:
	current_age = age
	if age >= MAX_AGE:
		age_label.text = str(MAX_AGE) + "+"
	elif age <= MIN_AGE:
		age_label.text = str(MIN_AGE) + "-"
	else:
		age_label.text = str(age)
	
	var stage := _get_stage(age)
	panda_display.texture = panda_textures[STAGE_TO_TEXTURE[stage]]

func _get_stage(age: int) -> int:
	for i in range(AGE_RANGES.size()):
		if age >= AGE_RANGES[i][0] and age <= AGE_RANGES[i][1]:
			return i
	return AGE_RANGES.size() - 1  # fallback: último tramo
