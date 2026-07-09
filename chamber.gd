extends Node
class_name Chamber

@export var face: PlaneMesh
@export var anomscene: PackedScene
@export var doorscene: PackedScene
@export var compscene: PackedScene
const cardinals = [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]
const bases = {
	Vector3.UP: Basis(Vector3.RIGHT, Vector3.UP, Vector3.BACK),
	Vector3.DOWN: Basis(Vector3.LEFT, Vector3.DOWN, Vector3.BACK),
	Vector3.RIGHT: Basis(Vector3.FORWARD, Vector3.RIGHT, Vector3.DOWN),
	Vector3.LEFT: Basis(Vector3.BACK, Vector3.LEFT, Vector3.DOWN),
	Vector3.FORWARD: Basis(Vector3.LEFT, Vector3.FORWARD, Vector3.DOWN),
	Vector3.BACK: Basis(Vector3.RIGHT, Vector3.BACK, Vector3.DOWN)
}
var plantbases = [bases[Vector3.LEFT].rotated(Vector3.UP, PI / 4), bases[Vector3.FORWARD].rotated(Vector3.UP, PI / 4)]
var size: int
var voxmap: Dictionary[Vector3, Global.Vox]
var air: Dictionary[Vector3, bool]  # once again no sets {._.}
var noise: FastNoiseLite
var surfacetools: Dictionary[Global.Vox, SurfaceTool]
var entities: Array[PhysicsBody3D]
var anomalies: Array[Anomaly]
var computers: Array[Computer]
var door: StaticBody3D
var doorpos: Vector3
var starttime: float

func rescale(value: float, minval: float, maxval: float):
	return value * (maxval - minval) / 2 + (maxval + minval) / 2

func setvox(point: Vector3, voxtype: Global.Vox):
	voxmap[point] = voxtype
	if voxtype == Global.Vox.AIR and point not in air:
		air[point] = true
	if voxtype != Global.Vox.AIR and point in air:
		air.erase(point)

func randomair():
	return Global.dicechoose(air.keys())

func issolid(point: Vector3):
	return point not in voxmap or Global.meshtypes[voxmap[point]] == Global.MeshType.CUBE

func isair(point: Vector3):
	return point in voxmap and Global.meshtypes[voxmap[point]] == Global.MeshType.AIR

func ground(point: Vector3):
	if issolid(point):
		return null
	while true:
		var stepdown = point + Vector3.DOWN
		if issolid(stepdown):
			return point
		point = stepdown

func spawnpoint():
	while true:
		var point = ground(randomair()) + Vector3(0.5, 0, 0.5)
		var distanced = true
		for entity in entities:
			if Global.dist(point, entity.position) < (24 if entity == Global.player else 4):
				distanced = false
		if distanced:
			return point

func approxsidelen():
	return len(air) ** (1 / 3.)

func create():
	print("starting!")
	Global.chamber = self
	terragen()
	print("terra genned!")
	if not goodfloodfill():
		print("regenerating...")
		resetvars()
		create()
		return
	placefeatures()
	print("features placed!")
	print("cave aquifered!")
	createmeshes()
	print("meshes created!")
	anomalize()
	print("anomalies materialized!")
	welcomeplayer()
	print("player welcomed!")
	print("done!")
	self.starttime = Time.get_ticks_msec()

func resetvars():
	size = 0
	voxmap = {}
	air = {}
	noise = null
	surfacetools = {}
	entities = []
	anomalies = []
	door = null
	doorpos = Vector3(0, 0, 0)

func terragen():
	metaterragen()
	actualterragen()
	if len(air) < 512:
		terragen()
		return
	fillsmallgaps()

func metaterragen():
	size = floor(2 ** Global.dice.randf_range(6, 7)) ###
	noise = FastNoiseLite.new()
	noise.seed = Global.dice.randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.2 / sqrt(size) * 2 ** Global.dice.randf_range(-0.5, 0.5)
	if Global.hasmod(Global.Modifier.LESSSPACE):
		noise.frequency *= 2
	if Global.hasmod(Global.Modifier.MORESPACE):
		noise.frequency *= 0.5
	noise.fractal_octaves = 4

