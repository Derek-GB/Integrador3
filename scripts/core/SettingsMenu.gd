extends CanvasLayer

# =============================================================================
# SettingsMenu.gd
#
# Popup/modal de configuración. Se puede abrir desde el menú principal
# o desde la pantalla de pausa.
#
# Uso:
#   SettingsMenu.abrir()
#   SettingsMenu.cerrar()
# =============================================================================

# ── Nodos ────────────────────────────────────────────────────────────────────

@onready var panel            := $Panel
@onready var btn_cerrar       := $Panel/MarginContainer/VBox/Header/BtnCerrar
@onready var btn_cancelar     := $Panel/MarginContainer/VBox/FooterBtns/BtnCancelar
@onready var btn_aplicar      := $Panel/MarginContainer/VBox/FooterBtns/BtnAplicar
@onready var lbl_reinicio     := $Panel/MarginContainer/VBox/LblReinicio

@onready var opt_modo         := $Panel/MarginContainer/VBox/ScrollContainer/Opciones/FilaModo/OptModo
@onready var opt_res          := $Panel/MarginContainer/VBox/ScrollContainer/Opciones/FilaRes/OptRes
@onready var chk_vsync        := $Panel/MarginContainer/VBox/ScrollContainer/Opciones/FilaVsync/ChkVsync
@onready var opt_fps          := $Panel/MarginContainer/VBox/ScrollContainer/Opciones/FilaFPS/OptFPS
@onready var chk_aa           := $Panel/MarginContainer/VBox/ScrollContainer/Opciones/FilaAA/ChkAA
@onready var chk_sombras      := $Panel/MarginContainer/VBox/ScrollContainer/Opciones/FilaSombras/ChkSombras
@onready var opt_calidad_somb := $Panel/MarginContainer/VBox/ScrollContainer/Opciones/FilaCalidadSombras/OptCalidadSombras

# ── Estado temporal (lo que el usuario seleccionó pero aún no aplicó) ────────

var _modo_temp         : int
var _res_temp          : Vector2i
var _vsync_temp        : bool
var _fps_temp          : int
var _aa_temp           : bool
var _sombras_temp      : bool
var _calidad_somb_temp : int  # índice del enum ShadowQuality

# ── Constantes de opciones ───────────────────────────────────────────────────

const MODOS_PANTALLA := ["Pantalla Completa", "Sin Bordes", "Ventana"]
const RESOLUCIONES   := [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]
const FPS_OPCIONES   := [30, 60, 120]
const CALIDAD_SOMBRAS := ["Baja", "Media", "Alta"]

# =============================================================================
# GODOT
# =============================================================================

func _ready() -> void:
	print("opt_res: ", opt_res)
	print("opt_modo: ", opt_modo)
	print("opt_fps: ", opt_fps)
	print("opt_calidad_somb: ", opt_calidad_somb)
	print("chk_vsync: ", chk_vsync)
	print("chk_aa: ", chk_aa)
	print("chk_sombras: ", chk_sombras)
	_poblar_opciones()
	_conectar_senales()
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		cerrar()
		get_viewport().set_input_as_handled()

# =============================================================================
# PÚBLICO
# =============================================================================

func abrir() -> void:
	_cargar_valores_actuales()
	lbl_reinicio.visible = false
	visible = true
	# Si el juego está corriendo, pausarlo
	if get_tree().current_scene != null:
		get_tree().paused = true


func cerrar() -> void:
	visible = false
	get_tree().paused = false

# =============================================================================
# SETUP
# =============================================================================

func _poblar_opciones() -> void:
	for m in MODOS_PANTALLA:
		opt_modo.add_item(m)

	for r in RESOLUCIONES:
		opt_res.add_item("%d x %d" % [r.x, r.y])

	for f in FPS_OPCIONES:
		opt_fps.add_item("%d FPS" % f)

	for c in CALIDAD_SOMBRAS:
		opt_calidad_somb.add_item(c)


func _conectar_senales() -> void:
	btn_cerrar.pressed.connect(cerrar)
	btn_cancelar.pressed.connect(cerrar)
	btn_aplicar.pressed.connect(_aplicar)

	# Detectar cambios para mostrar aviso de reinicio si aplica
	chk_aa.toggled.connect(_on_aa_toggled)
	opt_calidad_somb.item_selected.connect(_on_calidad_sombras_seleccionada)

	# El resto solo actualiza el estado temporal
	opt_modo.item_selected.connect(func(i): _modo_temp = i)
	opt_res.item_selected.connect(func(i): _res_temp = RESOLUCIONES[i])
	chk_vsync.toggled.connect(func(v): _vsync_temp = v)
	opt_fps.item_selected.connect(func(i): _fps_temp = FPS_OPCIONES[i])
	chk_sombras.toggled.connect(func(v): _sombras_temp = v)

# =============================================================================
# CARGA DE VALORES ACTUALES
# =============================================================================

func _cargar_valores_actuales() -> void:
	var sm := SettingsManager

	_modo_temp         = sm.window_mode
	_res_temp          = sm.resolution
	_vsync_temp        = sm.vsync_enabled
	_fps_temp          = sm.max_fps
	_aa_temp           = sm.antialiasing_enabled
	_sombras_temp      = sm.shadows_enabled
	_calidad_somb_temp = sm.shadow_quality

	# Reflejar en controles
	opt_modo.select(_modo_temp)
	opt_res.select(_indice_resolucion(_res_temp))
	chk_vsync.button_pressed = _vsync_temp
	opt_fps.select(_indice_fps(_fps_temp))
	chk_aa.button_pressed = _aa_temp
	chk_sombras.button_pressed = _sombras_temp
	opt_calidad_somb.select(_calidad_somb_temp)


func _indice_resolucion(res: Vector2i) -> int:
	for i in RESOLUCIONES.size():
		if RESOLUCIONES[i] == res:
			return i
	return 2  # default 1080p


func _indice_fps(fps: int) -> int:
	for i in FPS_OPCIONES.size():
		if FPS_OPCIONES[i] == fps:
			return i
	return 1  # default 60

# =============================================================================
# SEÑALES DE CONTROLES
# =============================================================================

func _on_aa_toggled(valor: bool) -> void:
	_aa_temp = valor
	_revisar_reinicio()


func _on_calidad_sombras_seleccionada(indice: int) -> void:
	_calidad_somb_temp = indice
	_revisar_reinicio()


func _revisar_reinicio() -> void:
	var sm := SettingsManager
	var necesita := (
		_aa_temp != sm.antialiasing_enabled or
		_calidad_somb_temp != sm.shadow_quality
	)
	lbl_reinicio.visible = necesita

# =============================================================================
# APLICAR
# =============================================================================

func _aplicar() -> void:
	var sm := SettingsManager

	sm.set_window_mode(_modo_temp)
	sm.set_resolution(_res_temp)
	sm.set_vsync(_vsync_temp)
	sm.set_max_fps(_fps_temp)
	sm.set_shadows_enabled(_sombras_temp)
	sm.set_antialiasing_enabled(_aa_temp)
	sm.set_shadow_quality(_calidad_somb_temp)

	# El aviso de reinicio ya lo maneja SettingsManager via restart_required_changed,
	# pero también lo mostramos localmente si aplica.
	lbl_reinicio.visible = sm.restart_required
