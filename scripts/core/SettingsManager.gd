extends Node

# =============================================================================
# SettingsManager.gd
#
# Autoload encargado de:
# - Cargar configuraciones desde user://general.cfg
# - Guardar configuraciones
# - Aplicar configuraciones inmediatas
# - Notificar cuando un reinicio es necesario
#
# Configuraciones inmediatas:
#   - Audio
#   - Resolución
#   - Modo de ventana
#   - VSync
#   - FPS máximos
#   - Activar/desactivar sombras
#
# Configuraciones que requieren reinicio (en teoria):
#   - Antialiasing
#   - Calidad de sombras
#
# Dependencias:
#   - AudioManager (autoload)
#
# Grupos utilizados:
#   - "lights"
#
# =============================================================================

signal settings_changed
signal restart_required_changed(required: bool)

const CONFIG_PATH := "user://general.cfg"

# =============================================================================
# ENUMS
# =============================================================================

enum WindowMode {
	FULLSCREEN,
	BORDERLESS,
	WINDOWED
}

enum ShadowQuality {
	LOW,
	MEDIUM,
	HIGH
}

# =============================================================================
# AUDIO
# =============================================================================

var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0

# =============================================================================
# VIDEO
# =============================================================================

var window_mode: WindowMode = WindowMode.FULLSCREEN

var resolution: Vector2i = Vector2i(1920, 1080)

var vsync_enabled: bool = true

# 0 = sin límite
var max_fps: int = 60

# =============================================================================
# GRAPHICS
# =============================================================================

# Requiere reinicio
var antialiasing_enabled: bool = false

# Se puede aplicar inmediatamente
var shadows_enabled: bool = true

# Requiere reinicio
var shadow_quality: ShadowQuality = ShadowQuality.LOW

# =============================================================================
# INTERNAL
# =============================================================================

var restart_required: bool = false

# =============================================================================
# GODOT
# =============================================================================

func _ready() -> void:
	load_settings()
	process_mode = Node.PROCESS_MODE_ALWAYS

# =============================================================================
# LOAD / SAVE
# =============================================================================

func load_settings() -> void:
	var config := ConfigFile.new()

	if config.load(CONFIG_PATH) != OK:
		print("SettingsManager: creando archivo de configuración.")
		save_settings()

	apply_loaded_values(config)
	apply_settings()


func apply_loaded_values(config: ConfigFile) -> void:

	# -------------------------------------------------------------------------
	# AUDIO
	# -------------------------------------------------------------------------

	master_volume = config.get_value(
		"audio",
		"master_volume",
		1.0
	)

	music_volume = config.get_value(
		"audio",
		"music_volume",
		1.0
	)

	sfx_volume = config.get_value(
		"audio",
		"sfx_volume",
		1.0
	)

	# -------------------------------------------------------------------------
	# VIDEO
	# -------------------------------------------------------------------------

	window_mode = config.get_value(
		"video",
		"window_mode",
		WindowMode.FULLSCREEN
	)

	resolution = config.get_value(
		"video",
		"resolution",
		Vector2i(1920, 1080)
	)

	vsync_enabled = config.get_value(
		"video",
		"vsync_enabled",
		true
	)

	max_fps = config.get_value(
		"video",
		"max_fps",
		60
	)

	# -------------------------------------------------------------------------
	# GRAPHICS
	# -------------------------------------------------------------------------

	antialiasing_enabled = config.get_value(
		"graphics",
		"antialiasing_enabled",
		false
	)

	shadows_enabled = config.get_value(
		"graphics",
		"shadows_enabled",
		true
	)

	shadow_quality = config.get_value(
		"graphics",
		"shadow_quality",
		ShadowQuality.LOW
	)


func save_settings() -> void:
	var config := ConfigFile.new()

	# -------------------------------------------------------------------------
	# AUDIO
	# -------------------------------------------------------------------------

	config.set_value(
		"audio",
		"master_volume",
		master_volume
	)

	config.set_value(
		"audio",
		"music_volume",
		music_volume
	)

	config.set_value(
		"audio",
		"sfx_volume",
		sfx_volume
	)

	# -------------------------------------------------------------------------
	# VIDEO
	# -------------------------------------------------------------------------

	config.set_value(
		"video",
		"window_mode",
		window_mode
	)

	config.set_value(
		"video",
		"resolution",
		resolution
	)

	config.set_value(
		"video",
		"vsync_enabled",
		vsync_enabled
	)

	config.set_value(
		"video",
		"max_fps",
		max_fps
	)

	# -------------------------------------------------------------------------
	# GRAPHICS
	# -------------------------------------------------------------------------

	config.set_value(
		"graphics",
		"antialiasing_enabled",
		antialiasing_enabled
	)

	config.set_value(
		"graphics",
		"shadows_enabled",
		shadows_enabled
	)

	config.set_value(
		"graphics",
		"shadow_quality",
		shadow_quality
	)

	var err := config.save(CONFIG_PATH)

	if err != OK:
		push_error("Error guardando configuración.")

# =============================================================================
# APPLY
# =============================================================================

func apply_settings() -> void:
	apply_audio()
	apply_window()
	apply_vsync()
	apply_fps()
	apply_shadows()
	apply_antialiasing()   
	apply_shadow_quality()

	settings_changed.emit()


