extends MeshInstance3D

func line(point1: Vector3, point2: Vector3):
	mesh.size.z = Global.dist(point1, point2) + 0.2
	global_position = (point1 + point2) / 2.
	look_at(point2)
