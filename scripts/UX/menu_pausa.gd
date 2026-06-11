extends Control
@onready var boton_salir = $Panel/Salir
@onready var boton_jugar = $Panel/Jugar

const MAIN_MENU = "res://scenes/UX/menuPrincipal.tscn"

var posicion_oculta: Vector2 = Vector2(2000,0)
var posicion_visible: Vector2 = Vector2(0,0)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global_position = posicion_oculta
	boton_salir.pressed.connect (
		salir
	)
	
	boton_jugar.pressed.connect (
		self.cerrar_ventana
	)

func salir() -> void:
	get_tree().change_scene_to_file(MAIN_MENU)

func abrir_ventana():
	global_position = posicion_visible
	show()
	set_process(true)
	

func cerrar_ventana():
	global_position = posicion_oculta
	hide()
	set_process(false)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
