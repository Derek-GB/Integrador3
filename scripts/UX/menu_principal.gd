extends Control
@onready var boton_jugar_menu = $Menu_Botones/Jugar
@onready var boton_reglas_menu = $Menu_Botones/Reglas
@onready var boton_creditos_menu = $Menu_Botones/Creditos
@onready var boton_salir_menu = $Menu_Botones/Salir
@onready var menu_botones: Control = $Menu_Botones
@onready var seleccion_juego: Control = $Seleccion_Juego
@onready var boton_1vs1 = $"Seleccion_Juego/1vs1"
@onready var boton_1vsbot = $"Seleccion_Juego/1vsbot"
@onready var boton_cerrar_seleccion = $Seleccion_Juego/Cerrar_Seleccion
@onready var reglas_juego: Control = $Reglas_Juego
@onready var boton_cerrar_reglas = $Reglas_Juego/Cerrar_Reglas

const MAIN = preload("res://scenes/main.tscn")

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
	
	boton_reglas_menu.pressed.connect(
		func(): 
			_mover_panel(menu_botones, "position:x", 150.0, 0.6)
			_mover_panel(reglas_juego, "position:x", 910.0, 0.6)
	)
	
	boton_cerrar_reglas.pressed.connect(
		func(): 
			_mover_panel(menu_botones, "position:x", 178.0, 0.6)
			_mover_panel(reglas_juego, "position:x", 3026.0, 0.6)
	)
	
	boton_1vs1.pressed.connect(
		func():
			GameManager.game_mode = 1 #1 para jugador vs jugador y 2 para jugador vs cpu
			get_tree().change_scene_to_packed(
				MAIN
			)
	)
	
	boton_1vsbot.pressed.connect(
		func():
			GameManager.game_mode = 2 #1 para jugador vs jugador y 2 para jugador vs cpu
			get_tree().change_scene_to_packed(
				MAIN
			)
	)
	
	for i in $Menu_Botones.get_children():
		if i is Button:
			conectar_hover(i)

func salir() -> void:
	get_tree().quit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func conectar_hover(boton: Control):
	boton.mouse_entered.connect(resize_up.bind(boton))
	boton.mouse_exited.connect(resize_down.bind(boton))

func resize_up(boton: Control) -> void:
	boton.scale = Vector2(1.05, 1.05)

func resize_down(boton: Control) -> void:
	boton.scale = Vector2.ONE

func _mover_panel(obj: Object,propiedad: NodePath, x : float, duracion: float) -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(obj, propiedad, x, duracion)
