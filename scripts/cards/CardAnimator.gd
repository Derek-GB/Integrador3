extends Node
const ENTRY_TIME = 1
const EXIT_TIME = 0.65
const TURNING_TIME = 0.8
# =========================================================
# ANIMACIÓN DE ENTRADA
# =========================================================
func animate_entry(card_container: Control, btn: Button) -> void:
	var original_position := card_container.position
	disabled_buttons([btn], true)
	card_container.position.y += 350.0
	card_container.scale = Vector2(0.4, 0.4)
	card_container.rotation_degrees = -12.0
	
	var tween = card_container.create_tween().set_parallel(true)
	
	tween.tween_property(card_container, "position", original_position, ENTRY_TIME)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
	tween.tween_property(card_container, "scale", Vector2.ONE, ENTRY_TIME)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
		
	tween.tween_property(card_container, "rotation_degrees", 0.0, ENTRY_TIME)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	await tween.finished
	disabled_buttons([btn], false)


# =========================================================
# ANIMACIÓN DE VOLTEAR
# =========================================================
func flip_card(card_container: Control, front_side: Control, back_panel: Control, btns: Array) -> void:
	disabled_buttons(btns,true)
	
	var tween = card_container.create_tween()
	
	tween.parallel().tween_property(card_container, "scale:x", 0.0, EXIT_TIME)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)
		
	tween.parallel().tween_property(card_container, "scale:y", 1.12, EXIT_TIME)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
	tween.parallel().tween_property(card_container, "rotation_degrees", 6.0, EXIT_TIME)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(func():
		front_side.visible = false
		back_panel.visible = true
	)
	
	tween.parallel().tween_property(card_container, "scale:x", 1.0, TURNING_TIME)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
	tween.parallel().tween_property(card_container, "scale:y", 1.0, TURNING_TIME)\
		.set_trans(Tween.TRANS_BOUNCE)\
		.set_ease(Tween.EASE_OUT)
		
	tween.parallel().tween_property(card_container, "rotation_degrees", 0.0, TURNING_TIME)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
	await tween.finished
	disabled_buttons(btns,false)


# =========================================================
# ANIMACIÓN DE SALIDA
# =========================================================
func animate_exit(card_container: Control, btns: Array) -> void:
	disabled_buttons(btns,true)
	
	var grab_tween = card_container.create_tween().set_parallel(true)
	
	grab_tween.tween_property(card_container, "scale", Vector2.ZERO, EXIT_TIME)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
		
	grab_tween.tween_property(card_container, "position:y", card_container.position.y - 80.0, 0.35)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)
		
	grab_tween.tween_property(card_container, "rotation_degrees", -15.0, EXIT_TIME)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
		
	await grab_tween.finished
	await card_container.get_tree().create_timer(0.4).timeout

func disabled_buttons(btns: Array, value:bool) -> void:
	for btn in btns:
		if is_instance_valid(btn) and btn is Button:
			btn.disabled = value
