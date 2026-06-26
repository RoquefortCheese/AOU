extends Modifier
class_name PillarVine

static func modtype():
	return Global.ModifierType.TERRAIN

static func generate():
	var cham = Global.chamber
	var candidates = []
	var finalvines = []
	for x in cham.size:
		for z in cham.size:
			var streak = []
			for y in cham.size:
				var point = Vector3(x, y, z)
				if not cham.issolid(point) and point != cham.doorpos:
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
