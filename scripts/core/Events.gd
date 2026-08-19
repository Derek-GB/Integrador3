extends Node

# Cross-node signals (separate nodes)
##Cambio de turno
signal turn_changed(player_index: int)
##Aviso de sonido a reproducir
signal play_sound(sound_name: String)

signal visible_pointer(pointer: int, visible: bool)
signal forced_visible_pointer(pointer: int, visible: bool)

signal set_minigame(minigame:int)
signal minigame_intro_started    # cuando se abre el intro
signal minigame_confirmed        # cuando el jugador presiona "¡Empezar!"
signal minigame_finished      # cuando el minijuego terminav
signal minigame_result(won: bool)         # para determinar resultado

signal notify_pause(on_pause: bool)
signal notify_pause_for_minigame(on_pause: bool)

signal earthquake_triggered
signal earthquake_finished

signal player_movement_started
signal player_movement_ended

func _ready(): process_mode = Node.PROCESS_MODE_ALWAYS
