extends Node3D

var ray: RayCast3D

func fire():
	ray = Global.player.get_node("Camera3D/RayCast3D")
	if ray.is_colliding():
		var target = ray.get_collider()
		if target is Anomaly:
			target.die(global_position, true)
		if target is Computer:
			if Global.dist(target.position, ray.global_position) <= 1.5:
				Global.player.useterminal(target)

func _process(delta: float):
	var time = Global.time()
	position = Vector3(sin(time), sin(time * sqrt(2)), 0) * 0.0625
