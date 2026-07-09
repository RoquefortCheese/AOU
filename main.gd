extends Node
class_name Main

@export var worldscene: PackedScene

var world: World

func _ready():
	newgame()

func newgame():
	if world != null:
		world.process_mode = Node.PROCESS_MODE_DISABLED
		remove_child(world)
	world = worldscene.instantiate()
	add_child(world)
	world.start()

func _input(event: InputEvent):
	if event.is_action_pressed("esc"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("pause"):
		if world != null:
			if world.process_mode == Node.PROCESS_MODE_DISABLED:
				world.process_mode = Node.PROCESS_MODE_INHERIT
			else:
				world.process_mode = Node.PROCESS_MODE_DISABLED
