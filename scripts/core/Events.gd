extends Node

# Cross-node signals (separate nodes)
##Cambio de turno
signal turn_changed(player_index: int)
##Aviso de sonido a reproducir
signal play_sound(sound_name: String)
