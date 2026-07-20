extends StaticBody3D
class_name Computer

const charsperline = 63
const maxlines = 35
enum TerminalClass {RESTORATION, MOD, BLINK, START, END}
const classnames: Dictionary[TerminalClass, String] = {
	TerminalClass.RESTORATION: "restoration",
	TerminalClass.MOD: "mod",
	TerminalClass.BLINK: "blink",
	TerminalClass.START: "start",
	TerminalClass.END: "end",
}
const normalclasses: Array[TerminalClass] = [TerminalClass.RESTORATION, TerminalClass.MOD, TerminalClass.BLINK]

enum Destination {DOOR, COMP, ANOM, SAFETY, RANDOM}
const destnames: Dictionary[Destination, String] = {
	Destination.DOOR: "door",
	Destination.COMP: "comp",
	Destination.ANOM: "anom",
	Destination.SAFETY: "safety",
	Destination.RANDOM: "random",
}
const destdescs: Dictionary[Destination, String] = {
	Destination.DOOR: "Somewhere near the door.",
	Destination.COMP: "Somewhere near the computer of the requested class.",
	Destination.ANOM: "Somewhere near a scoreable anomaly.",
	Destination.SAFETY: "Somewhere away from anomalies.",
	Destination.RANDOM: "Somewhere fully random.",
}
const destcosts: Dictionary[Destination, int] = {
	Destination.DOOR: 7,
	Destination.COMP: 5,
	Destination.ANOM: 3,
	Destination.SAFETY: 3,
	Destination.RANDOM: 2,
}

@export var allowedchars: Array[Key]
var terminalstring: String
var inputhistory: Array[String]
var historyscroll: int
var currentinput: String
enum OtherStuff {SPENT, MODS, CHARGE}
var otherstuff: Dictionary[OtherStuff, Variant]
var termclass: TerminalClass

func inuse():
	return Global.player.terminalinuse == self

func argquant(args: Array[String], quantity: int):
	if len(args) < quantity:
		terminalstring += "Not enough arguments.\n\n"
		return false
	if len(args) > quantity:
		terminalstring += "Too many arguments.\n\n"
		return false
	return true

func classfilter(rightclasses: Array[TerminalClass]):
	if termclass not in rightclasses:
		terminalstring += "This command is not available for this terminal class.\n\n"
		return false
	return true

func tabbed(entry: String, space: int = 16):
	return entry + " ".repeat(max(0, space - len(entry)))

func existentmod(modname: String):
	modname = modname.to_upper()
	if modname not in Global.Modifier:
		terminalstring += "Nonexistent modifier.\n\n"
		return null
	return Global.Modifier[modname]

func existentdest(dest: String):
	dest = dest.to_upper()
	if dest not in Destination:
		terminalstring += "Nonexistent destination.\n\n"
		return null
	return Destination[dest]

func existentsetting(setting: String):
	setting = setting.to_upper()
	if setting not in Global.Setting:
		terminalstring += "Nonexistent setting.\n\n"
		return null
	return Global.Setting[setting]

func infoname(mod: Global.Modifier):
	var output = ""
	output += tabbed(Anomaly.colnames[Global.modcolors[mod]], 8) + "| "
	output += Global.padnumstring(Global.modcosts[mod], 1, 0, true) + " | "
	output += Global.modnames[mod]
	return output

func incompats(mod: Global.Modifier, others: Array[Global.Modifier]):
	for playermod in others:
		if Vector2(mod, playermod) in Global.incompatibilities or Vector2(playermod, mod) in Global.incompatibilities:
			return "This mod conflicts with " + Global.modnames[playermod] + "."
	if mod in Global.prereqs:
		for reqset in Global.prereqs[mod]:
			var fulfilled = false
			for req in reqset:
				if req in others:
					fulfilled = true
			if not fulfilled:
				if len(reqset) == 1:
					return "This mod requires " + Global.modnames[reqset[0]] + "."
				return "This mod requires one of multiple others."
	return null

func create(termclass: TerminalClass):
	self.termclass = termclass
	match termclass:
		TerminalClass.RESTORATION:
			otherstuff[OtherStuff.SPENT] = false
		TerminalClass.MOD:
			otherstuff[OtherStuff.MODS] = []
			var shuffledmods = Global.diceshuffle(Global.Modifier.values())
			for mod in shuffledmods:
				if not Global.hasmod(mod) and incompats(mod, Global.player.modifiers.keys()) == null:
					otherstuff[OtherStuff.MODS].append(mod)
					if len(otherstuff[OtherStuff.MODS]) == 3:
						break
		TerminalClass.BLINK:
			otherstuff[OtherStuff.CHARGE] = 12
	clear()
	newcommand()

