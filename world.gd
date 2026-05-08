extends Node

@export var chamberscene: PackedScene
var starttime: float

func _ready():
	starttime = Time.get_ticks_msec()
	setglobals()
	var chamber = chamberscene.instantiate()
	chamber.create(Vector3.ZERO, 64)
	add_child(chamber)

func setglobals():
	Global.worldseed = randi()
	Global.world = self
	Global.player = $Player
