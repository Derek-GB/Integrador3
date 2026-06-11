extends CanvasLayer

const CARD_W = 350.0
const CARD_H = 500.0

signal action_completed(type: String, value: int)

var cards = [
	
	{
		"text": "Con tu familia participaste en la construcción de tu casa en un lugar seguro y respetando las normas y códigos de construcción.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0,
		"background": "res://images/cards/red/card_19.png" 
	}
]

var selected_card = {}
var card_container: Control
var front_side: Control
var back_panel: Control
var cpu_mode: bool = false

func _ready():
	randomize()
	_pick_card()
	_build_ui()
	_animate_card()
	if cpu_mode:
		_cpu_auto_play()

# =========================================================
# UNA SOLA CARTA AL AZAR
# =========================================================
func _pick_card():
	var index = randi() % cards.size()
	selected_card = cards[index]
	print("Carta seleccionada:", selected_card["action"])

# =========================================================
# UI
# =========================================================
func _build_ui():
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	card_container = Control.new()
	card_container.set_anchors_preset(Control.PRESET_CENTER)
	card_container.size = Vector2(CARD_W, CARD_H)
	card_container.position = Vector2(-CARD_W / 2.0, -CARD_H / 2.0)
	card_container.pivot_offset = Vector2(CARD_W / 2.0, CARD_H / 2.0)
	add_child(card_container)

	# =========================================================
	# FRENTE — IMAGEN card_action.png
	# =========================================================
	front_side = Panel.new()
	front_side.size = Vector2(CARD_W, CARD_H)
	front_side.position = Vector2(0, 0)
	card_container.add_child(front_side)

	var front_style = StyleBoxFlat.new()
	front_style.bg_color = Color("#D32F2F")
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

	var img = TextureRect.new()
	img.texture = load("res://images/cards/red/card_action.png")
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.size = Vector2(CARD_W, CARD_H)
	img.position = Vector2(0, 0)
	front_side.add_child(img)

	var front_info = Label.new()
	front_info.text = "Presiona para ver tu acción"
	front_info.position = Vector2(40, 460)
	front_info.add_theme_font_size_override("font_size", 18)
	front_info.add_theme_color_override("font_color", Color.YELLOW)
	front_side.add_child(front_info)

	var click_btn = Button.new()
	click_btn.flat = true
	click_btn.size = Vector2(CARD_W, CARD_H)
	click_btn.position = Vector2(0, 0)
	click_btn.pressed.connect(_flip_card)
	front_side.add_child(click_btn)

	# =========================================================
	# REVERSO — ACCIÓN
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
	
	
# =========================================================
#  AGREGAR IMAGEN DE FONDO DINÁMICA
# =========================================================
	var back_bg_image = TextureRect.new()
	# Verificar si la carta tiene imagen de fondo personalizada
	if selected_card.has("background") and selected_card["background"] != "":
		back_bg_image.texture = load(selected_card["background"])
	else:
	# Imagen por defecto si no tiene
		back_bg_image.texture = load("res://images/cards/bg/default.png")

	back_bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	back_bg_image.size = Vector2(CARD_W, CARD_H)
	back_bg_image.position = Vector2(0, 0)
	back_panel.add_child(back_bg_image)
	

	_build_card_content()

# =========================================================
# CONTENIDO DEL REVERSO
# =========================================================
func _build_card_content():
	# Definimos un tamaño más pequeño para el botón
	var btn_width = 200.0
	var btn_height = 45.0
	
	var btn = Button.new()
	btn.text = "Aceptar"
	btn.size = Vector2(btn_width, btn_height)
	
	# Lo centramos horizontalmente y lo dejamos abajo
	var x_pos = (CARD_W - btn_width) / 2.0
	btn.position = Vector2(x_pos, CARD_H - 70)
	
	# Reducimos un poco el tamaño de la letra para que combine
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(_on_accepted)
	back_panel.add_child(btn)

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
# ACEPTAR ACCIÓN
# =========================================================
func _on_accepted():
	action_completed.emit(selected_card["type"], selected_card["value"])
	queue_free()

# =========================================================
# MODO CPU — FLUJO AUTOMÁTICO
# =========================================================
func _cpu_auto_play() -> void:
	await get_tree().create_timer(1.4).timeout
	await _flip_card()
	await get_tree().create_timer(1.5).timeout
	_on_accepted()
