extends Node3D

signal overlay_done(n: int)

@onready var dimmer: ColorRect = $CanvasLayer/Control/Dimmer
@onready var dado_interno = $CanvasLayer/Control/ViewportContainer/DiceViewport/Dado

var ultimo_resultado: int = 0

func _ready() -> void:
	visible = false
	dimmer.color.a = 0.0
	$CanvasLayer/Control/ViewportContainer.visible = false

func mostrar(forced_result: int = -1) -> void:
	print("DiceOverlay: mostrar() llamado, forced=", forced_result)
	print(get_stack())
	$CanvasLayer/Control/ViewportContainer.visible = true
	visible = true
	# Fade in
	var tw := create_tween().set_parallel(true)
	tw.tween_property(dimmer, "color:a", 0.65, 0.3)
	await tw.finished

	# Tirar el dado interno
	await dado_interno.roll()   # siempre, CPU o humano
	ultimo_resultado = dado_interno._result
	#if forced_result == -1:
		#await dado_interno.roll()
	#else:
		#await dado_interno.roll_cpu(forced_result)

	var resultado: int = dado_interno._result

	# Fade out
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(dimmer, "color:a", 0.0, 0.4)
	await tw2.finished

	$CanvasLayer/Control/ViewportContainer.visible = false
	visible = false
	overlay_done.emit(resultado)