func actualterragen():
	for x in size:
		for y in size:
			for z in size:
				var point = Vector3(x, y, z)
				var spheubedist = 0
				for axis in 3:
					spheubedist += ((point[axis] + 0.5) * 2 / size - 1) ** 4
				var noiseval = noise.get_noise_3d(x + 0.5, (y + 0.5) * Global.ifmod(1, 2, Global.Modifier.SQUASH) * Global.ifmod(1, 0.5, Global.Modifier.STRETCH), z + 0.5)
				if Global.hasmod(Global.Modifier.ISLANDS):
					noiseval = asin(abs(noiseval) * -2 + 1) * 2 / PI
				if rescale(noiseval, 0, 1) < spheubedist * 0.5 + 0.5 or (min(x, y, z) == 0 or max(x, y, z) == size - 1):
					setvox(point, Global.Vox.STONE)
				else:
					setvox(point, Global.Vox.AIR)

func goodfloodfill():
	var frontier = [randomair()]
	var flood = {frontier[0]: true}
	while true:
		var newfrontier = []
		for point in frontier:
			for disp in cardinals:
				var npoint = point + disp
				if npoint not in flood and not issolid(npoint):
					flood[npoint] = true
					newfrontier.append(npoint)
		frontier = newfrontier
		if len(frontier) == 0:
			break
	var filling = []
	for point in air:
		if point not in flood:
			filling.append(point)
	for point in filling:
		setvox(point, Global.Vox.STONE)
	return len(air) >= size ** 3 * 2 ** -4.

func placefeatures():
	placelights()
	placeplayer()
	placedoor()
	placecomputers()
	featureterrain()

func placeplayer():
	Global.player.position = spawnpoint()
	entities.append(Global.player)

func featureterrain():
	if Global.hasmod(Global.Modifier.DOORPLANT):
		var cuberadius = approxsidelen() * sqrt(3) / 4
		for x in range(floor(doorpos.x - cuberadius), ceil(doorpos.x + cuberadius) + 1):
			for y in range(floor(doorpos.y - cuberadius), ceil(doorpos.y + cuberadius) + 1):
				for z in range(floor(doorpos.z - cuberadius), ceil(doorpos.z + cuberadius) + 1):
					var point = Vector3(x, y, z)
					if point == ground(point) and randf() < 0.25:
						setvox(point, Global.Vox.DOORPLANT)
	if Global.hasmod(Global.Modifier.PILLARVINE):
		var candidates = []
		var finalvines = []
		for x in size:
			for z in size:
				var streak = []
				for y in size:
					var point = Vector3(x, y, z)
					if not issolid(point) and point != doorpos:
						streak.append(point)
					else:
						if len(streak) >= approxsidelen():
							candidates.append(streak)
						streak = []
		candidates.shuffle()
		for vine in candidates:
			var distant = true
			for finalist in finalvines:
				if Global.dist(vine[0], finalist[0]) < 16:
					distant = false
					break
			if distant:
				finalvines.append(vine)
		for vine in finalvines:
			for point in vine:
				setvox(point, Global.Vox.PILLARVINE)

func placedoor():
	door = doorscene.instantiate()
	var furthest
	var furthestdist = -INF
	for i in 64:
		var point = spawnpoint()
		var distance = Global.dist(point, Global.player.position)
		if distance > furthestdist:
			furthestdist = distance
			furthest = point
	door.position = furthest
	doorpos = door.position - Vector3(0.5, 0, 0.5)
	for x in range(doorpos.x - 1, doorpos.x + 2):
		for z in range(doorpos.z - 1, doorpos.z + 2):
			setvox(Vector3(x, doorpos.y - 1, z), Global.Vox.STONE)
	entities.append(door)
	add_child(door)

