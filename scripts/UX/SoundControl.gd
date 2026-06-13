extends Control

@onready var btn_music_control: HSlider = $Music
@onready var btn_sfx_control: HSlider = $SFX

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	btn_music_control.value_changed.connect(
		func (valor):
			cambiar_volumen("Music", valor)
	)
	
	btn_sfx_control.value_changed.connect(
		func (valor):
			cambiar_volumen("SFX", valor)
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func cambiar_volumen(nombre_bus: String, valor_lineal: float) -> void:
	# 1. Obtenemos el número de índice del bus mediante su nombre
	var bus_index = AudioServer.get_bus_index(nombre_bus)
	
	# Caso límite: Si el nombre está mal escrito, el índice será -1. Evitamos un crash.
	if bus_index == -1:
		push_error("El bus de audio '" + nombre_bus + "' no existe.")
		return
		
	# 2. Si el valor es 0, silenciamos el bus por completo (Mute) para ahorrar procesamiento
	if valor_lineal <= 0.0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		# 3. Convertimos el porcentaje (0.0 a 1.0) a Decibelios matemáticos (-60dB a 0dB)
		var volumen_db = linear_to_db(valor_lineal)
		AudioServer.set_bus_volume_db(bus_index, volumen_db)

# Conexión del slider de la música
func _on_slider_musica_value_changed(value: float) -> void:
	cambiar_volumen("Music", value)

# Conexión del slider de los efectos de sonido
func _on_slider_sfx_value_changed(value: float) -> void:
	cambiar_volumen("SFX", value)
