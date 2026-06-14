extends Node

#GameManager signals
##Cambio de turno
signal turn_changed(player_index: int)
##Aviso de sonido a reproducir
signal play_sound(sound_name: String)

#ActionCard signals
##Acción completada, con tipo y valor específico
signal action_completed(type: String, value: int)

#QuestionCard signals
##Resultado de la respuesta a una pregunta, indicando si es correcta o no
signal answer_result(correct: bool)

#Minigame signals
##Minijuego completado, aviso
signal puzzle_completed

#Dice signals
##Dado lanzado, con el número obtenido
signal dice_rolled(n: int)
##Lanzamiento de dado comenzado
signal roll_started
##Lanzamiento de dado finalizado
signal roll_finished(n: int)

#Piece signals
##Ficha llegó a un waypoint específico
signal reached_end
##Ficha pisó un waypoint específico, con su índice
signal stepped_on(index: int)

#DiceOverlay signals
##Overlay de dado completado, con el número obtenido
signal overlay_done(n: int)
