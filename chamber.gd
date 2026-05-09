extends Node

@export var face: PlaneMesh
@export var anomscene: PackedScene
const cardinals = [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]
const bases = {
	Vector3.UP: Basis(Vector3.RIGHT, Vector3.UP, Vector3.BACK),
	Vector3.DOWN: Basis(Vector3.LEFT, Vector3.DOWN, Vector3.BACK),
	Vector3.RIGHT: Basis(Vector3.FORWARD, Vector3.RIGHT, Vector3.DOWN),
	Vector3.LEFT: Basis(Vector3.BACK, Vector3.LEFT, Vector3.DOWN),
	Vector3.FORWARD: Basis(Vector3.LEFT, Vector3.FORWARD, Vector3.DOWN),
	Vector3.BACK: Basis(Vector3.RIGHT, Vector3.BACK, Vector3.DOWN)
}
var pos: Vector3
var size: int
var voxmap: Dictionary[Vector3, Global.Vox]
var air: Array[Vector3]
var groundmap: Dictionary[Vector3, Vector3]
var dice: RandomNumberGenerator
var noise: FastNoiseLite
var surfacetools: Dictionary[Global.Vox, SurfaceTool]

func rescale(value: float, min: float, max: float):
	return value * (max - min) / 2 + (max + min) / 2

func dicechoose(array: Array):
	return array[dice.randi_range(0, len(array) - 1)]

func randomair():
	return dicechoose(air)

func genair():
	air = []
	for x in range(size):
		for y in range(size):
			for z in range(size):
				var point = Vector3(x, y, z)
				if voxmap[point] == Global.Vox.AIR:
					air.append(point)

func create(pos: Vector3, size: int):
	print("starting!")
	self.pos = pos
	self.size = size
	manufacturedice()
	print("dice manufactured!")
	terragen()
	print("terra genned!")
	calculatestuff()
	print("stuff calculated!")
	createvisuals()
	print("visuals created!")
	anomalize()
	print("anomalies materialized!")
	welcomeplayer()
	print("done!")

func manufacturedice():
	dice = RandomNumberGenerator.new()
	dice.seed = Global.worldseed
	for axis in range(3):
		dice.seed += pos[axis]
		dice.seed = dice.randi()

func terragen():
	noise = FastNoiseLite.new()
	noise.seed = dice.randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.2 / sqrt(size)
	noise.fractal_octaves = 4
	for x in range(size):
		for y in range(size):
			for z in range(size):
				var point = Vector3(x, y, z)
				var spheubedist = 0
				for axis in range(3):
					spheubedist += ((point[axis] + 0.5) * 2 / size - 1) ** 4
				if (min(x, y, z) == 0 or max(x, y, z) == size - 1) or rescale(noise.get_noise_3d(x + 0.5, y + 0.5, z + 0.5), 0, 1) < spheubedist * 0.5 + 0.5:
					voxmap[point] = Global.Vox.STONE
				else:
					voxmap[point] = Global.Vox.AIR
	for x in range(size):
		for z in range(size):
			var streak = 0
			for y in range(size + 1):
				var point = Vector3(x, y, z)
				if point in voxmap and voxmap[point] == Global.Vox.AIR:
					streak += 1
				else:
					if streak < 3:
						for yy in range(y - streak, y):
							voxmap[Vector3(x, yy, z)] = Global.Vox.STONE
					streak = 0
	genair()
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
		voxmap[point] = Global.Vox.STONE
	genair()
	if len(air) < size ** 3 * 2 ** -4:
		print("regenerating...")
		terragen()

func calculatestuff():
	for x in range(size):
		for z in range(size):
			var ground = null
			for y in range(size):
				var point = Vector3(x, y, z)
				if voxmap[point] == Global.Vox.AIR:
					if ground == null:
						ground = point
					groundmap[point] = ground
				else:
					ground = null

func createvisuals():
	createmeshes()
	placelights()

func createmeshes():
	for voxtype in Global.Vox.values():
		if voxtype != Global.Vox.AIR:
			var st = SurfaceTool.new()
			st.set_material(Global.materials[voxtype])
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			surfacetools[voxtype] = st
	for x in range(size):
		for y in range(size):
			for z in range(size):
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
		meshinstance.create_trimesh_collision()
		add_child(meshinstance)

func placelights():
	var lighting = {}
	for point in air:
		lighting[point] = 0
	for i in range(8):
		var light = OmniLight3D.new()
		light.omni_range = 2 ** dice.randf_range(4, 7)
		var lightpos
		while true:
			lightpos = randomair()
			if i == 0 or dice.randf() ** 16 >= lighting[lightpos] / i:
				break
		light.position = lightpos + Vector3.ONE / 2.
		for point in lighting:
			lighting[point] += 1 / Global.dist(lightpos, point)
		add_child(light)
		
		var sphere = MeshInstance3D.new()
		sphere.mesh = SphereMesh.new()
		sphere.position = light.position
		sphere.mesh.material = StandardMaterial3D.new()
		sphere.mesh.material.albedo_color = Color.YELLOW
		sphere.mesh.material.shading_mode = 0
		add_child(sphere)

func anomalize():
	for i in range(len(air) * 0.0004):
		var anomaly = anomscene.instantiate()
		anomaly.create(self, dicechoose([Color.MAGENTA, Color.BLUE, Color.CYAN]))
		anomaly.position = randomair() + Vector3(0.5, 1, 0.5)
		add_child(anomaly)

func welcomeplayer():
	Global.player.position = groundmap[randomair()] + Vector3(0.5, 0, 0.5)
