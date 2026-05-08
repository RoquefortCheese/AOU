extends Node

enum Vox {AIR, STONE}
@export var materials: Dictionary[Vox, Material]

var worldseed: int
var player: CharacterBody3D
var world: Node

func dist(point1: Vector3, point2: Vector3):
	return sqrt((point2.x - point1.x) ** 2 + (point2.y - point1.y) ** 2 + (point2.z - point1.z) ** 2)

func time():
	return (Time.get_ticks_msec() - world.starttime) / 1000