func placecomputers():
	var classlist = Computer.normalclasses.duplicate()
	if Global.settings[Global.Setting.SIMPLE]:
		classlist.erase(Computer.TerminalClass.MOD)
	for termclass in classlist:
		var computer = compscene.instantiate()
		computer.create(termclass)
		var pos
		var spin
		while true:
			pos = spawnpoint()
			spin = PI / 2 * floor(Global.dice.randf() * 4)
			var userpos = pos - Vector3(0.5, 0, 0.5) + Vector3.BACK.rotated(Vector3.UP, spin)
			if issolid(userpos + Vector3.DOWN) and not issolid(userpos) and not issolid(userpos + Vector3.UP):
				break
		computer.position = pos + Vector3.UP * 2
		computer.rotation.y = spin
		entities.append(computer)
		computers.append(computer)
		add_child(computer)

func placelights():
	var nooks = []
	for point in air:
		var isnook = true
		for axis in 3:
			var hidden = false
			for dir in Global.pm:
				var disp = Vector3.ZERO
				disp[axis] += dir
				if issolid(point + disp):
					hidden = true
			if not hidden:
				isnook = false
		if isnook:
			nooks.append(point)
	var lightquant = min(32, ceil(approxsidelen() * 0.5))
	var bestlighting = -INF
	var besttry
	for attempt in 32:
		var lights = []
		for i in lightquant:
			var point
			while true:
				point = Global.dicechoose(nooks)
				if point not in lights:
					break
			lights.append(point)
		var lighting = 0
		for first in len(lights) - 1:
			for second in range(first + 1, len(lights)):
				lighting += Global.dist(lights[first], lights[second])
		if lighting > bestlighting:
			bestlighting = lighting
			besttry = lights
	for point in besttry:
		var light = OmniLight3D.new()
		light.omni_range = approxsidelen() * 2 ** Global.dice.randf_range(-1, 1)
		light.light_energy = 4
		light.position = point + Vector3.ONE / 2.
		add_child(light)
		setvox(point, Global.Vox.LIGHT)

func fillsmallgaps():
	for x in size:
		for z in size:
			var streak = 0
			for y in size + 1:
				var point = Vector3(x, y, z)
				if not issolid(point):
					streak += 1
				else:
					if streak < 3:
						for yy in range(y - streak, y):
							setvox(Vector3(x, yy, z), Global.Vox.STONE)
					streak = 0

func createmeshes():
	for voxtype in Global.Vox.values():
		if Global.meshtypes[voxtype] != Global.MeshType.AIR:
			var st = SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			st.set_material(Global.materials[voxtype])
			surfacetools[voxtype] = st
	for x in size:
		for y in size:
			for z in size:
				var point = Vector3(x, y, z)
				var voxtype = voxmap[point]
				var meshtype = Global.meshtypes[voxtype]
				if meshtype != Global.MeshType.AIR:
					var st = surfacetools[voxtype]
					if meshtype == Global.MeshType.CUBE:
						for disp in cardinals:
							var npoint = point + disp
							if (not issolid(npoint) or (npoint in voxmap and voxmap[npoint] == Global.Vox.GLASS and voxtype != Global.Vox.GLASS)):
								st.append_from(face, 0, Transform3D(bases[disp], point + disp / 2. + Vector3.ONE / 2.))
					if meshtype == Global.MeshType.PLANT:
						for basis in plantbases:
							st.append_from(face, 0, Transform3D(basis, point + Vector3.ONE / 2.))
	for voxtype in Global.Vox.values():
		if voxtype in surfacetools:
			var st = surfacetools[voxtype]
			var meshinstance = MeshInstance3D.new()
			meshinstance.mesh = st.commit()
			if meshinstance.mesh.get_surface_count() != 0:
				if Global.meshtypes[voxtype] == Global.MeshType.CUBE:
					meshinstance.create_trimesh_collision()
				add_child(meshinstance)

func anomalize():
	var colorder = Global.diceshuffle(Anomaly.AnomColor.values())
	for i in int(len(air) * 2 ** Global.ifmod(-12.5, -11.5, Global.Modifier.MOREANOMS)): #(-11 - 3 * 2 ** (Global.chamberindex * -0.1)):
		var anomaly = anomscene.instantiate()
		anomaly.position = spawnpoint() + Vector3.UP
		anomalies.append(anomaly)
		entities.append(anomaly)
		add_child(anomaly)
	anomalies.sort_custom(func(one, two): return one.position.y > two.position.y)
	for i in len(anomalies):
		anomalies[i].create(colorder[Global.ifmod(i % 3, floor(i * 3. / len(anomalies)), Global.Modifier.SORTANOMS)])

