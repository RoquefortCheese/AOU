extends Equipment
const cooldowntime = 1.
var cooldown = 0
var material: StandardMaterial3D

func equip():
	super.equip()
	material = $PistolModel.mesh.surface_get_material(0)

func fire():
	if not cooldown:
		var hit = false
		if ray.is_colliding():
			var target = ray.get_collider()
			if is_instance_of(target, Anomaly):
				target.die(global_position)
				hit = true
		if not hit:
			cooldown = cooldowntime

func _process(delta: float):
	var time = Global.time()
	position = Vector3(sin(time), sin(time * sqrt(2)), 0) * 0.0625
	cooldown = max(0, cooldown - delta)
	material.albedo_color = lerp( Color.WHITE * 0.625, Color.WHITE * 2, cooldown / cooldowntime)
