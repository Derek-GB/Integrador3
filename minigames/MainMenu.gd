extends Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	pass

# Casilla 3  - Puzzle mapa de riesgo
func _on_button_pressed() -> void:
	Events.set_minigame.emit(3)

# Casilla 9  - Limpia el río (basurero)
func _on_button_2_pressed() -> void:
	Events.set_minigame.emit(9)

# Casilla 13 - Esquiva los rayos
func _on_button_3_pressed() -> void:
	Events.set_minigame.emit(13)

# Casilla 15 - Desmonta la casa
func _on_button_4_pressed() -> void:
	Events.set_minigame.emit(15)

# Casilla 19 - Reforesta el bosque
func _on_button_5_pressed() -> void:
	Events.set_minigame.emit(19)

# Casilla 23 - Laberinto / rescata amigos
func _on_button_6_pressed() -> void:
	Events.set_minigame.emit(23)

# Casilla 25 - Protege la ladera
func _on_button_7_pressed() -> void:
	Events.set_minigame.emit(25)

# Casilla 29 - Terremoto / zona segura
func _on_button_9_pressed() -> void:
	Events.set_minigame.emit(29)

# Casilla 31 - Botiquín
func _on_button_10_pressed() -> void:
	Events.set_minigame.emit(31)

# Casilla 35 - Identifica el río diferente
func _on_button_11_pressed() -> void:
	Events.set_minigame.emit(35)

# Casilla 37 - Limpia el río (guante)
func _on_button_12_pressed() -> void:
	Events.set_minigame.emit(37)

# Casilla 42 - Construye la ruta segura
func _on_button_15_pressed() -> void:
	Events.set_minigame.emit(42)

# Casilla 44 - Fechas de vencimiento
func _on_button_14_pressed() -> void:
	Events.set_minigame.emit(44)

# Casilla 47 - Alarma inclusiva
func _on_button_17_pressed() -> void:
	Events.set_minigame.emit(47)

# Casilla 50 - Apaga el incendio
func _on_button_13_pressed() -> void:
	Events.set_minigame.emit(50)

# Casilla 53 - Alerta de deslizamiento
func _on_button_16_pressed() -> void:
	Events.set_minigame.emit(53)

# Casilla 60 - Derechos de la niñez (preguntas)
func _on_button_19_pressed() -> void:
	Events.set_minigame.emit(60)

# Casilla 63 - Alerta de maremoto
func _on_button_20_pressed() -> void:
	Events.set_minigame.emit(63)

# Casilla 67 - Repara las fugas
func _on_button_21_pressed() -> void:
	Events.set_minigame.emit(67)

# Casilla 70 - Repara el puente
func _on_button_22_pressed() -> void:
	Events.set_minigame.emit(70)

# Volver al selector de edad
func _on_button_26_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/UX/AgeSelector.tscn")
