extends Control

@onready var btn_music_control: HSlider = $Music
@onready var btn_sfx_control: HSlider = $SFX

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	btn_music_control.value_changed.connect(
		func (value):
			change_volume("Music", value)
	)
	
	btn_sfx_control.value_changed.connect(
		func (value):
			change_volume("SFX", value)
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func change_volume(name_bus: String, linear_value: float) -> void:
	# 1. Obtenemos el número de índice del bus mediante su nombre
	var bus_index = AudioServer.get_bus_index(name_bus)
	
	# Caso límite: Si el nombre está mal escrito, el índice será -1. Evitamos un crash.
	if bus_index == -1:
		push_error("El bus de audio '" + name_bus + "' no existe.")
		return
		
	# 2. Si el valor es 0, silenciamos el bus por completo (Mute) para ahorrar procesamiento
	if linear_value <= 0.0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		# 3. Convertimos el porcentaje (0.0 a 1.0) a Decibelios matemáticos (-60dB a 0dB)
		var volume_db = linear_to_db(linear_value)
		AudioServer.set_bus_volume_db(bus_index, volume_db)
