extends Node

enum Vox {AIR, STONE, LIGHT, PILLARVINE, DOORPLANT}
enum MeshType {AIR, CUBE, PLANT}
@export var materials: Dictionary[Vox, Material]
@export var meshtypes: Dictionary[Vox, MeshType]
enum Modifier {DOORPLANT, PILLARVINE, MORESPACE, LESSSPACE, FASTANOMS, FLOATY, MOREANOMS, SQUASH, STRETCH, SORTANOMS}

const modcosts: Dictionary[Modifier, int] = {
	Modifier.DOORPLANT: 2,
	Modifier.PILLARVINE: 4,
	Modifier.MORESPACE: 3,
	Modifier.LESSSPACE: -3,
	Modifier.FASTANOMS: -4,
	Modifier.FLOATY: 4,
	Modifier.MOREANOMS: -4,
	Modifier.SQUASH: 2,
	Modifier.STRETCH: -2,
	Modifier.SORTANOMS: 1,
}
const modcolors: Dictionary[Modifier, Anomaly.AnomColor] = {
	Modifier.DOORPLANT: Anomaly.AnomColor.BLUE,
	Modifier.PILLARVINE: Anomaly.AnomColor.CYAN,
	Modifier.MORESPACE: Anomaly.AnomColor.CYAN,
	Modifier.LESSSPACE: Anomaly.AnomColor.CYAN,
	Modifier.FASTANOMS: Anomaly.AnomColor.MAGENTA,
	Modifier.FLOATY: Anomaly.AnomColor.CYAN,
	Modifier.MOREANOMS: Anomaly.AnomColor.MAGENTA,
	Modifier.SQUASH: Anomaly.AnomColor.CYAN,
	Modifier.STRETCH: Anomaly.AnomColor.CYAN,
	Modifier.SORTANOMS: Anomaly.AnomColor.BLUE,
}

@export var modnames: Dictionary[Modifier, String]
@export var moddescs: Dictionary[Modifier, String]
const maxmods: int = 6

var worldseed: int
var player: Player
var world: World
var chamber: Chamber
var chamberindex: int

const pm = [-1, 1]

func time():
	return (Time.get_ticks_msec() - chamber.starttime) / 1000

func ifmod(default: Variant, modified: Variant, modifier: Modifier):
	return default if modifier not in player.modifiers else modified

static func dist(point1: Vector3, point2: Vector3):
	return (point2 - point1).length()

static func flatten(vector: Vector3):
	return vector * Vector3(1, 0, 1)

static func padnumstring(num: float, whole: int, deci: int = 0):
	var output = ""
	var numstring = str(num).split(".")
	output += "0".repeat(max(0, whole - len(numstring[0])))
	output += numstring[0]
	if deci != 0:
		var decistring = numstring[1].left(deci)
		output += "." + decistring
		output += "0".repeat(max(0, deci - len(decistring)))
	return output
