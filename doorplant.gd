extends Modifier
class_name DoorPlant

static func modtype():
	return Global.ModifierType.TERRAIN

static func generate():
	var cham = Global.chamber
	var doorpos = cham.doorpos
	var cuberadius = cham.approxsidelen() * sqrt(3) / 4
	for x in range(floor(doorpos.x - cuberadius), ceil(doorpos.x + cuberadius) + 1):
		for y in range(floor(doorpos.y - cuberadius), ceil(doorpos.y + cuberadius) + 1):
			for z in range(floor(doorpos.z - cuberadius), ceil(doorpos.z + cuberadius) + 1):
				var point = Vector3(x, y, z)
				if point == cham.ground(point) and randf() < 0.25:
					cham.setvox(point, Global.Vox.DOORPLANT)
