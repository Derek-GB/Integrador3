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
	
	synchronize_slider(MUSIC_BUS,btn_music_control)
	synchronize_slider(SFX_BUS,btn_sfx_control)
		
	btn_music_control.value_changed.connect(
		func (value):
		AudioManager.change_volume(MUSIC_BUS, value)
	)
	
	btn_sfx_control.value_changed.connect(
		func (value):
			AudioManager.change_volume(SFX_BUS, value)
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
