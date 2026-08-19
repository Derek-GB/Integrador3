extends Node

const POOL_SIZE := 8
var _sfx_pool: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var block_sfx := false

func _ready()-> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

func change_volume(name_bus: String, linear_value: float) -> void:
	var bus_index = AudioServer.get_bus_index(name_bus)
	if bus_index == -1:
		push_error("El bus de audio '" + name_bus + "' no existe.")
		return
	if linear_value <= 0.0:
		AudioServer.set_bus_mute(bus_index, true)
		AudioServer.set_bus_volume_db(bus_index, -80.0)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_value))

func play_sfx(stream: AudioStream, volume_db := 0.0) -> void:
	if block_sfx:
		return

	var player := _get_free_player()
	player.stream = stream
	player.volume_db = volume_db
	player.play()

func stop_all_sfx() -> void:
	block_sfx = true

	for player in _sfx_pool:
		player.stop()
		player.stream = null

func enable_sfx() -> void:
	block_sfx = false

func play_music(stream: AudioStream, crossfade: float = 1.0, volume_db: float = 0.0) -> void:
	if stream == null:
		return

	if _music_player.playing and _music_player.stream == stream:
		return

	_set_stream_loop(stream)

	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -80.0, crossfade)
	await tween.finished

	_music_player.stream = stream
	_music_player.play()

	tween = create_tween()
	tween.tween_property(_music_player, "volume_db", volume_db, crossfade)

func stop_music() -> void:
	_music_player.stop()

# =========================================================
# REGISTRO DE PLAYERS EXTERNOS
# Regla oficial del proyecto (ver docs/AUDIO_MANAGER.md):
# todo AudioStreamPlayer de cualquier minijuego debe registrarse
# o crearse por aquí para respetar los buses Music/SFX.
# =========================================================

func register_sfx_player(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	player.bus = "SFX"

func register_music_player(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	player.bus = "Music"

func create_sfx_player(stream: AudioStream, volume_db := 0.0) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	player.stream = stream
	player.volume_db = volume_db
	return player

func create_music_player(stream: AudioStream, volume_db := 0.0) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = "Music"
	player.stream = stream
	player.volume_db = volume_db
	return player

func _get_free_player() -> AudioStreamPlayer:
	for p in _sfx_pool:
		if not p.playing:
			return p
	return _sfx_pool[0] # fallback: reutilizar el primero

func _set_stream_loop(stream: AudioStream, enabled: bool = true) -> void:
	if stream == null:
		return

	if stream is AudioStreamOggVorbis:
		stream.loop = enabled

	elif stream is AudioStreamMP3:
		stream.loop = enabled

	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

	else:
		push_warning("AudioManager: Tipo de AudioStream no soportado para loop: %s" % stream.get_class())
