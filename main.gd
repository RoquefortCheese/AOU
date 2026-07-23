extends Node
class_name Main

@export var worldscene: PackedScene

var world: World

func _ready():
	
	# don't mind this, just some atrocious spaghetti code to calculate numbers for dev purposes
	var counts = {}
	var costs = {}
	var scopes = {}
	var totalcount = 0
	var totalcost = 0
	var totalscope = 0
	for color in Anomaly.AnomColor.values():
		counts[color] = 0
		costs[color] = 0
		scopes[color] = 0
		for mod in Global.Modifier.values():
			if Global.modcolors[mod] == color:
				counts[color] += 1
				totalcount += 1
				costs[color] += Global.modcosts[mod]
				totalcost += Global.modcosts[mod]
				scopes[color] += abs(Global.modcosts[mod])
				totalscope += abs(Global.modcosts[mod])
		print(Anomaly.actualcolor[color].to_html() + " count: " + str(counts[color]))
		print(Anomaly.actualcolor[color].to_html() + " cost: " + str(costs[color]))
		print(Anomaly.actualcolor[color].to_html() + " scope: " + str(scopes[color]))
	print("total count: " + str(totalcount))
	print("total cost: " + str(totalcost))
	print("total scope: " + str(totalscope))
	
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
		if world != null and Global.player.terminalinuse == null:
			if world.process_mode == Node.PROCESS_MODE_DISABLED:
				world.hideshader()
				world.process_mode = Node.PROCESS_MODE_INHERIT
			else:
				world.showshader("PAUSED")
				world.process_mode = Node.PROCESS_MODE_DISABLED
	if event.is_action_pressed("forceend") and Global.player.terminalinuse == null:
		if world != null:
			Global.finishcause = "You chose to end the game."
			world.finish()