func apply_audio() -> void:
	if AudioManager == null:
		return

	AudioManager.change_volume(
		"Master",
		master_volume
	)

	AudioManager.change_volume(
		"Music",
		music_volume
	)

	AudioManager.change_volume(
		"SFX",
		sfx_volume
	)


func apply_window() -> void:

	match window_mode:

		WindowMode.FULLSCREEN:
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_FULLSCREEN
			)

		WindowMode.BORDERLESS:
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_WINDOWED
			)

			DisplayServer.window_set_flag(
				DisplayServer.WINDOW_FLAG_BORDERLESS,
				true
			)

		WindowMode.WINDOWED:
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_WINDOWED
			)

			DisplayServer.window_set_flag(
				DisplayServer.WINDOW_FLAG_BORDERLESS,
				false
			)

	# Aplicar resolución solamente en modos ventana.

	if window_mode != WindowMode.FULLSCREEN:
		await get_tree().process_frame
		var screen_size: Vector2i = DisplayServer.screen_get_size()
		var safe_res: Vector2i = Vector2i(
			mini(resolution.x, screen_size.x),
			mini(resolution.y, screen_size.y)
		)
		get_window().size = safe_res
		get_window().position = (screen_size - safe_res) / 2


func apply_vsync() -> void:

	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED
		if vsync_enabled
		else DisplayServer.VSYNC_DISABLED
	)


func apply_fps() -> void:
	Engine.max_fps = max_fps


func apply_shadows() -> void:

	# Recorre todas las luces registradas
	# en el grupo "lights".

	for light in get_tree().get_nodes_in_group("lights"):

		if light is Light3D:
			light.shadow_enabled = shadows_enabled


func apply_antialiasing() -> void:
	var msaa := Viewport.MSAA_2X if antialiasing_enabled else Viewport.MSAA_DISABLED

	get_viewport().msaa_2d = msaa
	get_viewport().msaa_3d = msaa


func apply_shadow_quality() -> void:
	var atlas_size: int

	match shadow_quality:
		ShadowQuality.LOW:    atlas_size = 1024
		ShadowQuality.MEDIUM: atlas_size = 2048
		ShadowQuality.HIGH:   atlas_size = 4096

	RenderingServer.directional_shadow_atlas_set_size(atlas_size, true)

# =============================================================================
# AUDIO PREVIEWs
# =============================================================================

func preview_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)

	AudioManager.change_volume(
		"Master", master_volume
		)

func preview_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)

	AudioManager.change_volume(
		"Music", music_volume
	)

func preview_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)

	AudioManager.change_volume(
		"SFX", sfx_volume
	)

# =============================================================================
# AUDIO SETTERS
# =============================================================================

func set_music_volume(value: float) -> void:
	preview_music_volume(value)

	save_settings()

func set_sfx_volume(value: float) -> void:
	preview_sfx_volume(value)

	save_settings()

func set_master_volume(value: float) -> void:
	preview_master_volume(value)

	save_settings()

# =============================================================================
# VIDEO SETTERS
# =============================================================================

func set_window_mode(mode: WindowMode) -> void:
	window_mode = mode

	apply_window()
	save_settings()


func set_resolution(new_resolution: Vector2i) -> void:
	resolution = new_resolution

	apply_window()
	save_settings()

func set_window_settings(mode: WindowMode, new_resolution: Vector2i) -> void:
	window_mode = mode
	resolution = new_resolution
	
	apply_window()
	save_settings()

func set_vsync(enabled: bool) -> void:
	vsync_enabled = enabled

	apply_vsync()
	save_settings()


func set_max_fps(fps: int) -> void:
	max_fps = fps

	apply_fps()
	save_settings()

# =============================================================================
# GRAPHICS SETTERS
# =============================================================================

func set_shadows_enabled(enabled: bool) -> void:
	shadows_enabled = enabled

	apply_shadows()
	save_settings()


func set_antialiasing_enabled(enabled: bool) -> void:
	antialiasing_enabled = enabled

	apply_antialiasing()
	save_settings()



func set_shadow_quality(value: ShadowQuality) -> void:
	shadow_quality = value

	apply_shadow_quality()
	save_settings()

# =============================================================================
# RESTART
# =============================================================================

func _mark_restart_required() -> void:
	restart_required = true

	save_settings()

	restart_required_changed.emit(true)


func clear_restart_required() -> void:
	restart_required = false

	restart_required_changed.emit(false)

# =============================================================================
# HELPERS
# =============================================================================

func get_available_resolutions() -> Array[Vector2i]:
	return [
		Vector2i(1280, 720),
		Vector2i(1600, 900),
		Vector2i(1920, 1080),
		Vector2i(2560, 1440)
	]


func reset_to_defaults() -> void:

	master_volume = 1.0
	music_volume = 1.0
	sfx_volume = 1.0

	window_mode = WindowMode.FULLSCREEN
	resolution = Vector2i(1920, 1080)

	vsync_enabled = true
	max_fps = 60

	antialiasing_enabled = false

	shadows_enabled = true
	shadow_quality = ShadowQuality.LOW

	restart_required = true

	save_settings()
	apply_settings()
