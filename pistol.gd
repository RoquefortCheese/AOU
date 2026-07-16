extends Node3D
class_name Pistol
var combo = 0

func fire():
	if Global.player.ammo == 0:
		$NoAmmoAudioPlayer.play()
		return
	Global.player.ammo -= 1
	var ray = Global.player.get_node("Camera3D/RayCast3D")
	var target = ray.get_collider()
	if target is Anomaly:
		if target.following and target.alive:
			combo += 1
			if combo == 6:
				if Global.hasmod(Global.Modifier.COMBO):
					Global.player.impacthealth(1)
				combo = 0
		target.die(global_position, true)
	else:
		$MissedShotAudioPlayer.play()
		combo = 0

func _process(delta: float):
	var time = Global.chamber.time
	position = Vector3(sin(time), sin(time * sqrt(2)), 0) * 0.0625
