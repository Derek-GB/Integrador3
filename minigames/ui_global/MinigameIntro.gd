extends Control

var minigame_data: Node

# ── Referencias para el tutorial guiado ──────────────────
var panel_controles: PanelContainer
var panel_desc: PanelContainer
var btn: Button

var tutorial_overlay: ColorRect
var tutorial_focus: Panel
var tutorial_text_bg: Panel
var tutorial_arrow: Label
var tutorial_title: Label
var tutorial_message: Label
var tutorial_next: Button
var tutorial_step: int = 0
var tutorial_pulse: Tween


func _ready():
	minigame_data = get_node("/root/MinigameData")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_clear_scene()
	_build_scene()


func _clear_scene():
	for child in get_children():
		child.queue_free()


func _build_scene():
	var screen = get_viewport_rect().size

	# ── Sonido de instrucciones en bucle ───────────────────
	var audio = AudioStreamPlayer.new()
	audio.name = "AudioInstrucciones"
	audio.stream = load("res://minigames/ui_global/music/Sound_Instruction.mp3")
	audio.volume_db = -15.0
	audio.bus = "Music"
	add_child(audio)
	audio.call_deferred("play")
	audio.finished.connect(func(): audio.play())

	# ── Fondo ──────────────────────────────────────────────
	var bg = ColorRect.new()
	bg.color = Color("#B8D9F0")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# ── Título arriba al centro ────────────────────────────
	var panel_titulo = PanelContainer.new()
	panel_titulo.custom_minimum_size = Vector2(screen.x * 0.57, 73)
	panel_titulo.position = Vector2(screen.x / 2 - screen.x * 0.285, 10)
	_set_panel_color(panel_titulo, Color("#5AAB5A"))
	add_child(panel_titulo)

	var lbl_title = Label.new()
	lbl_title.text = minigame_data.title
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 58)
	lbl_title.add_theme_color_override("font_color", Color("#FFFFFF"))
	lbl_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_titulo.add_child(lbl_title)

	# ── HBox principal ─────────────────────────────────────
	var hbox = HBoxContainer.new()
	hbox.position = Vector2(40, 100)
	hbox.size = Vector2(screen.x - 80, screen.y - 200)
	hbox.add_theme_constant_override("separation", 10)
	add_child(hbox)

	# ── Cálculo de alineación vertical del video ───────────
	var hbox_height = screen.y - 200
	var video_height = screen.y * 0.58 + 60.0
	var video_top_offset = (hbox_height - video_height) / 2.0

	# ── Video lado izquierdo ───────────────────────────────
	var vbox_video = VBoxContainer.new()
	vbox_video.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_video.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_video.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(vbox_video)

	var panel_video = PanelContainer.new()
	panel_video.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel_video.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var style_video = StyleBoxFlat.new()
	style_video.bg_color = Color("#C8895A")
	style_video.corner_radius_top_left = 12
	style_video.corner_radius_top_right = 12
	style_video.corner_radius_bottom_left = 12
	style_video.corner_radius_bottom_right = 12
	style_video.content_margin_left = 30
	style_video.content_margin_right = 30
	style_video.content_margin_top = 30
	style_video.content_margin_bottom = 30
	panel_video.add_theme_stylebox_override("panel", style_video)

	vbox_video.add_child(panel_video)

	var video = VideoStreamPlayer.new()
	video.custom_minimum_size = Vector2(screen.x * 0.46, screen.y * 0.58)
	video.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	video.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	video.expand = true
	video.volume_db = -80.0
	panel_video.add_child(video)

	if minigame_data.video_path != "":
		print("El path de video es " + minigame_data.video_path)

		var stream = VideoStreamTheora.new()
		stream.file = minigame_data.video_path
		video.stream = stream
		video.play()

		video.finished.connect(func():
			video.play()
		)

	else:
		print("video_path está vacío")

	# ── VBox lado derecho ──────────────────────────────────
	var vbox_right = VBoxContainer.new()
	vbox_right.custom_minimum_size = Vector2(screen.x * 0.36, 0)
	vbox_right.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox_right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_right.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox_right.add_theme_constant_override("separation", 18)
	hbox.add_child(vbox_right)

	var spacer_top = Control.new()
	spacer_top.custom_minimum_size = Vector2(0, video_top_offset - 15)
	vbox_right.add_child(spacer_top)

	const CONTROLES_RATIO := 0.32
	const DESC_RATIO := 0.68

	var vbox_right_content = VBoxContainer.new()
	vbox_right_content.custom_minimum_size = Vector2(0, video_height)
	vbox_right_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_right_content.add_theme_constant_override("separation", 18)
	vbox_right.add_child(vbox_right_content)

	# ── Panel controles ────────────────────────────────────
	panel_controles = PanelContainer.new()
	panel_controles.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_controles.size_flags_stretch_ratio = CONTROLES_RATIO
	panel_controles.clip_contents = true
	panel_controles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_panel_color(panel_controles, Color("#D4621A"))

	vbox_right_content.add_child(panel_controles)

	var vbox_controles = VBoxContainer.new()
	vbox_controles.add_theme_constant_override("separation", 10)
	vbox_controles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_controles.add_child(vbox_controles)

	var lbl_controles_title = Label.new()
	lbl_controles_title.text = "Controles"
	lbl_controles_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_controles_title.add_theme_font_size_override("font_size", 40)
	lbl_controles_title.add_theme_color_override("font_color", Color("#FFFFFF"))
	lbl_controles_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox_controles.add_child(lbl_controles_title)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	vbox_controles.add_child(grid)

	const ICON_BOX_SIZE := Vector2(80, 80)

	for control in minigame_data.controls:

		var tex = load(control["icon"])

		print(
			"Cargando ícono:",
			control["icon"],
			" resultado:",
			tex
		)

		var icon = TextureRect.new()
		icon.texture = tex
		icon.custom_minimum_size = ICON_BOX_SIZE
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		grid.add_child(icon)

		var lbl_control = Label.new()
		lbl_control.text = control["action"]
		lbl_control.add_theme_color_override("font_color", Color("#FFFFFF"))
		lbl_control.add_theme_font_size_override("font_size", 30)
		lbl_control.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(lbl_control)

	# ── Panel descripción / instrucciones ──────────────────
	panel_desc = PanelContainer.new()
	panel_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_desc.size_flags_stretch_ratio = DESC_RATIO
	panel_desc.clip_contents = true
	panel_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_panel_color(panel_desc, Color("#D4621A"))

	vbox_right_content.add_child(panel_desc)

	var vbox_desc = VBoxContainer.new()
	vbox_desc.add_theme_constant_override("separation", 16)
	vbox_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_desc.add_child(vbox_desc)

	var lbl_desc = Label.new()
	lbl_desc.text = minigame_data.description
	lbl_desc.add_theme_color_override("font_color", Color("#FFFFFF"))
	lbl_desc.add_theme_font_size_override("font_size", 30)
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_desc.add_child(lbl_desc)

	var lbl_instr_title = Label.new()
	lbl_instr_title.text = "Instrucciones"
	lbl_instr_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_instr_title.add_theme_font_size_override("font_size", 40)
	lbl_instr_title.add_theme_color_override("font_color", Color("#FFFFFF"))
	lbl_instr_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox_desc.add_child(lbl_instr_title)

	var lbl_instr = Label.new()
	lbl_instr.text = minigame_data.instructions
	lbl_instr.add_theme_color_override("font_color", Color("#FFFFFF"))
	lbl_instr.add_theme_font_size_override("font_size", 28)
	lbl_instr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_instr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_desc.add_child(lbl_instr)

	# ── Botón Empezar ──────────────────────────────────────
	btn = Button.new()
	btn.text = "¡Empezar!"
	btn.custom_minimum_size = Vector2(260, 75)
	btn.position = Vector2(screen.x / 2 - 130, screen.y - 130)
	btn.add_theme_font_size_override("font_size", 40)
	btn.add_theme_color_override("font_color", Color("#FFFFFF"))

	_set_button_color(
		btn,
		Color("#5AAB5A"),
		Color("#6DBF6D"),
		Color("#3D8A3D")
	)

	btn.pressed.connect(_on_start)

	add_child(btn)

	# Empieza desactivado.
	btn.disabled = true

	# ── Leaf ───────────────────────────────────────────────
	var leaf_size = 170.0

	var leaf_icon = TextureRect.new()
	leaf_icon.texture = load("res://minigames/ui_global/assets/Leaf.png")
	leaf_icon.size = Vector2(leaf_size, leaf_size)
	leaf_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	leaf_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	leaf_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(leaf_icon)

	panel_video.resized.connect(func():

		var gp = panel_video.global_position

		leaf_icon.size = Vector2(
			leaf_size,
			leaf_size
		)

		leaf_icon.position = Vector2(
			gp.x
			+
			panel_video.size.x
			-
			leaf_size * 0.5
			+
			100,

			gp.y
			-
			leaf_size * 0.5
			+
			120
		)
	)

	# Inicia tutorial después de que los Containers
	# ya hayan calculado bien sus tamaños.
	call_deferred("_iniciar_tutorial_guiado")


