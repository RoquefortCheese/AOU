extends Node

enum Vox {AIR, STONE, LIGHT, DOORSTONE}
@export var materials: Dictionary[Vox, Material]
enum EquipmentType {PISTOL}
@export var equipment: Dictionary[EquipmentType, PackedScene]

var worldseed: int
var player: CharacterBody3D
var world: World
var chamber: Chamber

func dist(point1: Vector3, point2: Vector3):
	return (point2 - point1).length()

func time():
	return (Time.get_ticks_msec() - world.starttime) / 1000

func flatten(vector: Vector3):
	return vector * Vector3(1, 0, 1)
