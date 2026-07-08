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

func _process(delta: float):
	if Input.is_action_just_pressed("esc"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