# =========================================================
# TUTORIAL
# =========================================================

func _iniciar_tutorial_guiado() -> void:

	await get_tree().process_frame


	if (
		panel_controles == null
		or
		panel_desc == null
		or
		btn == null
	):

		push_warning(
			"Tutorial: faltan referencias."
		)

		if btn != null:
			btn.disabled = false

		return


	tutorial_step = 0


	# =====================================================
	# FONDO OSCURO
	# =====================================================

	tutorial_overlay = ColorRect.new()

	tutorial_overlay.name = "TutorialOverlay"

	tutorial_overlay.color = Color(
		0,
		0,
		0,
		0.38
	)

	tutorial_overlay.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	add_child(
		tutorial_overlay
	)

	tutorial_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)


	# =====================================================
	# BORDE AMARILLO
	# =====================================================

	tutorial_focus = Panel.new()

	tutorial_focus.name = "TutorialFocus"

	tutorial_focus.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	var focus_style = StyleBoxFlat.new()

	focus_style.bg_color = Color(
		1.0,
		0.92,
		0.20,
		0.08
	)

	focus_style.border_color = Color(
		"#FFD83D"
	)

	focus_style.set_border_width_all(
		9
	)

	focus_style.set_corner_radius_all(
		20
	)

	focus_style.shadow_color = Color(
		1.0,
		0.75,
		0.0,
		0.70
	)

	focus_style.shadow_size = 18


	tutorial_focus.add_theme_stylebox_override(
		"panel",
		focus_style
	)


	tutorial_overlay.add_child(
		tutorial_focus
	)


	# =====================================================
	# FONDO PARA EL TEXTO (título + mensaje)
	# =====================================================
	# Se agrega ANTES del título y el mensaje para que quede
	# detrás de ellos y les dé contraste, sin importar qué
	# haya de fondo (video, paneles claros, etc).

	tutorial_text_bg = Panel.new()

	tutorial_text_bg.name = "TutorialTextBg"

	tutorial_text_bg.position = Vector2(
		0,
		8
	)

	tutorial_text_bg.size = Vector2(
		get_viewport_rect().size.x,
		120
	)

	tutorial_text_bg.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	var text_bg_style = StyleBoxFlat.new()

	text_bg_style.bg_color = Color(
		0,
		0,
		0,
		0.78
	)

	text_bg_style.corner_radius_top_left = 14
	text_bg_style.corner_radius_top_right = 14
	text_bg_style.corner_radius_bottom_left = 18
	text_bg_style.corner_radius_bottom_right = 18


	tutorial_text_bg.add_theme_stylebox_override(
		"panel",
		text_bg_style
	)


	tutorial_overlay.add_child(
		tutorial_text_bg
	)


	# =====================================================
	# FLECHA
	# =====================================================

	tutorial_arrow = Label.new()

	tutorial_arrow.name = "TutorialArrow"

	tutorial_arrow.text = "➜"


	tutorial_arrow.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	tutorial_arrow.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	tutorial_arrow.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	tutorial_arrow.add_theme_font_size_override(
		"font_size",
		72
	)

	tutorial_arrow.add_theme_color_override(
		"font_color",
		Color("#FFD83D")
	)

	tutorial_arrow.add_theme_color_override(
		"font_shadow_color",
		Color.BLACK
	)

	tutorial_arrow.add_theme_constant_override(
		"shadow_offset_x",
		4
	)

	tutorial_arrow.add_theme_constant_override(
		"shadow_offset_y",
		4
	)


	tutorial_overlay.add_child(
		tutorial_arrow
	)


	# =====================================================
	# TÍTULO
	# =====================================================

	tutorial_title = Label.new()

	tutorial_title.name = "TutorialTitle"

	tutorial_title.position = Vector2(
		0,
		15
	)

	tutorial_title.size = Vector2(
		get_viewport_rect().size.x,
		52
	)


	tutorial_title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	tutorial_title.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	tutorial_title.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	tutorial_title.add_theme_font_size_override(
		"font_size",
		34
	)

	tutorial_title.add_theme_color_override(
		"font_color",
		Color("#FFD83D")
	)

	tutorial_title.add_theme_color_override(
		"font_shadow_color",
		Color.BLACK
	)

	tutorial_title.add_theme_constant_override(
		"shadow_offset_x",
		3
	)

	tutorial_title.add_theme_constant_override(
		"shadow_offset_y",
		3
	)


	tutorial_overlay.add_child(
		tutorial_title
	)


	# =====================================================
	# MENSAJE
	# =====================================================

	tutorial_message = Label.new()

	tutorial_message.name = "TutorialMessage"

	tutorial_message.position = Vector2(
		180,
		65
	)

	tutorial_message.size = Vector2(
		get_viewport_rect().size.x - 360,
		52
	)


	tutorial_message.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	tutorial_message.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	tutorial_message.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	tutorial_message.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	tutorial_message.add_theme_font_size_override(
		"font_size",
		24
	)

	tutorial_message.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	tutorial_message.add_theme_color_override(
		"font_shadow_color",
		Color.BLACK
	)

	tutorial_message.add_theme_constant_override(
		"shadow_offset_x",
		2
	)

	tutorial_message.add_theme_constant_override(
		"shadow_offset_y",
		2
	)


	tutorial_overlay.add_child(
		tutorial_message
	)


	# =====================================================
	# BOTÓN SIGUIENTE
	# =====================================================

	tutorial_next = Button.new()

	tutorial_next.name = "TutorialNext"

	tutorial_next.text = "SIGUIENTE  ▶"

	tutorial_next.custom_minimum_size = Vector2(
		300,
		72
	)

	tutorial_next.size = Vector2(
		300,
		72
	)

	tutorial_next.position = Vector2(
		get_viewport_rect().size.x / 2.0 - 150.0,
		get_viewport_rect().size.y - 95.0
	)


	tutorial_next.add_theme_font_size_override(
		"font_size",
		28
	)

	tutorial_next.add_theme_color_override(
		"font_color",
		Color.WHITE
	)


	_set_button_color(
		tutorial_next,
		Color("#5AAB5A"),
		Color("#6DBF6D"),
		Color("#3D8A3D")
	)


	tutorial_next.pressed.connect(
		_on_tutorial_next
	)


	tutorial_overlay.add_child(
		tutorial_next
	)


	_mostrar_paso_controles()


