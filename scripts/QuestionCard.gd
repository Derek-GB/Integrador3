extends CanvasLayer

signal answer_result(correct: bool)

var selected_question = {}
var card_container: Control
var front_side: Control
var back_panel: Control
var cpu_mode: bool = false

var _option_buttons: Array = []
var _cpu_feedback_label: Label = null
var _front_info: Label = null

# Tamaño fijo de la carta
const CARD_W = 350.0
const CARD_H = 500.0

func _ready():
	randomize()
	_build_ui()
	_animate_card()
	if cpu_mode:
		_cpu_auto_play()

# =========================================================
# UNA SOLA PREGUNTA AL AZAR
# =========================================================

func setup(pregunta: Dictionary) -> void:
	# Convertir formato JSON → formato interno de la carta
	selected_question = {
		"question": pregunta["pregunta"],
		"options": pregunta["opciones"].map(func(o): return o["texto"]),
		"correct": pregunta["respuestaCorrecta"] - 1,  # JSON usa 1-based, aquí 0-based
		"explanation": pregunta["explicacion"]
	}

# =========================================================
# UI
# =========================================================
func _build_ui():
	# FONDO OSCURO COMPLETO
	var overlay = ColorRect.new()
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
	# FRENTE — fondo verde + imagen centrada encima
	# =========================================================
	front_side = Panel.new()
	front_side.size = Vector2(CARD_W, CARD_H)
	front_side.position = Vector2(0, 0)
	card_container.add_child(front_side)

	var front_style = StyleBoxFlat.new()
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
	var img = TextureRect.new()
	img.texture = load("res://images/card_back.png")
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.size = Vector2(CARD_W, CARD_H)
	img.position = Vector2(0, 0)
	front_side.add_child(img)

	_front_info = Label.new()
	_front_info.text = "Presiona para girar"
	_front_info.position = Vector2(60, 460)
	_front_info.add_theme_font_size_override("font_size", 18)
	_front_info.add_theme_color_override("font_color", Color.YELLOW)
	front_side.add_child(_front_info)

	var click_btn = Button.new()
	click_btn.flat = true
	click_btn.size = Vector2(CARD_W, CARD_H)
	click_btn.position = Vector2(0, 0)
	click_btn.pressed.connect(_flip_card)
	front_side.add_child(click_btn)

	# =========================================================
	# REVERSO — mismo tamaño, fondo crema
	# =========================================================
	back_panel = Panel.new()
	back_panel.visible = false
	back_panel.size = Vector2(CARD_W, CARD_H)
	back_panel.position = Vector2(0, 0)
	card_container.add_child(back_panel)

	var back_style = StyleBoxFlat.new()
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

	_build_question()

	# Barra de estado para el CPU — renderiza encima del contenido de back_panel
	var fb_bg := ColorRect.new()
	fb_bg.color = Color(0.04, 0.04, 0.12, 0.90)
	fb_bg.position = Vector2(0, CARD_H - 66)
	fb_bg.size = Vector2(CARD_W, 66)
	fb_bg.visible = false
	fb_bg.name = "_cpu_fb_bg"
	back_panel.add_child(fb_bg)

	_cpu_feedback_label = Label.new()
	_cpu_feedback_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cpu_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cpu_feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cpu_feedback_label.add_theme_font_size_override("font_size", 15)
	_cpu_feedback_label.add_theme_color_override("font_color", Color.WHITE)
	_cpu_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fb_bg.add_child(_cpu_feedback_label)

# =========================================================
# PREGUNTA EN EL REVERSO
# =========================================================
func _build_question():
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	vbox.size = Vector2(310, 460)
	back_panel.add_child(vbox)

	var question = Label.new()
	question.text = selected_question["question"]
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question.custom_minimum_size = Vector2(310, 80)
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question.add_theme_font_size_override("font_size", 20)
	question.add_theme_color_override("font_color", Color("#3B1F00"))
	vbox.add_child(question)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	_option_buttons.clear()
	for i in range(selected_question["options"].size()):
		var btn = Button.new()
		btn.text = selected_question["options"][i]
		btn.custom_minimum_size = Vector2(310, 65)
		btn.add_theme_font_size_override("font_size", 18)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_option_selected.bind(i))
		vbox.add_child(btn)
		_option_buttons.append(btn)

