extends Node3D
class_name Pistol

func fire():
	if Global.player.ammo == 0:
		$NoAmmoAudioPlayer.play()
		return
	Global.player.ammo -= 1
	var ray = Global.player.get_node("Camera3D/RayCast3D")
	var target = ray.get_collider()
	if target is Anomaly:
		target.die(global_position, true)
	else:
		$MissedShotAudioPlayer.play()


func _process(delta: float):
	var time = Global.time()
	position = Vector3(sin(time), sin(time * sqrt(2)), 0) * 0.0625
