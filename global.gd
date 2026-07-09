extends Node

enum Vox {AIR, STONE, LIGHT, GLASS, PILLARVINE, DOORPLANT}
enum MeshType {AIR, CUBE, PLANT}
@export var materials: Dictionary[Vox, Material]
@export var meshtypes: Dictionary[Vox, MeshType]

enum Modifier {DOORPLANT, PILLARVINE, MORESPACE, LESSSPACE, FASTANOMS, FLOATY, MOREANOMS, SQUASH, STRETCH, SORTANOMS, REGEN, RUNNING, DOUBLEJUMP, HYPERBLUE, HYPERCYAN, HYPERMAGENTA, ISLANDS, MOREAMMO, FASTRELOAD, ALERTANOMS, MOREOUCH}
const modcosts: Dictionary[Modifier, int] = {
	Modifier.DOORPLANT: -2,
	Modifier.PILLARVINE: -4,
	Modifier.MORESPACE: -3,
	Modifier.LESSSPACE: 3,
	Modifier.FASTANOMS: 4,
	Modifier.FLOATY: -4,
	Modifier.MOREANOMS: 4,
	Modifier.SQUASH: -2,
	Modifier.STRETCH: 2,
	Modifier.SORTANOMS: -1,
	Modifier.REGEN: 3,
	Modifier.RUNNING: -3,
	Modifier.DOUBLEJUMP: -4,
	Modifier.HYPERBLUE: 2,
	Modifier.HYPERCYAN: 2,
	Modifier.HYPERMAGENTA: 2,
	Modifier.ISLANDS: -1,
	Modifier.MOREAMMO: -3,
	Modifier.FASTRELOAD: -3,
	Modifier.ALERTANOMS: 4,
	Modifier.MOREOUCH: 4,
}
const modcolors: Dictionary[Modifier, Anomaly.AnomColor] = {
	Modifier.DOORPLANT: Anomaly.AnomColor.BLUE,
	Modifier.PILLARVINE: Anomaly.AnomColor.BLUE,
	Modifier.MORESPACE: Anomaly.AnomColor.BLUE,
	Modifier.LESSSPACE: Anomaly.AnomColor.BLUE,
	Modifier.FASTANOMS: Anomaly.AnomColor.MAGENTA,
	Modifier.FLOATY: Anomaly.AnomColor.CYAN,
	Modifier.MOREANOMS: Anomaly.AnomColor.MAGENTA,
	Modifier.SQUASH: Anomaly.AnomColor.BLUE,
	Modifier.STRETCH: Anomaly.AnomColor.BLUE,
	Modifier.SORTANOMS: Anomaly.AnomColor.BLUE,
	Modifier.REGEN: Anomaly.AnomColor.MAGENTA,
	Modifier.RUNNING: Anomaly.AnomColor.CYAN,
	Modifier.DOUBLEJUMP: Anomaly.AnomColor.CYAN,
	Modifier.HYPERBLUE: Anomaly.AnomColor.MAGENTA,
	Modifier.HYPERCYAN: Anomaly.AnomColor.MAGENTA,
	Modifier.HYPERMAGENTA: Anomaly.AnomColor.MAGENTA,
	Modifier.ISLANDS: Anomaly.AnomColor.BLUE,
	Modifier.MOREAMMO: Anomaly.AnomColor.MAGENTA,
	Modifier.FASTRELOAD: Anomaly.AnomColor.MAGENTA,
	Modifier.ALERTANOMS: Anomaly.AnomColor.MAGENTA,
	Modifier.MOREOUCH: Anomaly.AnomColor.CYAN,
}
var modnames: Dictionary[Modifier, String] = {
	Modifier.DOORPLANT: "DoorPlant",
	Modifier.PILLARVINE: "PillarVine",
	Modifier.MORESPACE: "MoreSpace",
	Modifier.LESSSPACE: "LessSpace",
	Modifier.FASTANOMS: "FastAnoms",
	Modifier.FLOATY: "Floaty",
	Modifier.MOREANOMS: "MoreAnoms",
	Modifier.SQUASH: "Squash",
	Modifier.STRETCH: "Stretch",
	Modifier.SORTANOMS: "SortAnoms",
	Modifier.REGEN: "Regen",
	Modifier.RUNNING: "Running",
	Modifier.DOUBLEJUMP: "DoubleJump",
	Modifier.HYPERBLUE: "HyperBlue",
	Modifier.HYPERCYAN: "HyperCyan",
	Modifier.HYPERMAGENTA: "HyperMagenta",
	Modifier.ISLANDS: "Islands",
	Modifier.MOREAMMO: "MoreAmmo",
	Modifier.FASTRELOAD: "FastReload",
	Modifier.ALERTANOMS: "AlertAnoms",
	Modifier.MOREOUCH: "MoreOuch",
}
var moddescs: Dictionary[Modifier, String] = {
	Modifier.DOORPLANT: "Blue plants grow next to doors.",
	Modifier.PILLARVINE: "Tall vines that can be climbed.",
	Modifier.MORESPACE: "More open caves.",
	Modifier.LESSSPACE: "More constricted caves.",
	Modifier.FASTANOMS: "Anomalies move faster.",
	Modifier.FLOATY: "Less gravity.",
	Modifier.MOREANOMS: "Significantly more anomalies.",
	Modifier.SQUASH: "Caves compressed vertically.",
	Modifier.STRETCH: "Caves stretched vertically.",
	Modifier.SORTANOMS: "Anomalies stratified by color.",
	Modifier.REGEN: "Anomalies revive after some time.",
	Modifier.RUNNING: "Faster movement.",
	Modifier.DOUBLEJUMP: "Jump in the air.",
	Modifier.HYPERBLUE: "Blue anomalies always know where you are.",
	Modifier.HYPERCYAN: "Cyan anomalies move much faster.",
	Modifier.HYPERMAGENTA: "Magenta anomalies deal more damage.",
	Modifier.ISLANDS: "More floating terrain.",
	Modifier.MOREAMMO: "More ammunition.",
	Modifier.FASTRELOAD: "Faster reload time.",
	Modifier.ALERTANOMS: "Anomalies sense you from farther away.",
	Modifier.MOREOUCH: "Anomalies deal more damage.",
}
var incompatibilities: Array[Vector2] = [
	Vector2(Modifier.MORESPACE, Modifier.LESSSPACE),
	Vector2(Modifier.SQUASH, Modifier.STRETCH),
]
const maxmods: int = 6