# =========================================================
# ANIMACIÓN ENTRADA
# =========================================================
func _animate_card():
	card_container.scale = Vector2(0.3, 0.3)
	var tween = create_tween()
	tween.tween_property(card_container, "scale", Vector2.ONE, 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

# =========================================================
# GIRAR CARTA
# =========================================================
func _flip_card():
	var tween1 = create_tween()
	tween1.tween_property(card_container, "scale:x", 0.0, 0.18)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
	await tween1.finished

	front_side.visible = false
	back_panel.visible = true

	var tween2 = create_tween()
	tween2.tween_property(card_container, "scale:x", 1.0, 0.18)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	await tween2.finished

# =========================================================
# RESPUESTA
# =========================================================
func _on_option_selected(option_index: int) -> void:
	var is_correct: bool = (option_index == int(selected_question["correct"]))
	print("QuestionCard: respuesta correcta =", is_correct)
	var popup = AcceptDialog.new()
	if is_correct:
		popup.title = "¡Correcto! ✅"
	else:
		popup.title = "Incorrecto ❌"
	popup.dialog_text = selected_question["explanation"]
	add_child(popup)
	popup.popup_centered()

	await popup.confirmed

	print("QuestionCard: emitiendo answer_result =", is_correct)
	answer_result.emit(is_correct)
	queue_free()

# =========================================================
# MODO CPU — FLUJO AUTOMÁTICO CON FEEDBACK VISUAL
# =========================================================
func _cpu_auto_play() -> void:
	# Paso 1: "leyendo" en el frente de la carta
	await get_tree().create_timer(1.0).timeout
	if _front_info:
		_front_info.text = "La maquina esta leyendo..."

	# Paso 2: girar para mostrar la pregunta
	await get_tree().create_timer(0.8).timeout
	await _flip_card()

	# Paso 3: mostrar "pensando" mientras evalúa opciones
	_set_cpu_status("La maquina esta pensando...", Color.WHITE)
	await get_tree().create_timer(2.0).timeout

	# Paso 4: elegir opción aleatoria y resaltarla
	var random_option: int = randi() % int(selected_question["options"].size())
	var letters: Array = ["A", "B", "C", "D", "E"]
	var letter: String = letters[random_option] if random_option < letters.size() else str(random_option + 1)
	_set_cpu_status("La maquina eligio: opcion " + letter, Color.YELLOW)
	_highlight_cpu_choice(random_option)
	await get_tree().create_timer(1.5).timeout

	# Paso 5: mostrar si fue correcta o incorrecta
	var is_correct: bool = (random_option == int(selected_question["correct"]))
	if is_correct:
		_set_cpu_status("Respuesta correcta ✅", Color("#4CAF50"))
	else:
		_set_cpu_status("Respuesta incorrecta ❌", Color("#F44336"))

	# Paso 6: esperar y cerrar
	await get_tree().create_timer(2.2).timeout
	print("QuestionCard: emitiendo answer_result =", is_correct)
	answer_result.emit(is_correct)
	queue_free()

# =========================================================
# HELPERS CPU
# =========================================================
func _set_cpu_status(text: String, color: Color = Color.WHITE) -> void:
	if _cpu_feedback_label == null:
		return
	var fb_bg: Node = _cpu_feedback_label.get_parent()
	if fb_bg:
		fb_bg.visible = true
	_cpu_feedback_label.text = text
	_cpu_feedback_label.add_theme_color_override("font_color", color)

func _highlight_cpu_choice(chosen: int) -> void:
	for i in _option_buttons.size():
		var btn: Button = _option_buttons[i]
		if i == chosen:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("#1565C0")
			style.corner_radius_top_left = 6
			style.corner_radius_top_right = 6
			style.corner_radius_bottom_left = 6
			style.corner_radius_bottom_right = 6
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.border_color = Color("#90CAF9")
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
			btn.add_theme_stylebox_override("pressed", style)
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			btn.modulate = Color(1.0, 1.0, 1.0, 0.35)
