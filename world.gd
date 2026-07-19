extends Node
class_name World

@export var chamberscene: PackedScene
@export var interchamberscene: PackedScene

const finitelimit = 6

func setseed(seed: int):
	Global.worldseed = seed
	Global.dice.seed = seed

func setglobals():
	Global.dice = RandomNumberGenerator.new()
	setseed(randi())
	for setting in Global.Setting.values():
		print(setting)
		Global.settings[setting] = false
	Global.finishcause = ""
	Global.player = $Player
	Global.world = self
	Global.chamber = null
	Global.chamberindex = 0
	print("world seed: " + str(Global.worldseed))

func start():
	setglobals()
	loadchamber(true, IntermissionChamber.IntermissionClass.START)

func finish():
	loadchamber(true, IntermissionChamber.IntermissionClass.END)

func phasewarp():  # why is it called phase warp? because it warps your phase, obviously.
	for color in 3:
		$Player.score[color] = max(0, Global.player.score[color] - Global.chamber.deltascore[color] - 4)
	loadchamber()

func enterdoor():
	Global.chamberindex += 1
	if not Global.settings[Global.Setting.INFINITE] and Global.chamberindex == finitelimit + 1:
		Global.finishcause = "You completed all " + str(finitelimit) + " chambers."
		finish()
		return
	loadchamber()

func loadchamber(isinter: bool = false, interclass: IntermissionChamber.IntermissionClass = -1):
	$Player.stopusingterminal()
	$Player.process_mode = Node.PROCESS_MODE_DISABLED
	if Global.chamber != null:
		Global.chamber.process_mode = Node.PROCESS_MODE_DISABLED
	print("Chamber #" + str(Global.chamberindex))
	$AmbientLoadingShader.process_mode = Node.PROCESS_MODE_INHERIT
	$AmbientLoadingShader.visible = true
	$AmbientLoadingShader.material.set_shader_parameter("displacement", randf())
	if Global.chamber != null:
		remove_child(Global.chamber)
	for i in 2:
		await get_tree().process_frame
	var chamber = chamberscene.instantiate()
	if isinter:
		chamber = interchamberscene.instantiate()
		chamber.interclass = interclass
	chamber.create()
	add_child(chamber)
	$AmbientLoadingShader.process_mode = Node.PROCESS_MODE_DISABLED
	$AmbientLoadingShader.visible = false
