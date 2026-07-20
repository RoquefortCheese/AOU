extends Node

enum Vox {AIR, STONE, LIGHT, GLASS, PILLARVINE, DOORPLANT, HIGHGRASS, CORAL, DOUBLEGLASS}
enum MeshType {AIR, CUBE, PLANT}
@export var materials: Dictionary[Vox, Material]
@export var meshtypes: Dictionary[Vox, MeshType]
@export var isglass: Dictionary[Vox, bool]

enum Modifier {DOORPLANT, PILLARVINE, FASTANOMS, FLOATY, MOREANOMS, SQUASH, STRETCH, REGEN, RUNNING, DOUBLEJUMP, ISLANDS, MOREAMMO, ALERTANOMS, TRIPLEJUMP, STROLLING, SNIPER, SILVERLINE, FULLHEAL, HIGHGRASS, DENSE, FALLDAMAGE, SQUISH, HYPERSPICE, WALLRUN, PLANTJUMP, CORALBLEACH, PHOTOFIELD, VENGEANCE, COMBO, DARKNESS, AIRJUMP, TUNNELS, GLASS, BOXCAVE, RUBBER, LESSAMMO}
const modcosts: Dictionary[Modifier, int] = {
	Modifier.DOORPLANT: -2,
	Modifier.PILLARVINE: -4,
	Modifier.FASTANOMS: 3,
	Modifier.FLOATY: -2,
	Modifier.MOREANOMS: 2,
	Modifier.SQUASH: -3,
	Modifier.STRETCH: 3,
	Modifier.REGEN: 4,
	Modifier.RUNNING: -4,
	Modifier.DOUBLEJUMP: -4,
	Modifier.ISLANDS: -3,
	Modifier.MOREAMMO: -4,
	Modifier.ALERTANOMS: 2,
	Modifier.TRIPLEJUMP: -2,
	Modifier.STROLLING: 4,
	Modifier.SNIPER: -2,
	Modifier.SILVERLINE: -2,
	Modifier.FULLHEAL: -4,
	Modifier.HIGHGRASS: -3,
	Modifier.DENSE: 4,
	Modifier.FALLDAMAGE: 4,
	Modifier.SQUISH: 3,
	Modifier.HYPERSPICE: 4,
	Modifier.WALLRUN: -2,
	Modifier.PLANTJUMP: -2,
	Modifier.CORALBLEACH: 3,
	Modifier.PHOTOFIELD: 2,
	Modifier.VENGEANCE: -4,
	Modifier.COMBO: -2,
	Modifier.DARKNESS: 3,
	Modifier.AIRJUMP: -2,
	Modifier.TUNNELS: 3,
	Modifier.GLASS: -3,
	Modifier.BOXCAVE: 3,
	Modifier.RUBBER: 4,
	Modifier.LESSAMMO: 3,
}
const modcolors: Dictionary[Modifier, Anomaly.AnomColor] = {
	Modifier.DOORPLANT: Anomaly.AnomColor.BLUE,
	Modifier.PILLARVINE: Anomaly.AnomColor.BLUE,
	Modifier.FASTANOMS: Anomaly.AnomColor.MAGENTA,
	Modifier.FLOATY: Anomaly.AnomColor.CYAN,
	Modifier.MOREANOMS: Anomaly.AnomColor.MAGENTA,
	Modifier.SQUASH: Anomaly.AnomColor.BLUE,
	Modifier.STRETCH: Anomaly.AnomColor.BLUE,
	Modifier.REGEN: Anomaly.AnomColor.MAGENTA,
	Modifier.RUNNING: Anomaly.AnomColor.CYAN,
	Modifier.DOUBLEJUMP: Anomaly.AnomColor.CYAN,
	Modifier.ISLANDS: Anomaly.AnomColor.BLUE,
	Modifier.MOREAMMO: Anomaly.AnomColor.MAGENTA,
	Modifier.ALERTANOMS: Anomaly.AnomColor.MAGENTA,
	Modifier.TRIPLEJUMP: Anomaly.AnomColor.CYAN,
	Modifier.STROLLING: Anomaly.AnomColor.CYAN,
	Modifier.SNIPER: Anomaly.AnomColor.MAGENTA,
	Modifier.SILVERLINE: Anomaly.AnomColor.MAGENTA,
	Modifier.FULLHEAL: Anomaly.AnomColor.MAGENTA,
	Modifier.HIGHGRASS: Anomaly.AnomColor.BLUE,
	Modifier.DENSE: Anomaly.AnomColor.CYAN,
	Modifier.FALLDAMAGE: Anomaly.AnomColor.CYAN,
	Modifier.SQUISH: Anomaly.AnomColor.BLUE,
	Modifier.HYPERSPICE: Anomaly.AnomColor.MAGENTA,
	Modifier.WALLRUN: Anomaly.AnomColor.CYAN,
	Modifier.PLANTJUMP: Anomaly.AnomColor.CYAN,
	Modifier.CORALBLEACH: Anomaly.AnomColor.BLUE,
	Modifier.PHOTOFIELD: Anomaly.AnomColor.CYAN,
	Modifier.VENGEANCE: Anomaly.AnomColor.MAGENTA,
	Modifier.COMBO: Anomaly.AnomColor.MAGENTA,
	Modifier.DARKNESS: Anomaly.AnomColor.BLUE,
	Modifier.AIRJUMP: Anomaly.AnomColor.CYAN,
	Modifier.TUNNELS: Anomaly.AnomColor.BLUE,
	Modifier.GLASS: Anomaly.AnomColor.BLUE,
	Modifier.BOXCAVE: Anomaly.AnomColor.BLUE,
	Modifier.RUBBER: Anomaly.AnomColor.CYAN,
	Modifier.LESSAMMO: Anomaly.AnomColor.MAGENTA,
}
var modnames: Dictionary[Modifier, String] = {
	Modifier.DOORPLANT: "DoorPlant",
	Modifier.PILLARVINE: "PillarVine",
	Modifier.FASTANOMS: "FastAnoms",
	Modifier.FLOATY: "Floaty",
	Modifier.MOREANOMS: "MoreAnoms",
	Modifier.SQUASH: "Squash",
	Modifier.STRETCH: "Stretch",
	Modifier.REGEN: "Regen",
	Modifier.RUNNING: "Running",
	Modifier.DOUBLEJUMP: "DoubleJump",
	Modifier.ISLANDS: "Islands",
	Modifier.MOREAMMO: "MoreAmmo",
	Modifier.ALERTANOMS: "AlertAnoms",
	Modifier.TRIPLEJUMP: "TripleJump",
	Modifier.STROLLING: "Strolling",
	Modifier.SNIPER: "Sniper",
	Modifier.SILVERLINE: "SilverLine",
	Modifier.FULLHEAL: "FullHeal",
	Modifier.HIGHGRASS: "HighGrass",
	Modifier.DENSE: "Dense",
	Modifier.FALLDAMAGE: "FallDamage",
	Modifier.SQUISH: "Squish",
	Modifier.HYPERSPICE: "HyperSpice",
	Modifier.WALLRUN: "WallRun",
	Modifier.PLANTJUMP: "PlantJump",
	Modifier.CORALBLEACH: "CoralBleach",
	Modifier.PHOTOFIELD: "PhotoField",
	Modifier.VENGEANCE: "Vengeance",
	Modifier.COMBO: "Combo",
	Modifier.DARKNESS: "Darkness",
	Modifier.AIRJUMP: "AirJump",
	Modifier.TUNNELS: "Tunnels",
	Modifier.GLASS: "Glass",
	Modifier.BOXCAVE: "BoxCave",
	Modifier.RUBBER: "Rubber",
	Modifier.LESSAMMO: "LessAmmo",
}
var moddescs: Dictionary[Modifier, String] = {
	Modifier.DOORPLANT: "Blue plants that grow next to doors.",
	Modifier.PILLARVINE: "Tall vines that can be climbed.",
	Modifier.FASTANOMS: "Anomalies move faster.",
	Modifier.FLOATY: "Less gravity.",
	Modifier.MOREANOMS: "Significantly more anomalies.",
	Modifier.SQUASH: "Caves compressed vertically.",
	Modifier.STRETCH: "Caves stretched vertically.",
	Modifier.REGEN: "Anomalies revive after some time.",
	Modifier.RUNNING: "Faster movement.",
	Modifier.DOUBLEJUMP: "Jump in the air.",
	Modifier.ISLANDS: "More floating terrain.",
	Modifier.MOREAMMO: "More ammunition.",
	Modifier.ALERTANOMS: "Anomalies sense you from farther away.",
	Modifier.TRIPLEJUMP: "Airjump twice.",
	Modifier.STROLLING: "Slower movement.",
	Modifier.SNIPER: "Sniping while pursued restores health.",
	Modifier.SILVERLINE: "All anomaly deaths increase score.",
	Modifier.FULLHEAL: "Restoration terminals heal fully.",
	Modifier.HIGHGRASS: "High grass that can be hidden in.",
	Modifier.DENSE: "More gravity.",
	Modifier.FALLDAMAGE: "Hitting the ground too fast hurts.",
	Modifier.SQUISH: "Caves compressed vertically even more.",
	Modifier.HYPERSPICE: "_Anom mods are stronger.",
	Modifier.WALLRUN: "Movement along walls is faster.",
	Modifier.PLANTJUMP: "Jump higher when standing in plants.",
	Modifier.CORALBLEACH: "Some plants matter is dead.",
	Modifier.PHOTOFIELD: "You are repelled from lights.",
	Modifier.VENGEANCE: "Taking damage kills nearby anomalies.",
	Modifier.COMBO: "Consecutive successful shots heal.",
	Modifier.DARKNESS: "Lights illuminate less.",
	Modifier.AIRJUMP: "Unlimited coyote time.",
	Modifier.TUNNELS: "More tunnel-like terrain.",
	Modifier.GLASS: "Stone is replaced with glass.",
	Modifier.BOXCAVE: "Noise tapering is not applied.",
	Modifier.RUBBER: "Bounciness occurs.",
	Modifier.LESSAMMO: "Less ammunition.",
}
var modflavors: Dictionary[Modifier, String] = {
	Modifier.DOORPLANT: "",
	Modifier.PILLARVINE: "",
	Modifier.FASTANOMS: "",
	Modifier.FLOATY: "",
	Modifier.MOREANOMS: "",
	Modifier.SQUASH: "",
	Modifier.STRETCH: "",
	Modifier.REGEN: "",
	Modifier.RUNNING: "",
	Modifier.DOUBLEJUMP: "Two jumps for the price of one!",
	Modifier.ISLANDS: "How are those chunks of stone levitating? Science, of course.",
	Modifier.MOREAMMO: "",
	Modifier.ALERTANOMS: "",
	Modifier.TRIPLEJUMP: "",
	Modifier.STROLLING: "",
	Modifier.SNIPER: "",
	Modifier.SILVERLINE: "",
	Modifier.FULLHEAL: "",
	Modifier.HIGHGRASS: "",
	Modifier.DENSE: "",
	Modifier.FALLDAMAGE: "Realism in gaming.",
	Modifier.SQUISH: "",
	Modifier.HYPERSPICE: "",
	Modifier.WALLRUN: "This would make more sense with flat walls.",
	Modifier.PLANTJUMP: "Become one with nature.",
	Modifier.CORALBLEACH: "Ocean acidification is a serious issue.",
	Modifier.PHOTOFIELD: "Did you know photons and electrons are the same thing?",
	Modifier.VENGEANCE: "",
	Modifier.COMBO: "",
	Modifier.DARKNESS: "",
	Modifier.AIRJUMP: "",
	Modifier.TUNNELS: "",
	Modifier.GLASS: "",
	Modifier.BOXCAVE: "",
	Modifier.RUBBER: "",
	Modifier.LESSAMMO: "",
}
var incompatibilities: Array[Vector2] = [
	Vector2(Modifier.SQUASH, Modifier.STRETCH),
	Vector2(Modifier.RUNNING, Modifier.STROLLING),
	Vector2(Modifier.FLOATY, Modifier.DENSE),
	Vector2(Modifier.ISLANDS, Modifier.TUNNELS),
	Vector2(Modifier.MOREAMMO, Modifier.LESSAMMO),
]
var prereqs: Dictionary[Modifier, Array] = {  # vals are Array[Array[Modifier]] but nested collection types are unsupported (why would they not be supported (this is silly (yes we do need triple-nested collections this is very necessary (but seriously why tho godot))))
	Modifier.TRIPLEJUMP: [[Modifier.DOUBLEJUMP]],
	Modifier.SQUISH: [[Modifier.SQUASH]],
	Modifier.HYPERSPICE: [[Modifier.FASTANOMS, Modifier.ALERTANOMS, Modifier.MOREANOMS]],
	Modifier.CORALBLEACH: [[Modifier.DOORPLANT, Modifier.PILLARVINE, Modifier.HIGHGRASS]],
}  # to get a key, at least one mod from each nested array in the value array must be present

enum Setting {SEEDED, INFINITE, SIMPLE, IMMORTALITY}
const settingnames: Dictionary[Setting, String] = {
	Setting.SEEDED: "Seeded",
	Setting.INFINITE: "Infinite",
	Setting.SIMPLE: "Simple",
	Setting.IMMORTALITY: "Immortality",
}
const settingdescs: Dictionary[Setting, String] = {
	Setting.SEEDED: "If enabled, a custom RNG seed has been set.",
	Setting.INFINITE: "Unless enabled, the game ends after six chambers.",
	Setting.SIMPLE: "If enabled, no modifier terminals generate.",
	Setting.IMMORTALITY: "If enabled, health cannot decrease.",
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

static func antidict(dict: Dictionary):
	var output = {}
	for key in dict:
		output[dict[key]] = key
	return output

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
