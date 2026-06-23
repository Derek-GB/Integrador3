extends CanvasLayer

signal answer_result(correct: bool)

var selected_question: Dictionary = {}
var card_container: Control
var front_side: Control
var back_panel: Control
var cpu_mode: bool = false

var _option_buttons: Array = []
var _cpu_feedback_label: Label = null
var _front_info: Label = null

# Tamaño fijo de la carta
const CARD_W := 350.0
const CARD_H := 500.0

func _ready() -> void:
	randomize()
	_build_ui()
	_animate_card()

	if cpu_mode:
		_cpu_auto_play()


# =========================================================
# UNA SOLA PREGUNTA AL AZAR
# =========================================================
func setup(question_data: Dictionary, background_image: String = "") -> void:
	# Convertir formato JSON → formato interno de la carta
	selected_question = {
		"question": question_data["pregunta"],
		"options": question_data["opciones"].map(func(option): return option["texto"]),
		"correct": question_data["respuestaCorrecta"] - 1, # JSON usa 1-based, aquí 0-based
		"explanation": question_data["explicacion"],
		"background": background_image
	}


# =========================================================
# UI
# =========================================================
func _build_ui() -> void:
	# FONDO OSCURO COMPLETO
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# CARTA — centrada con anchors
	card_container = Control.new()
	card_container.set_anchors_preset(Control.PRESET_CENTER)
	card_container.size = Vector2(CARD_W, CARD_H)
	card_container.position = Vector2(-CARD_W / 2.0, -CARD_H / 2.0)
	card_container.pivot_offset = Vector2(CARD_W / 2.0, CARD_H / 2.0)
	add_child(card_container)

	# =========================================================
	# FRENTE — fondo azul + imagen centrada encima
	# =========================================================
	front_side = Panel.new()
	front_side.size = Vector2(CARD_W, CARD_H)
	front_side.position = Vector2.ZERO
	card_container.add_child(front_side)

	var front_style := StyleBoxFlat.new()
	front_style.bg_color = Color("#4a5f7a")
	front_style.corner_radius_top_left = 20
	front_style.corner_radius_top_right = 20
	front_style.corner_radius_bottom_left = 20
	front_style.corner_radius_bottom_right = 20
	front_style.border_width_left = 4
	front_style.border_width_top = 4
	front_style.border_width_right = 4
	front_style.border_width_bottom = 4
	front_style.border_color = Color("#FFD700")

	front_side.add_theme_stylebox_override("panel", front_style)

	# Imagen centrada dentro del fondo
	var card_image := TextureRect.new()
	card_image.texture = load("res://images/cards/blue/card_back.png")
	card_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_image.size = Vector2(CARD_W, CARD_H)
	card_image.position = Vector2.ZERO
	front_side.add_child(card_image)

	_front_info = Label.new()
	_front_info.text = "Press to flip"
	_front_info.position = Vector2(0, 460)
	_front_info.size = Vector2(CARD_W, 40)
	_front_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_front_info.add_theme_font_size_override("font_size", 18)
	_front_info.add_theme_color_override("font_color", Color.YELLOW)
	front_side.add_child(_front_info)

	var click_button := Button.new()
	click_button.flat = true
	click_button.size = Vector2(CARD_W, CARD_H)
	click_button.position = Vector2.ZERO
	click_button.pressed.connect(_flip_card)
	front_side.add_child(click_button)

	# =========================================================
	# REVERSO — mismo tamaño, fondo crema
	# =========================================================
	back_panel = Panel.new()
	back_panel.visible = false
	back_panel.size = Vector2(CARD_W, CARD_H)
	back_panel.position = Vector2.ZERO
	card_container.add_child(back_panel)

	var back_style := StyleBoxFlat.new()
	back_style.bg_color = Color("#F4E7C5")
	back_style.corner_radius_top_left = 20
	back_style.corner_radius_top_right = 20
	back_style.corner_radius_bottom_left = 20
	back_style.corner_radius_bottom_right = 20
	back_style.border_width_left = 4
	back_style.border_width_top = 4
	back_style.border_width_right = 4
	back_style.border_width_bottom = 4
	back_style.border_color = Color("#7A4E1D")

	back_panel.add_theme_stylebox_override("panel", back_style)

	# =========================================================
	# IMAGEN DE FONDO CON LA PREGUNTA
	# =========================================================
	var background_image_rect := TextureRect.new()

	if selected_question.has("background") and selected_question["background"] != "":
		print("Loading image: ", selected_question["background"])
		background_image_rect.texture = load(selected_question["background"])
	else:
		print("Using default image")
		background_image_rect.texture = load("res://images/cards/blue/default_question.png")

	background_image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	background_image_rect.size = Vector2(CARD_W, CARD_H)
	background_image_rect.position = Vector2.ZERO
	back_panel.add_child(background_image_rect)

	_build_question()

	# Barra de estado para el CPU — renderiza encima del contenido
	var feedback_background := ColorRect.new()
	feedback_background.color = Color(0.04, 0.04, 0.12, 0.90)
	feedback_background.position = Vector2(0, CARD_H - 66)
	feedback_background.size = Vector2(CARD_W, 66)
	feedback_background.visible = false
	feedback_background.name = "_cpu_feedback_background"

	back_panel.add_child(feedback_background)

	_cpu_feedback_label = Label.new()
	_cpu_feedback_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cpu_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cpu_feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cpu_feedback_label.add_theme_font_size_override("font_size", 15)
	_cpu_feedback_label.add_theme_color_override("font_color", Color.WHITE)
	_cpu_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	feedback_background.add_child(_cpu_feedback_label)