# =========================================================
# PASO 1
# =========================================================

func _mostrar_paso_controles() -> void:

	tutorial_step = 0


	tutorial_title.text = (
		"PASO 1 DE 2: MIRA LOS CONTROLES"
	)


	tutorial_message.text = (
		"Primero mira los botones que vas a usar durante el juego."
	)


	tutorial_next.text = (
		"SIGUIENTE  ▶"
	)


	_enfocar_tutorial(
		panel_controles
	)


# =========================================================
# PASO 2
# =========================================================

func _mostrar_paso_instrucciones() -> void:

	tutorial_step = 1


	tutorial_title.text = (
		"PASO 2 DE 2: MIRA LAS INSTRUCCIONES"
	)


	tutorial_message.text = (
		"Ahora mira qué debes hacer para completar el juego."
	)


	tutorial_next.text = (
		"LISTO  ▶"
	)


	_enfocar_tutorial(
		panel_desc
	)


# =========================================================
# SEÑALAR PANEL
# =========================================================

func _enfocar_tutorial(
	target: Control
) -> void:

	if (
		target == null
		or
		tutorial_overlay == null
	):
		return


	var target_rect: Rect2 = (
		target.get_global_rect()
	)


	var overlay_origin: Vector2 = (
		tutorial_overlay.get_global_rect().position
	)


	var local_pos: Vector2 = (
		target_rect.position
		-
		overlay_origin
	)


	tutorial_focus.position = (
		local_pos
		-
		Vector2(12, 12)
	)


	tutorial_focus.size = (
		target_rect.size
		+
		Vector2(24, 24)
	)


	# Flecha al lado izquierdo.
	tutorial_arrow.size = Vector2(
		90,
		90
	)


	tutorial_arrow.position = Vector2(
		max(
			10.0,
			tutorial_focus.position.x - 95.0
		),

		tutorial_focus.position.y
		+
		tutorial_focus.size.y / 2.0
		-
		45.0
	)


	_iniciar_pulso_tutorial()


