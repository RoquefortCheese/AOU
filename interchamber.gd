extends Chamber
class_name IntermissionChamber

enum IntermissionClass {START, END}

const roomsize = 16
const anomroomsize = 8
const playerdisp = 10

var interclass: IntermissionClass
var doorcorner: int

func incorner(object: Node3D, reference: Vector3, spin: bool, corner: int):
	var axis = corner * 2
	object.position = Vector3.ZERO
	object.position[axis] = anomroomsize + reference.z
	if spin:
		object.look_at_from_position(object.position, Vector3.ZERO)
	object.position[2 - axis] = reference.x
	object.position.y = reference.y

func spawnpoint():
	while true:
		var point = ground(randomair()) + Vector3(0.5, 0, 0.5)
		var distanced = true
		for entity in entities:
			if Global.dist(point, entity.position) < 2:
				distanced = false
		if distanced:
			return point

func terragen():
	size = roomsize
	for axis in [0, 2]:
		for line in anomroomsize + 1:
			for y in size:
				var point = Vector3.UP * y
				point[axis] = anomroomsize
				point[2 - axis] = line
				setvox(point, Global.Vox.DOUBLEGLASS)
	for x in size:
		for y in size:
			for z in size:
				var point = Vector3(x, y, z)
				if min(x, y, z) == 0 or max(x, y, z) == size - 1:
					setvox(point, Global.Vox.STONE)
				elif point not in voxmap or voxmap[point] != Global.Vox.DOUBLEGLASS:
					setvox(point, Global.Vox.AIR)

func garden():
	return

func largescalestuff():
	return

func goodfloodfill():
	return true

func placelights():
	for x in [2, anomroomsize - 2]:
		for z in [2, anomroomsize - 2]:
			for y in [0, size - 1]:
				var point = Vector3(x, y, z)
				var light = OmniLight3D.new()
				light.omni_range = roomsize * 2
				light.light_energy = 2
				light.position = point + Vector3.ONE / 2.
				add_child(light)
				setvox(point, Global.Vox.LIGHT)
	Global.player.get_node("Camera3D/OmniLight3D").omni_range = 0

func placeplayer():
	doorcorner = int(Global.dice.randf() * 2)
	incorner(Global.player, Vector3(2.5, 1, 4), false, 1 - doorcorner)
	entities.append(Global.player)

func placedoor():
	if interclass == IntermissionClass.END:
		return
	door = doorscene.instantiate()
	add_child(door)
	incorner(door, Vector3(3, 1, 2.5), false, doorcorner)
	doorpos = door.position - Vector3(0.5, 0, 0.5)
	entities.append(door)

func placecomputers():
	var axis = int(randf() * 2) * 2
	var computer = compscene.instantiate()
	computer.create({IntermissionClass.START: Computer.TerminalClass.START, IntermissionClass.END: Computer.TerminalClass.END}[interclass])
	add_child(computer)
	incorner(computer, Vector3(3, 3, 2.5), true, 1 - doorcorner)
	entities.append(computer)
	computers[computer.termclass] = computer

func anomalize():
	for i in 2:
		for color in 3:
			var anomaly = anomscene.instantiate()
			anomaly.create(color)
			anomaly.tamed = true
			var point
			while true:
				point = spawnpoint()
				if max(point.x, point.z) < anomroomsize:
					break
			anomaly.position = point + Vector3.UP
			anomalies.append(anomaly)
			entities.append(anomaly)
			add_child(anomaly)

func spinplayer():
	var camera = Global.player.get_node("Camera3D")
	camera.look_at(computers.values()[0].position)
	Global.player.pan = camera.rotation
