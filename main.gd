extends Node

func _process(delta: float):
	if Input.is_action_just_pressed("esc"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
