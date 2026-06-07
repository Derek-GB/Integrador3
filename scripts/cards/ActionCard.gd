extends CanvasLayer

const CARD_W = 350.0
const CARD_H = 500.0

signal action_completed(type: String, value: int)

var cards = [
	{
		"text": "Junto a tus amigos y amigas han organizado un comité ambiental para recuperar y proteger la naturaleza. ¡Excelente forma de prevenir futuros desastres!",
		"action": "¡Avanza 3 casillas!",
		"type": "advance",
		"value": 3
	},
	{
		"text": "En un desastre, la niñez será la primera en recibir socorro y protección. Cuéntales a tus amigos y amigas sus derechos.",
		"action": "¡Avanza 3 casillas!",
		"type": "advance",
		"value": 3
	},
	{
		"text": "La niñez tiene derecho a ser evacuada con su familia, nunca sola.",
		"action": "¡Avanza 1 casilla!",
		"type": "advance",
		"value": 1
	},
	{
		"text": "En tu escuela respetan los derechos de las personas con discapacidad: han instalado alarmas para alertar tanto a las personas ciegas como a las sordas.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0
	},
	{
		"text": "Tu escuela, en coordinación con la comunidad, ha elaborado un plan para funcionar como escuela albergue en situaciones de desastre.",
		"action": "¡Avanza 1 casilla!",
		"type": "advance",
		"value": 1
	},
	{
		"text": "¡Excelente medida de prevención! Las pizarras, muebles, libreros y mobiliario educativo han sido asegurados a las paredes.",
		"action": "¡Avanza 2 casillas!",
		"type": "advance",
		"value": 2
	},
	{
		"text": "¡Muy bien! Al evacuar lograste: 1. Atender las instrucciones. 2. Mantener la calma. 3. No gritar, correr o empujar.",
		"action": "¡Avanza 1 casilla!",
		"type": "advance",
		"value": 1
	},
	{
		"text": "Participaste en la reducción de riesgos en tu escuela: reportaste un vidrio roto, recogiste la basura y alertaste que el agua estaba sucia.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0
	},
	{
		"text": "¡Participaste en el simulacro! El simulacro te permite ensayar lo que deberías hacer para poner tu vida a salvo frente a una amenaza.",
		"action": "¡Avanza 1 casilla!",
		"type": "advance",
		"value": 1
	},
	{
		"text": "¡Excelente medida de preparación! En familia, decidieron el punto de encuentro en caso de un desastre.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0
	},
	{
		"text": "¡Muy bien! Las rutas de evacuación escogidas tienen iluminación, son seguras y están libres de obstáculos.",
		"action": "¡Avanza 1 casilla!",
		"type": "advance",
		"value": 1
	},
	{
		"text": "En caso de que tu escuela sufra daños por un desastre, el plan de seguridad escolar indica que se usará otro lugar como escuela. Tu derecho a la educación no se suspende con el desastre.",
		"action": "¡Avanza 2 casillas!",
		"type": "advance",
		"value": 2
	},
	{
		"text": "Los techos del salón comunal, la escuela y el centro de salud han sido reforzados para soportar fuertes vientos.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0
	},
	{
		"text": "Tu escuela se matriculó en la reducción de los desastres: está ubicada en terreno seguro, educa a la niñez en prevención y actualiza el plan con simulacros. ¡Nota: 100!",
		"action": "¡Avanza 3 casillas!",
		"type": "advance",
		"value": 3
	},
	{
		"text": "Cooperas con el funcionamiento de tu escuela como albergue. Organizas juegos y te diviertes junto con la niñez albergada.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0
	},
	{
		"text": "Mientras tu familia participa en las actividades de reconstrucción, tú vas a la escuela. ¡En la escuela estarás seguro(a), protegido(a) y alimentado(a)!",
		"action": "¡Avanza 1 casilla!",
		"type": "advance",
		"value": 1
	},
	{
		"text": "¡Ahorra energía! Apaga las luces cuando no se utilizan, evita el desperdicio y aprovecha la luz solar. ¡Es gratis y saludable!",
		"action": "¡Avanza 2 casillas!",
		"type": "advance",
		"value": 2
	},
	{
		"text": "Sabías que 5 árboles absorben a lo largo de su vida aproximadamente 1 tonelada de CO₂. ¡Siembra un árbol!",
		"action": "¡Avanza 3 casillas!",
		"type": "advance",
		"value": 3
	},
	{
		"text": "Con tu familia participaste en la construcción de tu casa en un lugar seguro y respetando las normas y códigos de construcción.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0
	},
	{
		"text": "En tu comunidad se han tomado medidas preventivas y se ha confeccionado un mapa de riesgo comunal.",
		"action": "¡Avanza 6 casillas!",
		"type": "advance",
		"value": 6
	},
	{
		"text": "Junto a tu familia preparaste un plan familiar para desastres y podrán llevarse rápidamente lo que necesiten para unos días.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0
	},
	{
		"text": "En tu comunidad se ha establecido un sistema de alerta temprana. Con este sistema se puede avisar con tiempo sobre un fenómeno y disminuir daños y muertes.",
		"action": "¡Avanza 7 casillas!",
		"type": "advance",
		"value": 7
	},
	{
		"text": "En tu escuela se organizó una campaña para evitar deslizamientos: los alumnos sembraron 200 arbolitos en una zona de erosión, disminuyendo la vulnerabilidad de esa zona.",
		"action": "¡Avanza 5 casillas!",
		"type": "advance",
		"value": 5
	},
	{
		"text": "Las inundaciones se pueden evitar botando la basura en lugares adecuados, manteniendo limpios los caños y sembrando árboles para mantener el cauce de los ríos.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0
	},
	{
		"text": "Ayudaste en la limpieza del río y disminuiste el riesgo de inundación en tu comunidad.",
		"action": "¡Avanza 6 casillas!",
		"type": "advance",
		"value": 6
	},
	{
		"text": "Si percibes un sismo cuando estás en tu casa, ponte inmediatamente debajo de una mesa resistente o en el marco de una puerta y espera a que pase.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0
	},
	{
		"text": "¡Terremoto! Ponte zapatos durante y después del sismo para proteger tus pies de los vidrios y objetos caídos.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0
	},
	{
		"text": "En tu comunidad se organizó un ejercicio de simulacro para terremotos. ¡Ahora la comunidad está mejor preparada!",
		"action": "¡Avanza 7 casillas!",
		"type": "advance",
		"value": 7
	},
	{
		"text": "Fuiste a la biblioteca y aprendiste que para evitar inundaciones es clave mantener limpios los cauces de los ríos y no botar basura en ellos.",
		"action": "¡Avanza 5 casillas!",
		"type": "advance",
		"value": 5
	},
	{
		"text": "Los bomberos explicaron en tu escuela que nunca debes jugar con fósforos, ni al aire libre ni en casa, para no provocar un incendio peligroso.",
		"action": "¡Avanza 3 casillas!",
		"type": "advance",
		"value": 3
	},
	{
		"text": "Estás participando en la elaboración de un mapa de riesgos de tu comunidad. Aprendiste a identificar cuáles amenazas presentan mayor peligro.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0
	},
	{
		"text": "Para proteger tu casa de los incendios forestales te deshiciste de la basura y del material inflamable que rodea tu casa: pasto, hojas y ramas secas.",
		"action": "¡Avanza 5 casillas!",
		"type": "advance",
		"value": 5
	},
	{
		"text": "¡Felicitaciones! Estás participando en simulaciones y simulacros de inundaciones e incendios en tu escuela.",
		"action": "¡Avanza 3 casillas!",
		"type": "advance",
		"value": 3
	},
	{
		"text": "Se avecina un evento y el plan de seguridad escolar no contempló el uso de la escuela como albergue. Tu escuela debe estar mejor preparada.",
		"action": "Pierdes 1 turno.",
		"type": "skip_turn",
		"value": 1
	},
	{
		"text": "Tu escuela aún no ha construido rampas de acceso, aumentando la vulnerabilidad de las personas con discapacidad y personas mayores.",
		"action": "Retrocede 1 casilla.",
		"type": "go_back",
		"value": 1
	},
	{
		"text": "La alcaldía autorizó la reconstrucción de la escuela en una zona de inundación. ¡Alerta! La escuela estará en un lugar inseguro.",
		"action": "Retrocede 1 casilla.",
		"type": "go_back",
		"value": 1
	},
	{
		"text": "¡Te devolviste a buscar un objeto! Una vez iniciada la evacuación, no debes devolverte. Pusiste tu vida en peligro.",
		"action": "Pierdes 1 turno.",
		"type": "skip_turn",
		"value": 1
	},
	{
		"text": "¡Tiraste la basura al suelo! Contaminar el ambiente aumenta el riesgo de desastres como inundaciones.",
		"action": "Pierdes 1 turno por contaminar.",
		"type": "skip_turn",
		"value": 1
	},
	{
		"text": "¡Huracán! Estás en la calle y oyes una alarma de huracán. Dirígete inmediatamente al refugio más cercano.",
		"action": "Ve a la casilla 33.",
		"type": "go_to_space",
		"value": 33
	},
	{
		"text": "Durante y después de una inundación, bebiste agua sin hervir ni purificar. El agua contaminada puede causarte enfermedades graves.",
		"action": "Pierdes 1 turno buscando agua potable.",
		"type": "skip_turn",
		"value": 1
	},
	{
		"text": "¡Inundación! No se debe caminar en el agua de la inundación sin protección. Si debes hacerlo, usa zapatos y mide la profundidad con un palo.",
		"action": "Pierdes 1 turno.",
		"type": "skip_turn",
		"value": 1
	},
	{
		"text": "Hiciste una fogata sin la ayuda de tus padres o algún adulto. ¡Esto es muy peligroso y puede provocar un incendio!",
		"action": "Pierdes 1 turno.",
		"type": "skip_turn",
		"value": 1
	},
	{
		"text": "En tu comunidad se cortaron árboles del bosque y no sembraron nuevos. Esto causa daño al suelo y erosión en época lluviosa.",
		"action": "Retrocede 3 casillas.",
		"type": "go_back",
		"value": 3
	},
	{
		"text": "¡Deslizamiento! No intentes cruzar el área afectada. Aléjate del lugar ya que pueden seguir cayendo materiales sobre las zonas cercanas.",
		"action": "¡Tira otra vez con cuidado!",
		"type": "spin_again",
		"value": 0
	},
	{
		"text": "¡Terremoto! Aléjate de las ventanas y de cualquier objeto que te pueda caer encima.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0
	},
	{
		"text": "Las sustancias tiradas a los ríos y suelos contaminan fuentes de agua y pueden provocar problemas de salud. ¡Infórmalo en el periódico mural de tu escuela!",
		"action": "Retrocede 3 casillas.",
		"type": "go_back",
		"value": 3
	},
	{
		"text": "El Fenómeno de El Niño es un calentamiento de las aguas tropicales en el océano Pacífico ecuatorial que causa sequías e inundaciones en diferentes países. Quédate en el campamento de damnificados y ayuda a la recreación de los niños más pequeños.",
		"action": "Pierdes 1 turno en el campamento.",
		"type": "skip_turn",
		"value": 1
	},
	{
		"text": "Tres formas responsables de usar el agua: cerrar la llave mientras te cepillas, ducharte en el menor tiempo posible y reparar grifos que gotean. Sin embargo, tu comunidad derrocha agua.",
		"action": "Retrocede 2 casillas.",
		"type": "go_back",
		"value": 2
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
	img.texture = load("res://images/cards/card_action.png")
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

	_build_card_content()

# =========================================================
# CONTENIDO DEL REVERSO
# =========================================================
func _build_card_content():
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 30)
	vbox.size = Vector2(310, 440)
	vbox.add_theme_constant_override("separation", 20)
	back_panel.add_child(vbox)

	var text_label = Label.new()
	text_label.text = selected_card["text"]
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(310, 200)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.add_theme_font_size_override("font_size", 18)
	text_label.add_theme_color_override("font_color", Color("#3B1F00"))
	vbox.add_child(text_label)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	var action_label = Label.new()
	action_label.text = selected_card["action"]
	action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_label.add_theme_font_size_override("font_size", 22)
	action_label.add_theme_color_override("font_color", Color("#8B0000"))
	vbox.add_child(action_label)

	var btn = Button.new()
	btn.text = "Aceptar"
	btn.custom_minimum_size = Vector2(310, 55)
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(_on_accepted)
	vbox.add_child(btn)

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
