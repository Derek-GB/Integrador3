extends CanvasLayer

signal action_completed(action_type: String, value: int)

@onready var result_title: Label = $DialogPanel/ResultTitle
@onready var action_description: Label = $DialogPanel/ActionDescription
@onready var accept_button: Button = $DialogPanel/AcceptButton

var _final_action: String = "nothing"
var _final_value: int = 0

const ACTION_MESSAGES: Dictionary = {
	"advance_single": "¡Excelente! Avanzas 1 casilla en el tablero.",
	"advance_plural": "¡Increíble! Avanzas %d casillas en el tablero.",
	"go_back_single": "Mala suerte. Debes retroceder 1 casilla.",
	"go_back_plural": "Debes retroceder %d casillas.",
	"spin_again":     "¡Qué suerte! Tienes la oportunidad de volver a tirar el dado.",
	"go_to_space":    "¡Genial! Te desplazas directamente a la casilla %d.",
	"nothing":        "No pasa nada en esta ocasión. ¡Sigue adelante!"
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	accept_button.pressed.connect(_on_accept_pressed)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setup_action(did_win: bool, reward_data: Dictionary) -> void:
	var action_key = "on_win" if did_win else "on_lose"
	
	_final_action = reward_data.get(action_key, "nothing")
	_final_value = reward_data.get("value", 0)
	
	if did_win:
		result_title.text = "¡MINIJUEGO SUPERADO!"
		result_title.add_theme_color_override("font_color", Color(0.122, 0.62, 0.145))
	else:
		result_title.text = "¡OH NO!"
		result_title.add_theme_color_override("font_color", Color(0.941, 0.125, 0.125))
	action_description.text = translate_action(_final_action, _final_value)

func translate_action(action: String, value: int) -> String:
	var key := action
	if action == "advance" or action == "go_back":
		key += "_single" if value == 1 else "_plural"
	if not ACTION_MESSAGES.has(key):
		key = "nothing"
	var text_template: String = ACTION_MESSAGES[key]
	if "%d" in text_template:
		return text_template % value
	return text_template

func _on_accept_pressed() -> void:
	# Emitimos los datos limpios para que el script del mapa mueva al jugador
	action_completed.emit(_final_action, _final_value)
	queue_free()