func welcomeplayer():
	Global.player.pan = Vector3.UP * randf() * TAU
	Global.player.get_node("Camera3D").rotation = Global.player.pan
	Global.player.process_mode = Node.PROCESS_MODE_INHERIT

func _process(delta: float):
	updatestatlabel()
	updatescorelabel()
	updatemodlabel()
	updatebalancelabel()

func _input(event: InputEvent):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Global.player.terminalinuse == null:
		if event.is_action_pressed("stattoggle"):
			$StatLabel.visible = not $StatLabel.visible
		if event.is_action_pressed("scoretoggle"):
			$ScoreLabel.visible = not $ScoreLabel.visible
		if event.is_action_pressed("modtoggle"):
			$ModLabel.visible = not $ModLabel.visible
		if event.is_action_pressed("balancetoggle"):
			$BalanceLabel.visible = not $BalanceLabel.visible
		if event.is_action_pressed("forcecontinue"):
			Global.world.phasewarp()

func updatestatlabel():
	$StatLabel.text = ""
	$StatLabel.text += updatehealth() + "\n"
	$StatLabel.text += updateammo() + "\n"
	$StatLabel.text += updatecompass() + "\n"
	$StatLabel.text += updatesonar() + "\n"

func updatescorelabel():
	$ScoreLabel.text = ""
	for color in 3:
		$ScoreLabel.text += "[color=" + Anomaly.actualcolor[color].to_html() + "]"
		$ScoreLabel.text += Global.padnumstring(Global.player.score[color], 3) + " x "
		$ScoreLabel.text += Global.padnumstring(Global.player.scoremult(color), 2, 2) + " = "
		$ScoreLabel.text += Global.padnumstring(Global.player.productscore(color), 4) + "\n"
	$ScoreLabel.text += "[color=white]"
	$ScoreLabel.text += Global.padnumstring(Global.player.totalscore(), 4)

func updatemodlabel():
	$ModLabel.text = ""
	for mod in Global.player.modifiers:
		$ModLabel.text += "\n" + Global.modnames[mod]

func updatebalancelabel():
	$BalanceLabel.text = ""
	$BalanceLabel.text += "Balance: "
	$BalanceLabel.text += Global.padnumstring(Global.player.balance, 1, 0, true)

func OoOoOo(quantity: String, amount: int):
	return quantity + ":" + " ".repeat(8 - len(quantity)) + "O".repeat(amount) + "o".repeat(6 - amount)

func updatehealth():
	return OoOoOo("Health", max(0, Global.player.health))

func updateammo():
	return OoOoOo("Ammo", ceil(Global.player.ammo * 6. / Global.player.maxammo()))

func updatecompass():
	#var prox = 1 - min(1, Global.dist(Global.player.position, door.position) / (approxsidelen() * sqrt(3)))
	#var playerangle = fmod(Global.player.get_node("Camera3D").rotation.y, TAU)
	#var doorangle = atan2(door.position.x - Global.player.position.x, door.position.z - Global.player.position.z)
	#var diff = playerangle - doorangle
	#var angdiff = min(abs(diff - TAU), abs(diff), abs(diff + TAU))
	#return OoOoOo("Compass", floor(angdiff / PI * 7))
	if door == null:
		return OoOoOo("Compass", 6)
	var camera = Global.player.get_node("Camera3D")
	var camangle = camera.get_node("CamVector").global_position - camera.global_position
	var doorangle = (door.position - Global.player.position).normalized()
	var angdiff = (doorangle - camangle).length() * 0.5
	return OoOoOo("Compass", (1 - angdiff) * 7)
		# why do angle math when you can use rotated vectors?  :D

func updatesonar():
	return OoOoOo("Sonar", min(Global.player.getfollowers(), 6))
