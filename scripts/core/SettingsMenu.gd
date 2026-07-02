extends CanvasLayer

# =============================================================================
# SettingsMenu.gd
#
# Configuration popup/modal. It can be opened from the main menu
# or from the pause screen.
#
# Usage:
#   SettingsMenu.open()
#   SettingsMenu.close()
# =============================================================================

# ── Nodes ────────────────────────────────────────────────────────────────────
signal closed

@onready var panel            := $Panel
@onready var btn_close       := $Panel/MarginContainer/VBox/Header/BtnCerrar
@onready var btn_cancel     := $Panel/MarginContainer/VBox/FooterBtns/BtnExit
@onready var btn_apply      := $Panel/MarginContainer/VBox/FooterBtns/BtnAplicar
@onready var lbl_restart     := $Panel/MarginContainer/VBox/LblReinicio
@onready var hide_timer: Timer = $HideLabelTimer

@onready var opt_mode         := $Panel/MarginContainer/VBox/ScrollContainer/Opciones/FilaModo/OptModo
@onready var opt_resolution   := $Panel/MarginContainer/VBox/ScrollContainer/Opciones/FilaRes/OptRes
@onready var chk_vsync        := $Panel/MarginContainer/VBox/ScrollContainer/Opciones/FilaVsync/ChkVsync
@onready var opt_fps          := $Panel/MarginContainer/VBox/ScrollContainer/Opciones/FilaFPS/OptFPS
@onready var chk_aa           := $Panel/MarginContainer/VBox/ScrollContainer/Opciones/FilaAA/ChkAA
@onready var chk_shadows      := $Panel/MarginContainer/VBox/ScrollContainer/Opciones/FilaSombras/ChkSombras
@onready var opt_shadow_quality := $Panel/MarginContainer/VBox/ScrollContainer/Opciones/FilaCalidadSombras/OptCalidadSombras

# ── Temporary state (what the user selected but has not applied yet) ─────────

var _temp_mode           : int
var _temp_resolution     : Vector2i
var _temp_vsync          : bool
var _temp_fps            : int
var _temp_aa             : bool
var _temp_shadows        : bool
var _temp_shadow_quality : int  # index of the ShadowQuality enum

# ── Option constants ─────────────────────────────────────────────────────────

const SCREEN_MODES   := ["Pantalla Completa", "Sin Bordes", "Ventana"]
const RESOLUTIONS    := [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]
const FPS_OPTIONS    := [30, 60, 120]
const SHADOW_QUALITY := ["Baja", "Media", "Alta"]

# =============================================================================
# GODOT
# =============================================================================

func _ready() -> void:
	print("opt_res: ", opt_resolution)
	print("opt_modo: ", opt_mode)
	print("opt_fps: ", opt_fps)
	print("opt_calidad_somb: ", opt_shadow_quality)
	print("chk_vsync: ", chk_vsync)
	print("chk_aa: ", chk_aa)
	print("chk_sombras: ", chk_shadows)
	_populate_options()
	_connect_signals()
	hide_timer.timeout.connect(
		func(): lbl_restart.visible = false
	)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

# =============================================================================
# PUBLIC
# =============================================================================

func open() -> void:
	_load_current_values()
	lbl_restart.visible = false
	visible = true
	# If the game is running, pause it
	if get_tree().current_scene != null:
		Events.notify_pause.emit(true)


func close() -> void:
	visible = false
	Events.notify_pause.emit(false)
	closed.emit()

# =============================================================================
# SETUP
# =============================================================================

func _populate_options() -> void:
	for m in SCREEN_MODES:
		opt_mode.add_item(m)

	for r in RESOLUTIONS:
		opt_resolution.add_item("%d x %d" % [r.x, r.y])

	for f in FPS_OPTIONS:
		opt_fps.add_item("%d FPS" % f)

	for c in SHADOW_QUALITY:
		opt_shadow_quality.add_item(c)


func _connect_signals() -> void:
	btn_close.pressed.connect(close)
	btn_cancel.pressed.connect(close)
	btn_apply.pressed.connect(_apply)

	# Detect changes to show restart warning if applicable
	chk_aa.toggled.connect(_on_aa_toggled)
	opt_shadow_quality.item_selected.connect(_on_shadow_quality_selected)

	# The rest only updates the temporary state
	opt_mode.item_selected.connect(func(i): _temp_mode = i)
	opt_resolution.item_selected.connect(func(i): _temp_resolution = RESOLUTIONS[i])
	chk_vsync.toggled.connect(func(v): _temp_vsync = v)
	opt_fps.item_selected.connect(func(i): _temp_fps = FPS_OPTIONS[i])
	chk_shadows.toggled.connect(func(v): _temp_shadows = v)

# =============================================================================
# LOAD CURRENT VALUES
# =============================================================================

func _load_current_values() -> void:
	var sm := SettingsManager

	_temp_mode           = sm.window_mode
	_temp_resolution     = sm.resolution
	_temp_vsync          = sm.vsync_enabled
	_temp_fps            = sm.max_fps
	_temp_aa             = sm.antialiasing_enabled
	_temp_shadows        = sm.shadows_enabled
	_temp_shadow_quality = sm.shadow_quality

	# Reflect in controls
	opt_mode.select(_temp_mode)
	opt_resolution.select(_get_resolution_index(_temp_resolution))
	chk_vsync.button_pressed = _temp_vsync
	opt_fps.select(_get_fps_index(_temp_fps))
	chk_aa.button_pressed = _temp_aa
	chk_shadows.button_pressed = _temp_shadows
	opt_shadow_quality.select(_temp_shadow_quality)


func _get_resolution_index(res: Vector2i) -> int:
	for i in RESOLUTIONS.size():
		if RESOLUTIONS[i] == res:
			return i
	return 2  # default 1080p


func _get_fps_index(fps: int) -> int:
	for i in FPS_OPTIONS.size():
		if FPS_OPTIONS[i] == fps:
			return i
	return 1  # default 60

# =============================================================================
# CONTROL SIGNALS
# =============================================================================

func _on_aa_toggled(value: bool) -> void:
	_temp_aa = value
	# _check_restart()


func _on_shadow_quality_selected(index: int) -> void:
	_temp_shadow_quality = index
	# _check_restart()


func _check_restart() -> void:
	var sm := SettingsManager
	var needs_restart := (
		_temp_aa != sm.antialiasing_enabled or
		_temp_shadow_quality != sm.shadow_quality
	)
	lbl_restart.visible = needs_restart

# =============================================================================
# APPLY
# =============================================================================

func _apply() -> void:
	var sm := SettingsManager

	sm.set_window_settings(_temp_mode, _temp_resolution)
	sm.set_vsync(_temp_vsync)
	sm.set_max_fps(_temp_fps)
	sm.set_shadows_enabled(_temp_shadows)
	sm.set_antialiasing_enabled(_temp_aa)
	sm.set_shadow_quality(_temp_shadow_quality)

	# The restart warning is already handled by SettingsManager via restart_required_changed,
	# but we also display it locally if applicable.
	lbl_restart.add_theme_color_override("font_color",Color.GREEN)
	lbl_restart.visible = true
	hide_timer.start()
