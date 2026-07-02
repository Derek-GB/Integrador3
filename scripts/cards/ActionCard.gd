extends CanvasLayer

const CARD_W = 350.0
const CARD_H = 500.0
const CARD_ANIMATOR = preload("res://scripts/cards/CardAnimator.gd")

signal action_completed(type: String, value: int)

@onready var card_container: Control = $CardContainer
@onready var front_side: Panel = $CardContainer/FrontSide
@onready var click_button: Button = $CardContainer/FrontSide/ClickBtn 
@onready var back_panel: Panel = $CardContainer/BackPanel
@onready var back_bg_image: TextureRect = $CardContainer/BackPanel/BackBgImage
@onready var action_button: Button = $CardContainer/BackPanel/ActionButton

var card_animator = CARD_ANIMATOR.new()

var cards = [
	{
		"text": "Con tu familia participaste en la construcción de tu casa en un lugar seguro y respetando las normas y códigos de construcción.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0,
		"background": "res://images/cards/red/card_01.png"
	},
	{
		"text": "En tu comunidad se han tomado medidas preventivas y se ha confeccionado un mapa de riesgo comunal.",
		"action": "¡Avanza 6 casillas!",
		"type": "advance",
		"value": 6,
		"background": "res://images/cards/red/card_02.png"
	},
	{
		"text": "Junto a tu familia has preparado un plan familiar para desastres y estarán preparados en caso de tener que salir de tu casa.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0,
		"background": "res://images/cards/red/card_03.png"
	},
	{
		"text": "En tu comunidad se ha establecido un sistema de alerta temprana que permite prevenir a la gente con tiempo sobre un fenómeno.",
		"action": "¡Avanza 7 casillas!",
		"type": "advance",
		"value": 7,
		"background": "res://images/cards/red/card_04.png"
	},
	{
		"text": "En tu escuela se organizó una campaña para evitar los deslizamientos: los alumnos sembraron 200 arbolitos en una zona de erosión.",
		"action": "¡Avanza 5 casillas!",
		"type": "advance",
		"value": 5,
		"background": "res://images/cards/red/card_05.png"
	},
	{
		"text": "Las inundaciones se pueden evitar botando la basura en los recipientes adecuados, manteniendo limpios los caños y sembrando árboles.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0,
		"background": "res://images/cards/red/card_06.png"
	},
	{
		"text": "Ayudaste en la limpieza del río y así disminuiste el riesgo de inundación en tu comunidad.",
		"action": "¡Avanza 6 casillas!",
		"type": "advance",
		"value": 6,
		"background": "res://images/cards/red/card_07.png"
	},
	{
		"text": "¡Huracán! Estás en la calle y oyes una alarma de huracán. Dirígete inmediatamente al refugio más cercano.",
		"action": "¡Ve a la casilla 33!",
		"type": "go_to_space",
		"value": 33,
		"background": "res://images/cards/red/card_08.png"
	},
	{
		"text": "Si percibes un sismo cuando estás en tu casa, ponte inmediatamente debajo de una mesa o en el marco de una puerta y espera.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0,
		"background": "res://images/cards/red/card_09.png"
	},
	{
		"text": "¡Terremoto! Ponte zapatos durante y después de un terremoto para proteger tus pies de los vidrios.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0,
		"background": "res://images/cards/red/card_10.png"
	},
	{
		"text": "Durante y después de una inundación, bebe solo agua embotellada o hervida. Pierdes un turno para buscar agua potable.",
		"action": "¡Pierdes 1 turno!",
		"type": "skip_turn",
		"value": 0,
		"background": "res://images/cards/red/card_11.png"
	},
	{
		"text": "¡Inundación! No se debe caminar en el agua de la inundación sin zapatos ni medir la profundidad con un palo.",
		"action": "¡Pierdes 1 turno!",
		"type": "skip_turn",
		"value": 0,
		"background": "res://images/cards/red/card_12.png"
	},
	{
		"text": "En tu comunidad se ha organizado un ejercicio de simulacro para terremotos. ¡Ahora la comunidad está mejor preparada!",
		"action": "¡Avanza 7 casillas!",
		"type": "advance",
		"value": 7,
		"background": "res://images/cards/red/card_13.png"
	},
	{
		"text": "Fuiste a la biblioteca y buscaste información sobre prevención de desastres. Aprendiste cómo mantener limpios los cauces de los ríos.",
		"action": "¡Avanza 5 casillas!",
		"type": "advance",
		"value": 5,
		"background": "res://images/cards/red/card_14.png"
	},
	{
		"text": "Los bomberos vinieron a tu escuela y explicaron que nunca debes jugar con fósforos para prevenir incendios.",
		"action": "¡Avanza 3 casillas!",
		"type": "advance",
		"value": 3,
		"background": "res://images/cards/red/card_15.png"
	},
	{
		"text": "Estás participando en la elaboración de un mapa de riesgos de tu comunidad. ¡Felicidades por identificar las amenazas!",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0,
		"background": "res://images/cards/red/card_16.png"
	},
	{
		"text": "Hiciste una fogata sin la ayuda de tus padres o algún adulto.",
		"action": "¡Pierdes 1 turno!",
		"type": "skip_turn",
		"value": 0,
		"background": "res://images/cards/red/card_17.png"
	},
	{
		"text": "Para proteger tu casa de los incendios forestales te deshiciste de la basura, desperdicios y material inflamable a tu alrededor.",
		"action": "¡Avanza 5 casillas!",
		"type": "advance",
		"value": 5,
		"background": "res://images/cards/red/card_18.png"
	},
	{
		"text": "En tu comunidad se cortaron árboles del bosque y no sembraron nuevos. El suelo se reseca, se debilita y erosiona el terreno.",
		"action": "¡Retrocede 3 casillas!",
		"type": "go_back",
		"value": 3,
		"background": "res://images/cards/red/card_19.png"
	},
	{
		"text": "¡Deslizamiento! No intentes cruzar el área afectada. Aléjate del lugar ya que pueden seguir cayendo materiales sobre las zonas cercanas.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0,
		"background": "res://images/cards/red/card_20.png"
	},
	{
		"text": "¡Terremoto! Aléjese de las ventanas y de cualquier objeto que le pueda caer encima.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0,
		"background": "res://images/cards/red/card_21.png"
	},
	{
		"text": "El Fenómeno de El Niño causa sequías e inundaciones en diferentes países. Quédate un turno en el campamento de damnificados ayudando a los niños.",
		"action": "¡Pierdes 1 turno!",
		"type": "skip_turn",
		"value": 0,
		"background": "res://images/cards/red/card_22.png"
	},
	{
		"text": "¡Felicitaciones! Estás participando en la organización y desarrollo de simulaciones y simulacros de inundaciones e incendios en tu escuela.",
		"action": "¡Avanza 3 casillas!",
		"type": "advance",
		"value": 3,
		"background": "res://images/cards/red/card_23.png"
	},
	{
		"text": "Junto a tus amigos y amigas han organizado un comité ambiental para recuperar y proteger la naturaleza.",
		"action": "¡Avanza 3 casillas!",
		"type": "advance",
		"value": 3,
		"background": "res://images/cards/red/card_24.png"
	},
	{
		"text": "En un desastre, la niñez será la primera en recibir socorro y protección. ¡Cuéntales a tus amigos sus derechos!",
		"action": "¡Avanza 3 casillas!",
		"type": "advance",
		"value": 3,
		"background": "res://images/cards/red/card_25.png"
	},
	{
		"text": "La niñez tiene derecho a ser evacuada con su familia, nunca sola.",
		"action": "¡Avanza 1 casilla!",
		"type": "advance",
		"value": 1,
		"background": "res://images/cards/red/card_26.png"
	},
	{
		"text": "La niñez tiene derecho a ser evacuada con su familia, nunca sola.",
		"action": "¡Avanza 1 casilla!",
		"type": "advance",
		"value": 1,
		"background": "res://images/cards/red/card_27.png"
	},
	{
		"text": "En tu escuela respetan los derechos de las personas con discapacidad: han instalado alarmas para alertar tanto a personas ciegas como a sordas.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0,
		"background": "res://images/cards/red/card_28.png"
	},
	{
		"text": "Tu escuela, en coordinación con la comunidad, ha elaborado un plan para funcionar como escuela albergue en situaciones de desastre.",
		"action": "¡Avanza 1 casilla!",
		"type": "advance",
		"value": 1,
		"background": "res://images/cards/red/card_29.png"
	},
	{
		"text": "Las pizarras, muebles, libreros y mobiliario educativo han sido asegurados a las paredes. ¡Excelente medida de prevención!",
		"action": "¡Avanza 2 casillas!",
		"type": "advance",
		"value": 2,
		"background": "res://images/cards/red/card_30.png"
	},
	{
		"text": "Participaste en la reducción de riesgos en tu escuela: reportaste un vidrio roto, recogiste la basura y alertaste que el agua estaba sucia.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0,
		"background": "res://images/cards/red/card_31.png"
	},
	{
		"text": "Se avecina un evento y el plan de seguridad escolar no contempló el uso de la escuela como albergue. Tu escuela debe estar mejor preparada.",
		"action": "¡Pierdes 1 turno!",
		"type": "skip_turn",
		"value": 0,
		"background": "res://images/cards/red/card_32.png"
	},
	{
		"text": "Tu escuela aún no ha construido rampas de acceso, aumentando así la vulnerabilidad de las personas con discapacidad y mayores.",
		"action": "¡Retrocede 1 casilla!",
		"type": "go_back",
		"value": 1,
		"background": "res://images/cards/red/card_33.png"
	},
	{
		"text": "La alcaldía ha decidido autorizar la reconstrucción de la escuela en una zona de inundación. ¡Alerta que la escuela estará en un lugar inseguro!",
		"action": "¡Retrocede 1 casilla!",
		"type": "go_back",
		"value": 1,
		"background": "res://images/cards/red/card_34.png"
	},
	{
		"text": "¡Muy bien! Al evacuar lograste: 1. Atender las instrucciones. 2. Mantener la calma. 3. No gritar, correr o empujar.",
		"action": "¡Avanza 1 casilla!",
		"type": "advance",
		"value": 1,
		"background": "res://images/cards/red/card_35.png"
	},
	{
		"text": "¡Participaste en el simulacro! El simulacro te permite ensayar lo que deberías hacer para poner tu vida a salvo frente a una amenaza.",
		"action": "¡Avanza 1 casilla!",
		"type": "advance",
		"value": 1,
		"background": "res://images/cards/red/card_36.png"
	},
	{
		"text": "En familia, decidieron el punto de encuentro en caso de un desastre. ¡Excelente medida de preparación!",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0,
		"background": "res://images/cards/red/card_37.png"
	},
	{
		"text": "¡Te devolviste a buscar un objeto! Una vez iniciada la evacuación, no debes devolverte por haber puesto tu vida en peligro.",
		"action": "¡Pierdes 1 turno!",
		"type": "skip_turn",
		"value": 0,
		"background": "res://images/cards/red/card_38.png"
	},
	{
		"text": "¡Muy bien! Las rutas de evacuación escogidas tienen iluminación, son seguras y están libres de obstáculos.",
		"action": "¡Avanza 1 casilla!",
		"type": "advance",
		"value": 1,
		"background": "res://images/cards/red/card_39.png"
	},
	{
		"text": "En caso de que tu escuela sufra daños por un desastre, el plan de seguridad escolar dice que se usará otro lugar como escuela.",
		"action": "¡Avanza 2 casillas!",
		"type": "advance",
		"value": 2,
		"background": "res://images/cards/red/card_40.png"
	},
	{
		"text": "Los techos del salón comunal, la escuela y el centro de salud han sido reforzados para que soporten fuertes vientos.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0,
		"background": "res://images/cards/red/card_41.png"
	},
	{
		"text": "Tu escuela se matriculó en la reducción de los desastres: está en terreno seguro, educa a la niñez y actualiza el plan. ¡Nota: 100!",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0,
		"background": "res://images/cards/red/card_42.png"
	},
	{
		"text": "Coopera con el funcionamiento de tu escuela como albergue. Organiza juegos y diviértete junto con la niñez albergada.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0,
		"background": "res://images/cards/red/card_43.png"
	},
	{
		"text": "Mientras tu familia participa en las actividades de reconstrucción, tú vas a la escuela. En la escuela estarás seguro, protegido y alimentado.",
		"action": "¡Avanza 1 casilla!",
		"type": "advance",
		"value": 1,
		"background": "res://images/cards/red/card_44.png"
	},
	{
		"text": "¡Ahorra energía! Apaga las luces cuando no se utilizan, evita el desperdicio y aprovecha la luz solar.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0,
		"background": "res://images/cards/red/card_45.png"
	},
	{
		"text": "Tres formas responsables de usar el agua: cerrar la llave mientras te cepillas, ducharte en el menor tiempo posible y cerrar el grifo cuando gotea.",
		"action": "¡Tira otra vez!",
		"type": "spin_again",
		"value": 0,
		"background": "res://images/cards/red/card_46.png"
	},
	{
		"text": "¡Tiraste la basura al suelo! ¡Pierdes un turno por contaminar!",
		"action": "¡Pierdes 1 turno!",
		"type": "skip_turn",
		"value": 0,
		"background": "res://images/cards/red/card_47.png"
	},
	{
		"text": "Sabías que: 5 árboles absorben a lo largo de su vida aproximadamente 1 tonelada de Dióxido de Carbono (CO2). ¡Siembra un árbol!",
		"action": "¡Avanza 3 casillas!",
		"type": "advance",
		"value": 3,
		"background": "res://images/cards/red/card_48.png"
	}
]

var selected_card = {}
var cpu_mode: bool = false

func _ready():
	randomize()
	_pick_card()
	_setup_card_ui()
	card_animator.animate_entry(card_container,click_button)
	
	click_button.pressed.connect(
		func ():
			card_animator.flip_card(card_container, front_side, back_panel, [click_button,action_button])
			)
			
	action_button.pressed.connect(_on_accepted)
	
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
func _setup_card_ui() -> void:
	if selected_card.has("background") and selected_card["background"] != "":
		back_bg_image.texture = load(selected_card["background"])
	else:
		back_bg_image.texture = load("res://images/cards/bg/default.png")
	

# =========================================================
# ACEPTAR ACCIÓN
# =========================================================
func _on_accepted():
	action_button.disabled = true
	await card_animator.animate_exit(card_container,[action_button])
	action_completed.emit(selected_card["type"], selected_card["value"])
	queue_free()

# =========================================================
# MODO CPU — FLUJO AUTOMÁTICO
# =========================================================
func _cpu_auto_play() -> void:
	await get_tree().create_timer(1.4).timeout
	await card_animator.flip_card(card_container, front_side, back_panel, [click_button,action_button])
	await get_tree().create_timer(1.5).timeout
	_on_accepted()