enum Setting {SEEDED, INFINITE, SIMPLE}
const settingnames: Dictionary[Setting, String] = {
	Setting.SEEDED: "Seeded",
	Setting.INFINITE: "Infinite",
	Setting.SIMPLE: "Simple",
}

var worldseed: int
var dice: RandomNumberGenerator
var settings: Dictionary[Setting, bool]
var finishcause: String
var player: Player
var world: World
var chamber: Chamber
var chamberindex: int

const pm = [-1, 1]

func time():
	return (Time.get_ticks_msec() - chamber.starttime) / 1000

func hasmod(modifier: Modifier):
	return modifier in player.modifiers

func ifmod(default: Variant, modified: Variant, modifier: Modifier):
	return default if modifier not in player.modifiers else modified

func dicechoose(array: Array):
	return array[dice.randi_range(0, len(array) - 1)]

func diceshuffle(array: Array):
	var copy = array.duplicate()
	var newarray = []
	while len(copy) != 0:
		var index = floor(dice.randf() * len(copy))
		newarray.append(copy.pop_at(index))
	return newarray

static func dist(point1: Vector3, point2: Vector3):
	return (point2 - point1).length()

static func flatten(vector: Vector3):
	return vector * Vector3(1, 0, 1)

static func padnumstring(num: float, whole: int, deci: int = 0, signed: bool = false):
	var output = ""
	if signed:
		output += "+" if num >= 0 else "-"
	var numstring = str(abs(num)).split(".")
	output += "0".repeat(max(0, whole - len(numstring[0])))
	output += numstring[0]
	if deci != 0:
		var decistring = numstring[1].left(deci)
		output += "." + decistring
		output += "0".repeat(max(0, deci - len(decistring)))
	return output
