extends Control
@onready var boton_salir_menu = $Menu_Botones/Salir

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	boton_salir_menu.pressed.connect (
		salir
	)

func salir() -> void:
	get_tree().quit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
