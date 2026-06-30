extends CanvasLayer

signal answer_result(correct: bool)

var selected_question: Dictionary = {}

# Reemplazamos la creación manual por referencias a la escena
@onready var card_container: Control = $CardContainer
@onready var front_side: Panel = $CardContainer/FrontSide
@onready var _front_info: Label = $CardContainer/FrontSide/FrontInfo
@onready var back_panel: Panel = $CardContainer/BackPanel
@onready var background_image_rect: TextureRect = $CardContainer/BackPanel/BackgroundImageRect
@onready var options_container: VBoxContainer = $CardContainer/BackPanel/OptionsContainer
@onready var click_button: Button = $CardContainer/FrontSide/ClickButton

@onready var feedback_panel: Panel = $FeedbackPanel
@onready var feedback_title: Label = $FeedbackPanel/TitleLabel
@onready var feedback_description: Label = $FeedbackPanel/DescriptionLabel
@onready var playing_button: Button = $FeedbackPanel/PlayingButton

#@onready var cpu_feedback_background: ColorRect = $CardContainer/BackPanel/CpuFeedbackBackground
#@onready var _cpu_feedback_label: Label = $CardContainer/BackPanel/CpuFeedbackBackground/CpuFeedbackLabel

# Mantener variables de CPU ignoradas por ahora
var cpu_mode: bool = false
var _option_buttons: Array = []
var _cpu_feedback_label: Label = null

const CARD_W := 350.0
const CARD_H := 500.0

func _ready() -> void:
	randomize()
	# _build_ui() <-- BORRADO, ya no se necesita crear nada
	_animate_card()
	if cpu_mode:
		_cpu_auto_play()
	if not selected_question.is_empty():
		_apply_card_data()
	click_button.pressed.connect(_flip_card)

func setup(question_data: Dictionary, background_image: String = "") -> void:
	selected_question = {
		"question": question_data["pregunta"],
		"options": question_data["opciones"].map(func(option): return option["texto"]),
		"correct": question_data["respuestaCorrecta"] - 1,
		"explanation": question_data["explicacion"],
		"background": background_image
		}
	# Configurar los elementos dinámicos que dependen de los datos cargados
	if is_node_ready():
		_apply_card_data()

func _apply_card_data() -> void:
	# Cargar imagen dinámica en el reverso
	if selected_question.has("background") and selected_question["background"] != "":
		background_image_rect.texture = load(selected_question["background"])
	else:
		background_image_rect.texture = load("res://images/cards/blue/default_question.png")
	_build_question()

# Tu función _build_question ahora solo spawnea los botones dentro del contenedor visual existente
func _build_question() -> void:
	# Limpiar botones previos si existieran
	for child in options_container.get_children():
		child.queue_free()
	_option_buttons.clear()
	
	for option_index in range(selected_question["options"].size()):
		var option_button := Button.new()
		option_button.text = selected_question["options"][option_index]
		option_button.custom_minimum_size = Vector2(290, 48)
		option_button.add_theme_font_size_override("font_size", 15)
		option_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_adjust_font_size(option_button,selected_question["options"][option_index])
		option_button.pressed.connect(_on_option_selected.bind(option_index))
		options_container.add_child(option_button)
		_option_buttons.append(option_button)
# Las funciones _animate_card(), _flip_card() y _on_option_selected() 
# se quedan EXACTAMENTE IGUAL, ya que manejan lógica y tweens, no construcción.


# =========================================================
# ANIMACIÓN ENTRADA
# =========================================================
func _animate_card() -> void:
	#card_container.scale = Vector2(0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(card_container, "scale", Vector2.ONE, 0.4) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)


# =========================================================
# GIRAR CARTA
# =========================================================
func _flip_card() -> void:
	var tween_out := create_tween()

	tween_out.tween_property(card_container, "scale:x", 0.0, 0.18) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN)

	await tween_out.finished

	front_side.visible = false
	back_panel.visible = true

	var tween_in := create_tween()

	tween_in.tween_property(card_container, "scale:x", 1.0, 0.18) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

	await tween_in.finished


# =========================================================
# RESPUESTA
# =========================================================
func _on_option_selected(option_index: int) -> void:
	
	for button in _option_buttons:
		button.disabled = true
	
	back_panel.visible = false
	
	var is_correct := option_index == int(selected_question["correct"])
	
	if is_correct:
		feedback_title.text = "¡Excelente Trabajo!"
		feedback_title.add_theme_color_override("font_color", Color(0.122, 0.62, 0.145))
	else:
		feedback_title.text = "¡Inténtalo de nuevo!"
		feedback_title.add_theme_color_override("font_color", Color(0.941, 0.125, 0.125))
	
	feedback_description.text = selected_question["explanation"]
	_adjust_font_description(feedback_description,selected_question["explanation"])
	feedback_panel.visible = true
	
	if not playing_button.pressed.is_connected(_on_continuar_pressed.bind(is_correct)):
		playing_button.pressed.connect(_on_continuar_pressed.bind(is_correct))

