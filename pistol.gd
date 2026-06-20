extends Equipment
var material: StandardMaterial3D

func equip():
	super.equip()
	material = $PistolModel.mesh.surface_get_material(0)

func fire():
	var hit = false
	if ray.is_colliding():
		var target = ray.get_collider()
		if is_instance_of(target, Anomaly):
			target.die(global_position)
			hit = true

func _process(delta: float):
	var time = Global.time()
	position = Vector3(sin(time), sin(time * sqrt(2)), 0) * 0.0625
