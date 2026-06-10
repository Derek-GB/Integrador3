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
@onready var lobby1 = $lobby1

const MAIN = preload("res://scenes/main.tscn")
const POS_CENTRO = 910.0
const POS_FUERA_DER = 2000.0
const BOTONES_HOME = 178.0
const BOTONES_LATERAL = 150.0
const DURACION = 1.3
var menu_activo: Control = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	lobby1.play()

	boton_salir_menu.pressed.connect (
		salir
	)

	boton_jugar_menu.pressed.connect(
		func(): 
			abrir_menu(seleccion_juego)
	)

	boton_cerrar_seleccion.pressed.connect(
		func(): 
			cerrar_todo()
	)

	boton_reglas_menu.pressed.connect(
		func(): 
			abrir_menu(reglas_juego)
	)

	boton_cerrar_reglas.pressed.connect(
		func(): 
			cerrar_todo()
	)

	boton_1vs1.pressed.connect(
		func():
			GameManager.game_mode = 1
			get_tree().change_scene_to_packed(MAIN)
	)

	boton_1vsbot.pressed.connect(
		func():
			GameManager.game_mode = 2
			get_tree().change_scene_to_packed(MAIN)
	)

	for i in $Menu_Botones.get_children():
		if i is Button:
			conectar_hover(i)
			i.pivot_offset = i.position

func salir() -> void:
	get_tree().quit()

func conectar_hover(boton: Control) -> void:
	boton.mouse_entered.connect(resize_up.bind(boton))
	boton.mouse_exited.connect(resize_down.bind(boton))

func resize_up(boton: Control) -> void:
	boton.scale = Vector2(1.05, 1.05)

func resize_down(boton: Control) -> void:
	boton.scale = Vector2.ONE

func abrir_menu(nuevo_menu: Control) -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(menu_botones, "position:x", BOTONES_LATERAL, DURACION)
	if menu_activo and menu_activo != nuevo_menu:
		tween.tween_property(menu_activo, "position:x", POS_FUERA_DER, DURACION)
	nuevo_menu.position.x = POS_FUERA_DER
	tween.tween_property(nuevo_menu, "position:x", POS_CENTRO, DURACION)
	menu_activo = nuevo_menu

func cerrar_todo() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(menu_botones, "position:x", BOTONES_HOME, DURACION)
	if menu_activo:
		tween.tween_property(menu_activo, "position:x", POS_FUERA_DER, DURACION)
		menu_activo = null