# =========================================================
# PARPADEO
# =========================================================

func _iniciar_pulso_tutorial() -> void:

	if (
		tutorial_pulse != null
		and
		tutorial_pulse.is_valid()
	):

		tutorial_pulse.kill()


	tutorial_focus.modulate.a = 1.0

	tutorial_arrow.modulate.a = 1.0


	tutorial_pulse = create_tween()

	tutorial_pulse.set_loops()


	tutorial_pulse.tween_property(
		tutorial_focus,
		"modulate:a",
		0.45,
		0.5
	).set_trans(
		Tween.TRANS_SINE
	)


	tutorial_pulse.parallel().tween_property(
		tutorial_arrow,
		"modulate:a",
		0.45,
		0.5
	).set_trans(
		Tween.TRANS_SINE
	)


	tutorial_pulse.tween_property(
		tutorial_focus,
		"modulate:a",
		1.0,
		0.5
	).set_trans(
		Tween.TRANS_SINE
	)


	tutorial_pulse.parallel().tween_property(
		tutorial_arrow,
		"modulate:a",
		1.0,
		0.5
	).set_trans(
		Tween.TRANS_SINE
	)


# =========================================================
# SIGUIENTE
# =========================================================

func _on_tutorial_next() -> void:

	if tutorial_step == 0:

		_mostrar_paso_instrucciones()

		return


	_finalizar_tutorial()