func clear():
	terminalstring = ""
	terminalstring += "Welcome to CrowderOS! This is a(n) " + classnames[termclass] + "-class terminal.\n"
	terminalstring += "Enter a command. For a list of commands, enter [help].\n"
	terminalstring += "To exit, left-click or enter [exit].\n\n"
	inputhistory = []
	historyscroll = 0

func help():
	terminalstring += "\nCrowderOS commands:\n"
	terminalstring += tabbed("help:") + "Displays this dialog.\n"
	terminalstring += tabbed("clear:") + "Clears the terminal.\n"
	terminalstring += tabbed("exit:") + "Exits the terminal.\n"
	terminalstring += tabbed("settings:") + "Displays game settings.\n"
	terminalstring += tabbed("info [setting]:") + "Outputs the setting description.\n"
	match termclass:
		TerminalClass.RESTORATION:
			terminalstring += tabbed("restore:") + "Restores some health. Usable once.\n"
		TerminalClass.MOD:
			terminalstring += tabbed("mods [col]:") + "Outputs all mods of the given color.\n"
			terminalstring += tabbed("modlist:") + "Outputs available modifiers.\n"
			terminalstring += tabbed("about [mod]:") + "Outputs the modifier description.\n"
			terminalstring += tabbed("add [mod]:") + "Adds the requested modifier.\n"
			terminalstring += tabbed("del [mod]:") + "Deletes the requested modifier.\n"
		TerminalClass.BLINK:
			terminalstring += tabbed("blink [dest]:") + "Teleports to the requested destination.\n"
			terminalstring += tabbed("blinkst:") + "Outputs all valid destination arguments.\n"
			terminalstring += tabbed("desc [dest]:") + "Outputs the destination description.\n"
			terminalstring += tabbed("charge:") + "Outputs remaining charge.\n"
		TerminalClass.START:
			terminalstring += tabbed("set [x] [bool]:") + "Enables or disables a game setting.\n"
			terminalstring += tabbed("seed [int]:") + "Sets the world seed to the given number.\n"
			terminalstring += tabbed("mods [col]:") + "Outputs all mods of the given color.\n"
			terminalstring += tabbed("about [mod]:") + "Outputs the modifier description.\n"
			terminalstring += tabbed("add [mod]:") + "Adds the requested modifier.\n"
			terminalstring += tabbed("del [mod]:") + "Deletes the requested modifier.\n"
		TerminalClass.END:
			terminalstring += tabbed("summary:") + "Outputs your run summary.\n"
			terminalstring += tabbed("restart:") + "Starts a new run.\n"
	terminalstring += "\n"

func showsettings():
	terminalstring += "\n"
	for setting in Global.Setting.values():
		terminalstring += tabbed(Global.settingnames[setting] + ":")
		terminalstring += str(Global.settings[setting])
		if setting == Global.Setting.SEEDED:
			terminalstring += " [" + str(Global.worldseed) + "]"
		terminalstring += "\n"
	terminalstring += "\n"

func info(args: Array[String]):
	var setting = existentsetting(args[1])
	if setting == null:
		return
	terminalstring += Global.settingdescs[setting] + "\n\n"

func restore():
	if otherstuff[OtherStuff.SPENT]:
		terminalstring += "You have already used this terminal to restore.\n\n"
		return
	Global.player.impacthealth(Global.ifmod(3, 256, Global.Modifier.FULLHEAL))
	otherstuff[OtherStuff.SPENT] = true
	terminalstring += "Your health has been restored!\n\n"

func blink(args: Array[String]):  # i swear most of this class's code is just input validation
	if len(args) < 2:
		terminalstring += "Not enough arguments.\n\n"
		return
	var dest = existentdest(args[1])
	if dest == null:
		return
	if not argquant(args, 3 if dest == Destination.COMP else 2):
		return
	var destterm
	if dest == Destination.COMP:
		destterm = args[2].to_upper()
		if destterm not in TerminalClass:
			terminalstring += "Nonexistent terminal class.\n\n"
			return
		destterm = TerminalClass[destterm]
		if destterm not in Global.chamber.computers:
			terminalstring += "This terminal class is not present in this chamber.\n\n"
			return
		if destterm == TerminalClass.BLINK:
			terminalstring += "You are already at this terminal.\n\n"
			return
		destterm = Global.chamber.computers[destterm]
	if otherstuff[OtherStuff.CHARGE] - destcosts[dest] < 0:
		terminalstring += "Insufficient charge remaining.\n\n"
		return
	var bestscore = -INF
	var bestpoint
	for i in 64:
		var point = Global.chamber.spawnpoint()
		var score
		match dest:
			Destination.DOOR:
				score = -Global.dist(point, Global.chamber.door.position)
			Destination.COMP:
				score = -Global.dist(point, destterm.position)
			Destination.ANOM:
				score = -INF
				for anomaly in Global.chamber.anomalies:
					if anomaly.scoreable():
						var antidist = -Global.dist(point, anomaly.position)
						if antidist > score:
							score = antidist
			Destination.SAFETY:
				score = INF
				for anomaly in Global.chamber.anomalies:
					if anomaly.alive:
						var dist = Global.dist(point, anomaly.position)
						if dist < score:
							score = dist
			Destination.RANDOM:
				score = 0
		if score > bestscore:
			bestscore = score
			bestpoint = point
	Global.player.stopusingterminal()
	Global.player.position = bestpoint
	otherstuff[OtherStuff.CHARGE] -= destcosts[dest]
	terminalstring += "Happy travels!\n\n"

