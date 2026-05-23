@abstract
extends Node3D
class_name Equipment

var ray: RayCast3D

func equip():
	Global.player.get_node("Camera3D/HandPos").add_child(self)
	ray = Global.player.get_node("Camera3D/RayCast3D")

@abstract func fire()
