extends Node

var background_music: AudioStreamPlayer

func _ready() -> void:
	# Creamos el reproductor por código para que sea 100% independiente
	background_music = AudioStreamPlayer.new()
	add_child(background_music)
	
	# ASIGNACIÓN CRÍTICA: Lo mandamos al bus de música que creamos antes
	background_music.bus = "Music"
	
	# Opcional: Si quieres que empiece a sonar apenas se abra el juego
	# musica_fondo.stream = preload("res://tu_musica.mp3")
	# musica_fondo.play()

func change_volume(name_bus: String, linear_value: float) -> void:
	var bus_index = AudioServer.get_bus_index(name_bus)
	if bus_index == -1:
		push_error("El bus de audio '" + name_bus + "' no existe.")
		return
	if linear_value <= 0.0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_value))
