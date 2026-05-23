extends Equipment

func fire():
	if ray.is_colliding(): #and Global.dist(ray.global_position, ray.get_collision_point()) <= 12:
		var target = ray.get_collider()
		if is_instance_of(target, Anomaly):
			target.die()

func _process(delta: float):
	var time = Global.time()
	position = Vector3(sin(time), sin(time * sqrt(2)), 0) * 0.0625