# =========================================================
# PREGUNTA EN EL REVERSO
# =========================================================
func _build_question() -> void:
	var options_container := VBoxContainer.new()
	options_container.position = Vector2(30, 290)
	options_container.size = Vector2(290, 190)
	options_container.add_theme_constant_override("separation", 8)

	back_panel.add_child(options_container)

	_option_buttons.clear()

	for option_index in range(selected_question["options"].size()):
		var option_button := Button.new()
		option_button.text = selected_question["options"][option_index]
		option_button.custom_minimum_size = Vector2(290, 48)
		option_button.add_theme_font_size_override("font_size", 15)
		option_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		option_button.pressed.connect(_on_option_selected.bind(option_index))

		options_container.add_child(option_button)
		_option_buttons.append(option_button)


# =========================================================
# ANIMACIÓN ENTRADA
# =========================================================
func _animate_card() -> void:
	card_container.scale = Vector2(0.3, 0.3)

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
	var is_correct := option_index == int(selected_question["correct"])

	print("QuestionCard: correct answer =", is_correct)

	var popup := AcceptDialog.new()

	if is_correct:
		popup.title = "Correct! ✅"
	else:
		popup.title = "Incorrect ❌"

	popup.dialog_text = selected_question["explanation"]

	var no_close_icon := PlaceholderTexture2D.new()
	no_close_icon.size = Vector2.ZERO
	popup.add_theme_icon_override("close", no_close_icon)
	popup.add_theme_icon_override("close_pressed", no_close_icon)

	add_child(popup)
	popup.popup_centered()

	await popup.confirmed

	print("QuestionCard: emitting answer_result =", is_correct)

	answer_result.emit(is_correct)
	queue_free()


# =========================================================
# MODO CPU — FLUJO AUTOMÁTICO CON FEEDBACK VISUAL
# =========================================================
func _cpu_auto_play() -> void:
	# Paso 1: leyendo en el frente de la carta
	await get_tree().create_timer(1.0).timeout

	if _front_info:
		_front_info.text = "The machine is reading..."

	# Paso 2: mostrar la pregunta
	await get_tree().create_timer(0.8).timeout
	await _flip_card()

	# Paso 3: pensando
	_set_cpu_status("The machine is thinking...", Color.WHITE)

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
		"The machine selected option " + selected_letter,
		Color.YELLOW
	)

	_highlight_cpu_choice(random_option)

	await get_tree().create_timer(1.5).timeout

	# Paso 5: resultado
	var is_correct := random_option == int(selected_question["correct"])

	if is_correct:
		_set_cpu_status("Correct answer ✅", Color("#4CAF50"))
	else:
		_set_cpu_status("Incorrect answer ❌", Color("#F44336"))

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
