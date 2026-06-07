extends Control
@onready var boton_jugar_menu = $Menu_Botones/Jugar
@onready var boton_reglas_menu = $Menu_Botones/Reglas
@onready var boton_creditos_menu = $Menu_Botones/Creditos
@onready var boton_salir_menu = $Menu_Botones/Salir
@onready var menu_botones: Control = $Menu_Botones
@onready var seleccion_juego: Control = $Seleccion_Juego
@onready var boton_cerrar_seleccion = $Seleccion_Juego/Cerrar_Seleccion

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	boton_salir_menu.pressed.connect (
		salir
	)
	
	boton_jugar_menu.pressed.connect(
		func(): 
			_mover_panel(menu_botones, "position:x", 150.0, 0.6)
			_mover_panel(seleccion_juego, "position:x", 910.0, 0.6)
	)
	
	boton_cerrar_seleccion.pressed.connect(
		func(): 
			_mover_panel(menu_botones, "position:x", 178.0, 0.6)
			_mover_panel(seleccion_juego, "position:x", 2000.0, 0.6)
	)

func salir() -> void:
	get_tree().quit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _mover_panel(obj: Object,propiedad: NodePath, x : float, duracion: float) -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(obj, propiedad, x, duracion)
