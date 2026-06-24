extends Node
class_name World

@export var chamberscene: PackedScene
var dice: RandomNumberGenerator

func _ready():
	setglobals()
	manufacturedice()
	loadchamber()

func setglobals():
	Global.worldseed = 985991134
	print("world seed: " + str(Global.worldseed))
	Global.world = self

func manufacturedice():
	dice = RandomNumberGenerator.new()
	dice.seed = Global.worldseed

func loadchamber():
	$AmbientLoadingShader.process_mode = Node.PROCESS_MODE_ALWAYS
	$AmbientLoadingShader.visible = true
	$AmbientLoadingShader.material.set_shader_parameter("displacement", randf())
	if Global.chamber != null:
		remove_child(Global.chamber)
	for i in 2:
		await get_tree().process_frame
	var chamber = chamberscene.instantiate()
	chamber.create(dice)
	add_child(chamber)
	$AmbientLoadingShader.process_mode = Node.PROCESS_MODE_DISABLED
	$AmbientLoadingShader.visible = false

func enterdoor():
	$Player.process_mode = Node.PROCESS_MODE_DISABLED
	Global.chamber.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	loadchamber()
