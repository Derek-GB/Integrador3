extends Control
const MUSIC_BUS = "Music"
const SFX_BUS = "SFX"
const MASTER_BUS = "Master"
@onready var btn_music_control: HSlider = $Music
@onready var btn_sfx_control: HSlider = $SFX
@onready var panel: Panel = $Panel
@onready var leaf = $Leaf
@onready var leaf2 = $Leaf2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_refresh_sliders()
	
	btn_music_control.value_changed.connect(
	func(value):
		SettingsManager.preview_music_volume(value)
	)

	btn_music_control.drag_ended.connect(
		func(_changed: bool):
			if _changed:
				SettingsManager.save_settings()
	)
	
	btn_sfx_control.value_changed.connect(
	func(value):
		SettingsManager.preview_sfx_volume(value)
	)

	btn_sfx_control.drag_ended.connect(
		func(_changed: bool):
			if _changed:
				SettingsManager.save_settings()
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func synchronize_slider(name_bus: String, slider:HSlider) -> void:
	var bus_idx = AudioServer.get_bus_index(name_bus)
	var linear_vol = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	slider.value = linear_vol

func visible_panel(option: bool) -> void:
	panel.visible = option
	leaf.visible = option
	leaf2.visible = option

func _refresh_sliders() -> void:
	synchronize_slider(MUSIC_BUS, btn_music_control)
	synchronize_slider(SFX_BUS, btn_sfx_control)
