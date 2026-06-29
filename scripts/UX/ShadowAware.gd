extends Light3D

func _ready() -> void:
	shadow_enabled = SettingsManager.shadows_enabled
	SettingsManager.settings_changed.connect(_on_settings_changed)

func _on_settings_changed() -> void:
	shadow_enabled = SettingsManager.shadows_enabled
