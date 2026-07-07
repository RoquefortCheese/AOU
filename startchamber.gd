extends Chamber
class_name StartChamber

const roomsize = 16
const ceilheight = 13
const anomroomsize = 8
const playerdisp = 10

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
				setvox(point, Global.Vox.GLASS)
	for x in size:
		for y in size:
			for z in size:
				var point = Vector3(x, y, z)
				if min(x, y, z) == 0 or max(x, z) == size - 1 or y >= ceilheight:
					setvox(point, Global.Vox.STONE)
				elif point not in voxmap or voxmap[point] != Global.Vox.GLASS:
					setvox(point, Global.Vox.AIR)

func goodfloodfill():
	return true

func placelights():
	for x in [2, anomroomsize - 2]:
		for z in [2, anomroomsize - 2]:
			var point = Vector3(x, 0, z)
			var light = OmniLight3D.new()
			light.omni_range = roomsize * 2
			light.light_energy = 4
			light.position = point + Vector3.ONE / 2.
			add_child(light)
			setvox(point, Global.Vox.LIGHT)

func placeplayer():
	Global.player.position = Vector3(playerdisp, 1, playerdisp)
	entities.append(Global.player)

func placedoor():
	door = doorscene.instantiate()
	door.position = Vector3(size - 3, 1, size - 3)
	doorpos = door.position - Vector3(0.5, 0, 0.5)
	entities.append(door)
	add_child(door)

func placecomputers():
	var axis = int(randf() * 2) * 2
	var computer = compscene.instantiate()
	computer.create(Computer.TerminalClass.START)
	entities.append(computer)
	computers.append(computer)
	add_child(computer)
	computer.position = Vector3(2.5, 3, 2.5)
	computer.position[axis] += anomroomsize
	computer.look_at_from_position(computer.position, Vector3(2.5, 3, 2.5))

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
