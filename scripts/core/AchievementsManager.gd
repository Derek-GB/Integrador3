extends RefCounted
class_name AchievementsManager

const ACHIEVEMENTS_PATH := "user://achievements.cfg"
const SECTION := "achievements"
const KEY_GAME_COMPLETED := "game_completed_once"

static func unlock_game_completed() -> void:
	var config := ConfigFile.new()
	if FileAccess.file_exists(ACHIEVEMENTS_PATH):
		var err := config.load(ACHIEVEMENTS_PATH)
		if err != OK:
			push_error("AchievementsManager: Error al cargar " + ACHIEVEMENTS_PATH)
	
	config.set_value(SECTION, KEY_GAME_COMPLETED, true)
	var save_err := config.save(ACHIEVEMENTS_PATH)
	if save_err != OK:
		push_error("AchievementsManager: Error al guardar " + ACHIEVEMENTS_PATH)
	else:
		print("AchievementsManager: Logro 'game_completed_once' guardado con éxito en user://achievements.cfg")

static func is_game_completed() -> bool:
	if not FileAccess.file_exists(ACHIEVEMENTS_PATH):
		return false
	
	var config := ConfigFile.new()
	var err := config.load(ACHIEVEMENTS_PATH)
	if err != OK:
		return false
	
	return config.get_value(SECTION, KEY_GAME_COMPLETED, false)
