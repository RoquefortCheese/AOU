extends Node
class_name Chamber

@export var face: PlaneMesh
@export var anomscene: PackedScene
@export var doorscene: PackedScene
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
var dice: RandomNumberGenerator
var voxmap: Dictionary[Vector3, Global.Vox]
var air: Dictionary[Vector3, bool]  # once again no sets {._.}
var noise: FastNoiseLite
var surfacetools: Dictionary[Global.Vox, SurfaceTool]
var entities: Array[PhysicsBody3D]
var anomalies: Array[CharacterBody3D]
var door: StaticBody3D
var doorpos: Vector3
var timebudget: float
var cyclesdone: int
var starttime: float

func rescale(value: float, minval: float, maxval: float):
	return value * (maxval - minval) / 2 + (maxval + minval) / 2

func dicechoose(array: Array):
	return array[dice.randi_range(0, len(array) - 1)]

func setvox(point: Vector3, voxtype: Global.Vox):
	voxmap[point] = voxtype
	if voxtype == Global.Vox.AIR and point not in air:
		air[point] = true
	if voxtype != Global.Vox.AIR and point in air:
		air.erase(point)

func randomair():
	return dicechoose(air.keys())

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
			if Global.dist(point, entity.position) < (16 if entity == Global.player else 4):
				distanced = false
		if distanced:
			return point

func approxsidelen():
	return len(air) ** (1 / 3.)

func create(dice: RandomNumberGenerator):
	print("starting!")
	Global.chamber = self
	self.dice = dice
	terragen()
	print("terra genned!")
	if not goodfloodfill():
		print("regenerating...")
		create(dice)
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

func terragen():
	metaterragen()
	actualterragen()
	if len(air) < 64:
		terragen()
		return
	fillsmallgaps()

func metaterragen():
	size = floor(2 ** dice.randf_range(6, 7)) ###
	noise = FastNoiseLite.new()
	noise.seed = dice.randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.2 / sqrt(size) * 2 ** dice.randf_range(-0.5, 0.5)
	if Global.Modifier.LESSSPACE in Global.player.modifiers:
		noise.frequency *= 2
	if Global.Modifier.MORESPACE in Global.player.modifiers:
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
				if rescale(noise.get_noise_3d(x + 0.5, y + 0.5, z + 0.5), 0, 1) < spheubedist * 0.5 + 0.5 or (min(x, y, z) == 0 or max(x, y, z) == size - 1):
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
	placedoor()
	featureterrain()

func featureterrain():
	if Global.Modifier.DOORPLANT in Global.player.modifiers:
		var cuberadius = approxsidelen() * sqrt(3) / 4
		for x in range(floor(doorpos.x - cuberadius), ceil(doorpos.x + cuberadius) + 1):
			for y in range(floor(doorpos.y - cuberadius), ceil(doorpos.y + cuberadius) + 1):
				for z in range(floor(doorpos.z - cuberadius), ceil(doorpos.z + cuberadius) + 1):
					var point = Vector3(x, y, z)
					if point == ground(point) and randf() < 0.25:
						setvox(point, Global.Vox.DOORPLANT)
	if Global.Modifier.PILLARVINE in Global.player.modifiers:
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
	for i in 12:
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
	print(lightquant)
	var bestlighting = -INF
	var besttry
	for attempt in 32:
		var lights = []
		for i in lightquant:
			var point
			while true:
				point = dicechoose(nooks)
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
		light.omni_range = approxsidelen() * 2 ** dice.randf_range(-1, 1)
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
							if not issolid(npoint):
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
	Global.player.position = spawnpoint()
	for i in len(air) * 2 ** (-11 - 3 * 2 ** (Global.chamberindex * -0.1)):
		var anomaly = anomscene.instantiate()
		anomaly.create(dicechoose([Color.MAGENTA, Color.BLUE, Color.CYAN]))
		anomaly.position = spawnpoint() + Vector3.UP
		anomalies.append(anomaly)
		entities.append(anomaly)
		add_child(anomaly)

func welcomeplayer():
	Global.player.process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	print(approxsidelen())
	timebudget = approxsidelen() ** 2 / 64 * (1 + 2 * 2 ** (Global.chamberindex * -0.2))
	cyclesdone = 0

func _process(delta: float):
	countdown()
	updatelabel(delta)

func countdown():
	if floor(Global.time() / timebudget) > cyclesdone:
		Global.player.impacthealth(-1)
		cyclesdone += 1

func updatelabel(delta: float):
	$StatLabel.text = ""
	$StatLabel.text += updatehealth() + "\n"
	$StatLabel.text += updatecompass() + "\n"
	$StatLabel.text += updatecountdown() + "\n"

func OoOoOo(quantity: String, amount: int):
	return quantity + ":" + " ".repeat(8 - len(quantity)) + "O".repeat(amount) + "o".repeat(6 - amount)

func updatehealth():
	return OoOoOo("Health", Global.player.health)

func updatecompass():
	var prox = 1 - min(1, Global.dist(Global.player.position, door.position) / (approxsidelen() * sqrt(3)))
	return OoOoOo("Compass", ceilf(prox * 6))

func updatecountdown():
	var timeleft = 1 - (fmod(Global.time(), timebudget) / timebudget)
	return OoOoOo("Time", min(6, floor(timeleft * 7)))
