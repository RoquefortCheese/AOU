extends StaticBody3D
class_name Computer

const charsperline = 63
const maxlines = 35
enum TerminalClass {RESTORATION, MOD, START, END}
const classnames: Dictionary[TerminalClass, String] = {
	TerminalClass.RESTORATION: "restoration",
	TerminalClass.MOD: "mod",
	TerminalClass.START: "start",
	TerminalClass.END: "end",
}
const normalclasses: Array[TerminalClass] = [TerminalClass.RESTORATION, TerminalClass.MOD]

@export var allowedchars: Array[Key]
var terminalstring: String
var inputhistory: Array[String]
var historyscroll: int
var currentinput: String
enum OtherStuff {SPENT, MODS}
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

func infoname(mod: Global.Modifier):
	var output = ""
	output += tabbed(Anomaly.colname[Global.modcolors[mod]], 8) + "| "
	output += Global.padnumstring(Global.modcosts[mod], 1, 0, true) + " | "
	output += Global.modnames[mod]
	return output

func incompats(mod: Global.Modifier):
	for playermod in Global.player.modifiers:
		if Vector2(mod, playermod) in Global.incompatibilities or Vector2(playermod, mod) in Global.incompatibilities:
			return "This mod conflicts with " + Global.modnames[playermod] + "."
	if mod in Global.prereqs and Global.prereqs[mod] not in Global.player.modifiers:
		return "This mod requires " + Global.modnames[Global.prereqs[mod]] + "."
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
				if not Global.hasmod(mod) and incompats(mod) == null:
					otherstuff[OtherStuff.MODS].append(mod)
					if len(otherstuff[OtherStuff.MODS]) == 3:
						break
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
	match termclass:
		TerminalClass.RESTORATION:
			terminalstring += tabbed("restore:") + "Restores some health. Usable once.\n"
		TerminalClass.MOD:
			terminalstring += tabbed("modlist:") + "Outputs available modifiers.\n"
			terminalstring += tabbed("about [mod]:") + "Outputs the modifier description.\n"
			terminalstring += tabbed("add [mod]:") + "Adds the requested modifier.\n"
			terminalstring += tabbed("del [mod]:") + "Deletes the requested modifier.\n"
		TerminalClass.START:
			terminalstring += tabbed("seed [int]:") + "Sets the world seed to the given number.\n"
			terminalstring += tabbed("set [x] [bool]:") + "Enables or disables a game setting.\n"
			terminalstring += tabbed("about [mod]:") + "Outputs the modifier description.\n"
			terminalstring += tabbed("add [mod]:") + "Adds the requested modifier.\n"
			terminalstring += tabbed("del [mod]:") + "Deletes the requested modifier.\n"
		TerminalClass.END:
			terminalstring += tabbed("cause:") + "Displays the cause of the end of the run.\n"
			terminalstring += tabbed("score:") + "Displays your total final score.\n"
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

func restore():
	if otherstuff[OtherStuff.SPENT]:
		terminalstring += "You have already used this terminal to restore.\n\n"
		return
	var healing = 3
	if Global.hasmod(Global.Modifier.MOREHEAL):
		healing += 1
	if Global.hasmod(Global.Modifier.LESSHEAL):
		healing -= 1
	Global.player.impacthealth(healing)
	otherstuff[OtherStuff.SPENT] = true
	terminalstring += "Your health has been restored!\n\n"

func modlist():
	for mod in otherstuff[OtherStuff.MODS]:
		terminalstring += infoname(mod) + "\n"
	terminalstring += "\n"

func about(args: Array[String]):
	var mod = existentmod(args[1])
	if mod == null:
		return
	terminalstring += infoname(mod) + ": "
	terminalstring += Global.moddescs[mod] + "\n\n"

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
	var issue = incompats(mod)
	if issue != null:
		terminalstring += issue + "\n\n"
		return
	if len(Global.player.modifiers) == Global.maxmods:
		terminalstring += "Cannot exceed the max amount of modifiers.\n\n"
		return
	if abs(Global.player.balance + Global.modcosts[mod]) > 4:
		terminalstring += "Balance cannot exceed ±4.\n\n"
		return
	Global.player.modifiers.append(mod)
	Global.player.balance += Global.modcosts[mod]
	terminalstring += Global.modnames[mod] + " added!\n\n"

func del(args: Array[String]):
	var mod = existentmod(args[1])
	if mod == null:
		return
	if mod not in Global.player.modifiers:
		terminalstring += "You do not have this modifier.\n\n"
		return
	if abs(Global.player.balance - Global.modcosts[mod]) > 4:
		terminalstring += "Balance cannot exceed ±4.\n\n"
		return
	Global.player.modifiers.erase(mod)
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
	var setting = args[1].to_upper()
	var value = args[2].to_lower()
	if setting not in Global.Setting:
		terminalstring += "Nonexistent setting.\n\n"
		return
	if value not in ["true", "false"]:
		terminalstring += "Value must be either true or false.\n\n"
		return
	setting = Global.Setting[setting]
	value = {"true": true, "false": false}[value]  # riveting stuff here
	if setting == Global.Setting.SEEDED:
		if value == true:
			terminalstring += "To set a seed, use the [seed] command.\n\n"
			return
		Global.world.setseed(randi())
	if setting == Global.Setting.SIMPLE:
		Global.player.modifiers = []
	Global.settings[setting] = value
	match setting:
		Global.Setting.SEEDED:
			terminalstring += "World seed rerandomized!\n\n"
		_:
			terminalstring += Global.settingnames[setting] + " " + {true: "enabled", false: "disabled"}[value] + "!\n\n"

func cod():
	terminalstring += Global.finishcause + "\n\n"

func showscore():
	terminalstring += str(Global.player.totalscore()) + "\n\n"

func restart():
	get_tree().current_scene.newgame()

func _process(delta: float):
	writeoutput()

func newcommand():
	terminalstring += "$root: "

func writeoutput():
	var output = terminalstring + currentinput
	if inuse():
		if fmod(Global.time(), 1) < 0.5:
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
			"restore":
				if argquant(args, 1) and classfilter([TerminalClass.RESTORATION]):
					restore()
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
			"seed":
				if argquant(args, 2) and classfilter([TerminalClass.START]):
					setseed(args)
			"set":
				if argquant(args, 3) and classfilter([TerminalClass.START]):
					tingset(args)
			"cause":
				if argquant(args, 1) and classfilter([TerminalClass.END]):
					cod()
			"score":
				if argquant(args, 1) and classfilter([TerminalClass.END]):
					showscore()
			"restart":
				if argquant(args, 1) and classfilter([TerminalClass.END]):
					restart()
	currentinput = ""
	newcommand()
