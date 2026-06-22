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
var size: int
var dice: RandomNumberGenerator
var voxmap: Dictionary[Vector3, Global.Vox]
var air: Dictionary[Vector3, bool]  # once again no sets {._.}
var groundmap: Dictionary[Vector3, Vector3]
var noise: FastNoiseLite
var surfacetools: Dictionary[Global.Vox, SurfaceTool]
var entities: Array[PhysicsBody3D]
var anomalies: Array[CharacterBody3D]
var door: StaticBody3D
var time: float
var score: int

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

func spawnpoint():
	while true:
		var point = groundmap[randomair()] + Vector3(0.5, 0, 0.5)
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
	placefeatures()
	print("features placed!")
	createmeshes()
	print("meshes created!")
	welcomeplayer()
	print("player welcomed!")
	anomalize()
	print("anomalies materialized!")
	print("done!")

func terragen():
	size = floor(2 ** dice.randf_range(6, 6)) ###
	noise = FastNoiseLite.new()
	noise.seed = dice.randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.2 / sqrt(size) * 2 ** dice.randf_range(-0.5, 0.5)
	noise.fractal_octaves = 4
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
	for x in size:
		for z in size:
			var streak = 0
			for y in size + 1:
				var point = Vector3(x, y, z)
				if point in voxmap and voxmap[point] == Global.Vox.AIR:
					streak += 1
				else:
					if streak < 3:
						for yy in range(y - streak, y):
							setvox(Vector3(x, yy, z), Global.Vox.STONE)
					streak = 0
	if len(air) == 0:
		terragen()
		return
	print("floodfilling...")
	var frontier = [randomair()]
	var flood = {frontier[0]: true}
	while true:
		var newfrontier = []
		for point in frontier:
			for disp in cardinals:
				var npoint = point + disp
				if npoint not in flood and voxmap[npoint] == Global.Vox.AIR:
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
	if len(air) < size ** 3 * 2 ** -4.:
		print("regenerating...")
		terragen()

func calculatestuff():
	for x in size:
		for z in size:
			var ground = null
			for y in size:
				var point = Vector3(x, y, z)
				if voxmap[point] == Global.Vox.AIR:
					if ground == null:
						ground = point
					groundmap[point] = ground
				else:
					ground = null

func placefeatures():
	placelights()
	calculatestuff()
	placedoor()
	featureterrain()

func featureterrain():
	for feature in Global.player.features:
		feature.generate()

func placedoor():
	door = doorscene.instantiate()
	door.position = spawnpoint()
	entities.append(door)
	add_child(door)

func placelights():
	var volumefactor = approxsidelen()
	var nooks = []
	for point in air:
		var isnook = true
		for axis in 3:
			var hidden = false
			for dir in Global.pm:
				var disp = Vector3.ZERO
				disp[axis] += dir
				if voxmap[point + disp] != Global.Vox.AIR:
					hidden = true
			if not hidden:
				isnook = false
		if isnook:
			nooks.append(point)
	var bestlighting = -INF
	var besttry
	for attempt in 32:
		var lights = []
		for i in 24:
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
		light.omni_range = volumefactor * 2 ** dice.randf_range(-1, 1)
		light.light_energy = 4
		light.position = point + Vector3.ONE / 2.
		add_child(light)
		setvox(point, Global.Vox.LIGHT)

func createmeshes():
	for voxtype in Global.Vox.values():
		if voxtype != Global.Vox.AIR:
			var st = SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			st.set_material(Global.materials[voxtype])
			surfacetools[voxtype] = st
	for x in size:
		for y in size:
			for z in size:
				var point = Vector3(x, y, z)
				var voxtype = voxmap[point]
				if voxtype != Global.Vox.AIR:
					var st = surfacetools[voxtype]
					for disp in cardinals:
						var npoint = point + disp
						if npoint in voxmap and voxmap[npoint] == Global.Vox.AIR:
							st.append_from(face, 0, Transform3D(bases[disp], point + disp / 2. + Vector3.ONE / 2.))
	for st in surfacetools.values():
		var meshinstance = MeshInstance3D.new()
		meshinstance.mesh = st.commit()
		if meshinstance.mesh.get_surface_count() != 0:
			meshinstance.create_trimesh_collision()
			add_child(meshinstance)

func anomalize():
	for i in len(air) * 2 ** -12.5:
		var anomaly = anomscene.instantiate()
		anomaly.create(dicechoose([Color.MAGENTA, Color.BLUE, Color.CYAN]))
		anomaly.position = spawnpoint() + Vector3.UP
		anomalies.append(anomaly)
		entities.append(anomaly)
		add_child(anomaly)

func welcomeplayer():
	Global.player.position = spawnpoint()
	Global.player.process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	time = 0

func _process(delta: float):
	updatelabel(delta)

func updatelabel(delta: float):
	$StatLabel.text = ""
	$StatLabel.text += updatescore(delta) + "\n"
	$StatLabel.text += updatecompass() + "\n"

func updatescore(delta: float):
	time += delta
	score = 1024 / 2 ** (time / 60)
	return str(score)

func updatecompass():
	var prox = 1 - min(1, Global.dist(Global.player.position, door.position) / (approxsidelen() * sqrt(3)))
	var strength = ceilf(prox * 6)
	return "O".repeat(strength) + "o".repeat(6 - strength)