# =========================================================
# FINALIZAR TUTORIAL
# =========================================================

func _finalizar_tutorial() -> void:

	tutorial_step = 2


	if (
		tutorial_pulse != null
		and
		tutorial_pulse.is_valid()
	):

		tutorial_pulse.kill()


	if tutorial_overlay != null:

		tutorial_overlay.queue_free()

		tutorial_overlay = null

		tutorial_text_bg = null


	# Ahora sí habilitamos EMPEZAR.
	btn.disabled = false

	btn.grab_focus()


	# Pequeño pulso para llamar la atención.
	btn.pivot_offset = (
		btn.size / 2.0
	)


	var start_pulse = create_tween()


	start_pulse.tween_property(
		btn,
		"scale",
		Vector2(
			1.08,
			1.08
		),
		0.18
	)


	start_pulse.tween_property(
		btn,
		"scale",
		Vector2.ONE,
		0.18
	)


	start_pulse.set_loops(
		2
	)


# =========================================================
# ESTILO PANEL
# =========================================================

func _set_panel_color(
	panel: PanelContainer,
	color: Color
):

	var style = StyleBoxFlat.new()

	style.bg_color = color

	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12

	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14

	panel.add_theme_stylebox_override(
		"panel",
		style
	)


# =========================================================
# ESTILO BOTÓN
# =========================================================

func _set_button_color(
	btn: Button,
	normal: Color,
	hover: Color,
	pressed: Color
):

	for state in [
		["normal", normal],
		["hover", hover],
		["pressed", pressed]
	]:

		var style = StyleBoxFlat.new()

		style.bg_color = state[1]

		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10

		btn.add_theme_stylebox_override(
			state[0],
			style
		)


# =========================================================
# EMPEZAR
# =========================================================

func _on_start():

	var audio = get_node_or_null(
		"AudioInstrucciones"
	)


	if audio:

		audio.stop()


	Events.minigame_confirmed.emit()

	queue_free()