func blinkst():
	terminalstring += "\nValid destinations:\n"
	for dest in Destination.values():
		terminalstring += destnames[dest] + "\n"
	terminalstring += "\n"

func desc(args: Array[String]):
	var dest = existentdest(args[1])
	if dest == null:
		return
	terminalstring += destdescs[dest] + "\n"
	terminalstring += "Costs " + str(destcosts[dest]) + " charge.\n"
	terminalstring += "\n"

func charge():
	terminalstring += "This terminal currently has " + str(otherstuff[OtherStuff.CHARGE]) + " charge.\n\n"

func mods(args: Array[String]):
	var color = args[1].capitalize()
	if color not in Anomaly.colnames.values():
		terminalstring += "Nonexistent color.\n\n"
		return
	color = Global.antidict(Anomaly.colnames)[color]
	for mod in Global.Modifier.values():
		if Global.modcolors[mod] == color:
			terminalstring += Global.modnames[mod] + "\n"
	terminalstring += "\n"

func modlist():
	for mod in otherstuff[OtherStuff.MODS]:
		terminalstring += infoname(mod) + "\n"
	terminalstring += "\n"

func about(args: Array[String]):
	var mod = existentmod(args[1])
	if mod == null:
		return
	terminalstring += infoname(mod) + ": " + Global.moddescs[mod] + "\n"
	terminalstring += "\"" + Global.modflavors[mod] + "\"\n"
	terminalstring += "\n"

func add(args: Array[String]):
	var mod = existentmod(args[1])
	if mod == null:
		return
	if termclass == TerminalClass.START and not Global.settings[Global.Setting.SIMPLE]:
		terminalstring += "Mods can only be added here with [Simple] enabled.\n\n"
		return
	if termclass == TerminalClass.MOD and mod not in otherstuff[OtherStuff.MODS]:
		terminalstring += "This modifier is unavailable at this terminal.\n\n"
		return
	if Global.hasmod(mod):
		terminalstring += "This modifier has already been added.\n\n"
		return
	var issue = incompats(mod, Global.player.modifiers.keys())
	if issue != null:
		terminalstring += issue + "\n\n"
		return
	if termclass == TerminalClass.MOD and abs(Global.player.balance + Global.modcosts[mod]) > 4:
		terminalstring += "Balance cannot exceed ±4.\n\n"
		return
	Global.player.modifiers[mod] = true
	Global.player.balance += Global.modcosts[mod]
	terminalstring += Global.modnames[mod] + " added!\n\n"

func del(args: Array[String]):
	var mod = existentmod(args[1])
	var changedmods = Global.player.modifiers.duplicate()
	changedmods.erase(mod)
	if mod == null:
		return
	if mod not in Global.player.modifiers:
		terminalstring += "You do not have this modifier.\n\n"
		return
	for othermod in Global.player.modifiers:
		if incompats(othermod, changedmods.keys()) != null:
			terminalstring += "To delete this modifier you must delete " + Global.modnames[othermod] + ".\n\n"
			return
	if abs(Global.player.balance - Global.modcosts[mod]) > 4:
		terminalstring += "Balance cannot exceed ±4.\n\n"
		return
	Global.player.modifiers = changedmods
	Global.player.balance -= Global.modcosts[mod]
	terminalstring += Global.modnames[mod] + " deleted!\n\n"

func setseed(args: Array[String]):
	var seedstring = args[1]
	var seedint
	if seedstring.is_valid_int():
		seedint = int(seedstring)
	else:
		terminalstring += "Input will be converted to an integer.\n"
		seedint = seedstring.hash()
	Global.world.setseed(seedint)
	Global.settings[Global.Setting.SEEDED] = true
	terminalstring += "Seed set!\n\n"

