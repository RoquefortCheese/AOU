extends TerrainFeature
class_name DoorStone

static func cost():
	return 5  ## five what? apples? bananas?

static func generate():
	var cham = Global.chamber
	for x in cham.size:
		for y in cham.size:
			for z in cham.size:
				var point = Vector3(x, y, z)
				if cham.voxmap[point] == Global.Vox.STONE:
					var reldist = Global.dist(point + Vector3.ONE / 2., cham.door.position) / (cham.approxsidelen * sqrt(3))
					if cham.dice.randf() < (cos(min(reldist * 2, 1) * PI) ** (1 / 3.) + 1) / 2:
						cham.voxmap[point] = Global.Vox.DOORSTONE
