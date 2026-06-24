extends Node

enum Vox {AIR, STONE, LIGHT, DOORSTONE, PILLARVINE}
enum MeshType {AIR, CUBE, PLANT}
@export var materials: Dictionary[Vox, Material]
@export var meshtypes: Dictionary[Vox, MeshType]
enum EquipmentType {PISTOL}
@export var equipment: Dictionary[EquipmentType, PackedScene]
enum FeatureType {DOORSTONE}
@export var features: Dictionary[FeatureType, Script]

var worldseed: int
var player: CharacterBody3D
var world: World
var chamber: Chamber

const pm = [-1, 1]

func dist(point1: Vector3, point2: Vector3):
	return (point2 - point1).length()

func time():
	return (Time.get_ticks_msec() - chamber.starttime) / 1000

func flatten(vector: Vector3):
	return vector * Vector3(1, 0, 1)