func tingset(args: Array[String]):
	var setting = existentsetting(args[1])
	if setting == null:
		return
	var value = args[2].to_lower()
	if value not in ["true", "false"]:
		terminalstring += "Value must be either true or false.\n\n"
		return
	value = {"true": true, "false": false}[value]  # riveting stuff here
	if setting == Global.Setting.SEEDED:
		if value == true:
			terminalstring += "To set a seed, use the [seed] command.\n\n"
			return
		Global.world.setseed(randi())
	if setting == Global.Setting.SIMPLE:
		Global.player.modifiers.clear()
	Global.settings[setting] = value
	match setting:
		Global.Setting.SEEDED:
			terminalstring += "World seed rerandomized!\n\n"
		_:
			terminalstring += Global.settingnames[setting] + " " + {true: "enabled", false: "disabled"}[value] + "!\n\n"

func summary():
	terminalstring += tabbed("Final score:") + str(Global.player.totalscore()) + "\n"
	terminalstring += tabbed("Chamber:") + str(Global.chamberindex) + "\n"
	terminalstring += tabbed("End reason:") + Global.finishcause + "\n"
	terminalstring += tabbed("Settings:")
	for setting in Global.Setting.values():
		if Global.settings[setting]:
			terminalstring += Global.settingnames[setting] + " "
	terminalstring += "\n"
	terminalstring += tabbed("Seed:") + str(Global.worldseed) + "\n"
	terminalstring += "\n"

func restart():
	get_tree().current_scene.newgame()

func _process(delta: float):
	writeoutput()

func newcommand():
	terminalstring += "$root: "

func writeoutput():
	var output = terminalstring + currentinput
	if inuse():
		if fmod(Global.chamber.time, 1) < 0.5:
			output += "_"
	var lines = []
	var nextline = ""
	for ch in output:
		if ch == "\n":
			lines.append(nextline)
			nextline = ""
		else:
			nextline += ch
			if len(nextline) == charsperline:
				lines.append(nextline)
				nextline = ""
	lines.append(nextline)
	$TextLabel.text = ""
	for i in range(max(0, len(lines) - maxlines), len(lines)):
		$TextLabel.text += lines[i] + "\n"

func _input(event: InputEvent):
	if inuse():
		if event is InputEventKey and not event.is_echo() and event.is_pressed():
			var key = event.keycode
			if key in allowedchars and len(currentinput) < 32:
				currentinput += char(event.unicode)
				historyscroll = len(inputhistory)
			if key == KEY_BACKSPACE and len(currentinput) != 0:
				currentinput = currentinput.left(-1)
				historyscroll = len(inputhistory)
			if key == KEY_UP:
				if historyscroll != 0:
					historyscroll -= 1
					currentinput = inputhistory[historyscroll]
			if key == KEY_DOWN:
				if historyscroll != len(inputhistory):
					historyscroll += 1
					currentinput = "" if historyscroll == len(inputhistory) else inputhistory[historyscroll]
			if key == KEY_ENTER:
				runinput()
				historyscroll = len(inputhistory)

func runinput():
	terminalstring += currentinput + "\n"
	if currentinput != "":
		inputhistory.append(currentinput)
		historyscroll += 1
		var args = currentinput.split(" ", false)
		var command = args[0].to_lower()
		match command:
			"help":
				if argquant(args, 1):
					help()
			"clear":
				if argquant(args, 1):
					clear()
			"exit":
				if argquant(args, 1):
					Global.player.stopusingterminal()
			"settings":
				if argquant(args, 1):
					showsettings()
			"info":
				if argquant(args, 2):
					info(args)
			"restore":
				if argquant(args, 1) and classfilter([TerminalClass.RESTORATION]):
					restore()
			"blink":
				if classfilter([TerminalClass.BLINK]):
					blink(args)
			"blinkst":
				if argquant(args, 1) and classfilter([TerminalClass.BLINK]):
					blinkst()
			"desc":
				if argquant(args, 2) and classfilter([TerminalClass.BLINK]):
					desc(args)
			"charge":
				if argquant(args, 1) and classfilter([TerminalClass.BLINK]):
					charge()
			"mods":
				if argquant(args, 2) and classfilter([TerminalClass.MOD, TerminalClass.START]):
					mods(args)
			"modlist":
				if argquant(args, 1) and classfilter([TerminalClass.MOD]):
					modlist()
			"about":
				if argquant(args, 2) and classfilter([TerminalClass.MOD, TerminalClass.START]):
					about(args)
			"add":
				if argquant(args, 2) and classfilter([TerminalClass.MOD, TerminalClass.START]):
					add(args)
			"del":
				if argquant(args, 2) and classfilter([TerminalClass.MOD, TerminalClass.START]):
					del(args)
			"set":
				if argquant(args, 3) and classfilter([TerminalClass.START]):
					tingset(args)
			"seed":
				if argquant(args, 2) and classfilter([TerminalClass.START]):
					setseed(args)
			"summary":
				if argquant(args, 1) and classfilter([TerminalClass.END]):
					summary()
			"restart":
				if argquant(args, 1) and classfilter([TerminalClass.END]):
					restart()
	currentinput = ""
	newcommand()
