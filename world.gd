extends Node
class_name World

@export var chamberscene: PackedScene
@export var startchamberscene: PackedScene

func _ready():
	setglobals()
	loadchamber()

func setglobals():
	Global.worldseed = randi()
	Global.dice = RandomNumberGenerator.new()
	Global.dice.seed = Global.worldseed
	print("world seed: " + str(Global.worldseed))
	Global.world = self
	Global.chamberindex = 0 ###


func loadchamber():
	$Player.process_mode = Node.PROCESS_MODE_DISABLED
	if Global.chamber != null:
		Global.chamber.process_mode = Node.PROCESS_MODE_DISABLED
	print("Chamber #" + str(Global.chamberindex))
	$AmbientLoadingShader.process_mode = Node.PROCESS_MODE_ALWAYS
	$AmbientLoadingShader.visible = true
	$AmbientLoadingShader.material.set_shader_parameter("displacement", randf())
	if Global.chamber != null:
		remove_child(Global.chamber)
	for i in 2:
		await get_tree().process_frame
	var chamber = (startchamberscene if Global.chamberindex == 0 else chamberscene).instantiate()  ###
	chamber.create()
	add_child(chamber)
	$AmbientLoadingShader.process_mode = Node.PROCESS_MODE_DISABLED
	$AmbientLoadingShader.visible = false
