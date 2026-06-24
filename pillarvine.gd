extends TerrainFeature
class_name PillarVine  # we're going up, up, up, it's our moment...

static var cost = 1

static func generate():
	var cham = Global.chamber
	var candidates = []
	var finalvines = []
	for x in cham.size:
		for z in cham.size:
			var streak = []
			for y in cham.size:
				var point = Vector3(x, y, z)
				if Global.meshtypes[cham.voxmap[point]] != Global.MeshType.CUBE and point != cham.doorpos:
					streak.append(point)
				else:
					if len(streak) >= cham.approxsidelen():
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
			cham.setvox(point, Global.Vox.PILLARVINE)
