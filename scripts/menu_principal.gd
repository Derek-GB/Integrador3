extends Control
@onready var boton_jugar_menu = $Menu_Botones/Jugar
@onready var boton_reglas_menu = $Menu_Botones/Reglas
@onready var boton_creditos_menu = $Menu_Botones/Creditos
@onready var boton_salir_menu = $Menu_Botones/Salir
@onready var menu_botones: Control = $Menu_Botones
@onready var seleccion_juego: Control = $Seleccion_Juego

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	boton_salir_menu.pressed.connect (
		salir
	)
	boton_jugar_menu.pressed.connect(
		_on_jugar_pressed
	)

func salir() -> void:
	get_tree().quit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_jugar_pressed() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(menu_botones, "position:x", 100.0, 0.6)
	tween.tween_property(seleccion_juego, "position:x", 650.0, 0.6)
