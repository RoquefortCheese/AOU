extends TerrainFeature
class_name DoorStone

static var cost = 5  ## five what? apples? bananas?

static func generate():
	var cham = Global.chamber
	var doorpos = cham.door.position
	var cuberadius = cham.approxsidelen() * sqrt(3) / 4
	for x in range(doorpos.x - cuberadius, doorpos.x + cuberadius + 1):
		for y in range(doorpos.y - cuberadius, doorpos.y + cuberadius + 1):
			for z in range(doorpos.z - cuberadius, doorpos.z + cuberadius + 1):
				var point = Vector3(x, y, z)
				if point in cham.voxmap and cham.voxmap[point] == Global.Vox.STONE:
					cham.setvox(point, Global.Vox.DOORSTONE)
