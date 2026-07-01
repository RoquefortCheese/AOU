extends Node

enum Vox {AIR, STONE, LIGHT, PILLARVINE, DOORPLANT}
enum MeshType {AIR, CUBE, PLANT}
@export var materials: Dictionary[Vox, Material]
@export var meshtypes: Dictionary[Vox, MeshType]
enum Modifier {DOORPLANT, PILLARVINE, MORESPACE, LESSSPACE, FASTANOMS, FLOATY, MOREANOMS, SQUASH, STRETCH, SORTANOMS}
@export var modcosts: Dictionary[Modifier, Vector3]
	# x = blue
	# y = cyan
	# z = magenta
@export var modnames: Dictionary[Modifier, String]
@export var moddescs: Dictionary[Modifier, String]
const maxmods = 6

var worldseed: int
var player: Player
var world: World
var chamber: Chamber
var chamberindex: int

const pm = [-1, 1]

func dist(point1: Vector3, point2: Vector3):
	return (point2 - point1).length()

func time():
	return (Time.get_ticks_msec() - chamber.starttime) / 1000

func flatten(vector: Vector3):
	return vector * Vector3(1, 0, 1)

func ifmod(default: Variant, modified: Variant, modifier: Modifier):
	return default if modifier not in player.modifiers else modified
