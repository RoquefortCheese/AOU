extends Node3D

var ray: RayCast3D

func fire():
	var ray = Global.player.get_node("Camera3D/RayCast3D")
	if ray.is_colliding():
		var target = ray.get_collider()
		if is_instance_of(target, Anomaly):
			target.die(global_position)
		if is_instance_of(target, Computer):
			if Global.dist(target.position, ray.global_position) <= 1.1:
				Global.player.usingterminal = true

func _process(delta: float):
	var time = Global.time()
	position = Vector3(sin(time), sin(time * sqrt(2)), 0) * 0.0625