func _on_continuar_pressed(is_correct: bool) -> void:
	answer_result.emit(is_correct)
	queue_free()


# =========================================================
# MODO CPU — FLUJO AUTOMÁTICO CON FEEDBACK VISUAL
# =========================================================
func _cpu_auto_play() -> void:
	# Paso 1: leyendo en el frente de la carta
	await get_tree().create_timer(1.0).timeout

	if _front_info:
		_front_info.text = "La maquina esta leyendo..."

	# Paso 2: mostrar la pregunta
	await get_tree().create_timer(0.8).timeout
	await _flip_card()

	# Paso 3: pensando
	_set_cpu_status("La maquina esta pensando...", Color.WHITE)

	await get_tree().create_timer(2.0).timeout

	# Paso 4: elegir opción
	var random_option : int = randi() % int(selected_question["options"].size())

	var option_letters : Array = ["A", "B", "C", "D", "E"]

	var selected_letter : String = (
		option_letters[random_option]
		if random_option < option_letters.size()
		else str(random_option + 1)
	)

	_set_cpu_status(
		"La maquina selecciono la opción " + selected_letter,
		Color.YELLOW
	)

	_highlight_cpu_choice(random_option)

	await get_tree().create_timer(1.5).timeout

	# Paso 5: resultado
	var is_correct := random_option == int(selected_question["correct"])

	if is_correct:
		_set_cpu_status("Respuesta correcta ✅", Color("#4CAF50"))
	else:
		_set_cpu_status("Respuesta incorrecta ❌", Color("#F44336"))

	# Paso 6: cerrar
	await get_tree().create_timer(2.2).timeout

	print("QuestionCard: emitting answer_result =", is_correct)

	answer_result.emit(is_correct)
	queue_free()


# =========================================================
# HELPERS CPU
# =========================================================
func _set_cpu_status(status_text: String, status_color: Color = Color.WHITE) -> void:
	if _cpu_feedback_label == null:
		return

	var feedback_background: Node = _cpu_feedback_label.get_parent()

	if feedback_background:
		feedback_background.visible = true

	_cpu_feedback_label.text = status_text
	_cpu_feedback_label.add_theme_color_override("font_color", status_color)


func _highlight_cpu_choice(chosen_index: int) -> void:
	for index in range(_option_buttons.size()):
		var option_button: Button = _option_buttons[index]

		if index == chosen_index:
			var selected_style := StyleBoxFlat.new()

			selected_style.bg_color = Color("#1565C0")
			selected_style.corner_radius_top_left = 6
			selected_style.corner_radius_top_right = 6
			selected_style.corner_radius_bottom_left = 6
			selected_style.corner_radius_bottom_right = 6
			selected_style.border_width_left = 2
			selected_style.border_width_top = 2
			selected_style.border_width_right = 2
			selected_style.border_width_bottom = 2
			selected_style.border_color = Color("#90CAF9")

			option_button.add_theme_stylebox_override("normal", selected_style)
			option_button.add_theme_stylebox_override("hover", selected_style)
			option_button.add_theme_stylebox_override("pressed", selected_style)
			option_button.add_theme_color_override("font_color", Color.WHITE)
		else:
			option_button.modulate = Color(1.0, 1.0, 1.0, 0.35)

func _adjust_font_size(btn: Button, text: String) -> void:
	var long = text.length()
	var font_size := 15 # Tamaño por defecto para textos cortos
	
	# Umbrales basados en la cantidad de caracteres (puedes calibrar estos números)
	if long > 60:
		font_size = 11 # Texto extra largo (ej: más de 3 líneas)
	elif long > 40:
		font_size = 13 # Texto mediano-largo
		
	# Aplicamos el override de tamaño de fuente al botón
	btn.add_theme_font_size_override("font_size", font_size)

## Ajusta el tamaño de la fuente del Label de explicación según su longitud
func _adjust_font_description(label: Label, text: String) -> void:
	var long = text.length()
	var font_size := 18 # Tamaño ideal por defecto para lectura
	
	# Umbrales basados en la cantidad de caracteres para un párrafo
	if long > 160:
		font_size = 12 # Texto masivo (reducimos bastante)
	elif long > 100:
		font_size = 16 # Texto mediano-largo
	label.add_theme_font_size_override("font_size", font_size)
