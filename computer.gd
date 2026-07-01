extends StaticBody3D
class_name Computer

const charsperline = 63
const maxlines = 35
enum TerminalClass {INFO, RESTORATION, MOD}
@export var classnames: Dictionary[TerminalClass, String]

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

func create(termclass: TerminalClass):
	self.termclass = termclass
	match termclass:
		TerminalClass.RESTORATION:
			otherstuff[OtherStuff.SPENT] = false
		TerminalClass.MOD:
			otherstuff[OtherStuff.MODS] = []
			var shuffledmods = Global.chamber.diceshuffle(Global.Modifier.values())
			for mod in shuffledmods:
				if mod not in Global.player.modifiers:
					otherstuff[OtherStuff.MODS].append(mod)
					if len(otherstuff[OtherStuff.MODS]) == 3:
						break
	clear()
	newcommand()

func argquant(args: Array[String], quantity: int):
	if len(args) < quantity:
		terminalstring += "Not enough arguments.\n\n"
		return false
	if len(args) > quantity:
		terminalstring += "Too many arguments.\n\n"
		return false
	return true

func classfilter(rightclass: TerminalClass):
	if termclass != rightclass:
		terminalstring += "This command is not available for this terminal class.\n\n"
		return false
	return true

func tabbed(entry: String):
	return entry + " ".repeat(max(0, 16 - len(entry)))

func existentmod(modname: String):
	modname = modname.to_upper()
	if modname not in Global.Modifier:
		terminalstring += "Nonexistent modifier.\n\n"
		return null
	return Global.Modifier[modname]

func costandname(mod: Global.Modifier):
	var output = ""
	for color in Anomaly.AnomColor.values():
		var cost = str(int(Global.modcosts[mod][color] * 4))
		output += cost + " ".repeat(3 - len(cost)) + "|"
	output += "  " + Global.modnames[mod]
	return output

func clear():
	terminalstring = ""
	terminalstring += "Welcome to CrowderOS! This is a(n) " + classnames[termclass] + "-class terminal.\n"
	terminalstring += "Enter a command. For a list of commands, enter \"help\".\n"
	terminalstring += "To exit, left-click or enter \"exit\".\n\n"
	inputhistory = []
	historyscroll = 0

func help():
	terminalstring += "\nCrowderOS commands:\n"
	terminalstring += tabbed("help:") + "Displays this dialog.\n"
	terminalstring += tabbed("clear:") + "Clears the terminal.\n"
	terminalstring += tabbed("exit:") + "Exits the terminal.\n"
	match termclass:
		TerminalClass.INFO:
			terminalstring += tabbed("info [data]:") + "Outputs the requested data.\n"
			terminalstring += tabbed("infolist:") + "Outputs the list of available data.\n"
		TerminalClass.RESTORATION:
			terminalstring += tabbed("restore:") + "Restores two hitpoints. Usable once.\n"
		TerminalClass.MOD:
			terminalstring += tabbed("modlist:") + "Outputs available modifiers.\n"
			terminalstring += tabbed("about [mod]:") + "Outputs the modifier description.\n"
			terminalstring += tabbed("add [mod]:") + "Adds the requested modifier.\n"
	terminalstring += "\n"

func info(args: Array[String]):
	match args[1]:
		"doordist":
			terminalstring += str(floor(Global.dist(position, Global.chamber.door.position) * 1000) / 1000)
		"numterms":
			terminalstring += str(len(Global.chamber.computers))
		"numanoms":
			var count = 0
			for anomaly in Global.chamber.anomalies:
				if anomaly.alive:
					count += 1
			terminalstring += str(count)
		"numdead":
			var count = 0
			for anomaly in Global.chamber.anomalies:
				if not anomaly.alive:
					count += 1
			terminalstring += str(count)
		"chamindex":
			terminalstring += str(Global.chamberindex)
		"seed":
			terminalstring += str(Global.worldseed)
		_:
			terminalstring += "Invalid argument. For a list of arguments, use \"infolist\"."
	terminalstring += "\n\n"

func infolist():
	terminalstring += "\n"
	if termclass != TerminalClass.INFO:
		terminalstring += "Note: The \"info\" command is not available on this terminal.\n"
	terminalstring += tabbed("doordist:") + "The distance from this terminal to the door.\n"
	terminalstring += tabbed("numterms:") + "The amount of terminals in this chamber.\n"
	terminalstring += tabbed("numanoms:") + "The amount of alive anomalies in this chamber.\n"
	terminalstring += tabbed("numdead:") + "The amount of dead anomalies in this chamber.\n"
	terminalstring += tabbed("chamindex:") + "The index of the current chamber.\n"
	terminalstring += tabbed("seed:") + "The current world seed.\n"
	terminalstring += "\n"

func restore():
	if otherstuff[OtherStuff.SPENT]:
		terminalstring += "You have already used this terminal to restore.\n\n"
		return
	Global.player.impacthealth(2)
	otherstuff[OtherStuff.SPENT] = true
	terminalstring += "Your health has been restored!\n\n"

func modlist():
	for mod in otherstuff[OtherStuff.MODS]:
		terminalstring += costandname(mod) + "\n"
	terminalstring += "\n"

func about(args: Array[String]):
	var mod = existentmod(args[1])
	if mod == null:
		return
	terminalstring += costandname(mod) + ": "
	terminalstring += Global.moddescs[mod] + "\n\n"

func add(args: Array[String]):
	var mod = existentmod(args[1])
	if mod == null:
		return
	if mod not in otherstuff[OtherStuff.MODS]:
		terminalstring += "This modifier is unavailable at this terminal.\n\n"
		return
	if mod in Global.player.modifiers:
		terminalstring += "This modifier has already been added.\n\n"
		return
	if len(Global.player.modifiers) == Global.maxmods:
		terminalstring += "Cannot exceed the max amount of modifiers.\n\n"
		return
	Global.player.modifiers.append(mod)
	for color in Anomaly.AnomColor.values():
		Global.player.scoremult[color] *= 2. ** -Global.modcosts[mod][color]
	terminalstring += Global.modnames[mod] + " added!\n\n"

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
			"info":
				if argquant(args, 2) and classfilter(TerminalClass.INFO):
					info(args)
			"infolist":
				if argquant(args, 1):
					infolist()
			"restore":
				if argquant(args, 1) and classfilter(TerminalClass.RESTORATION):
					restore()
			"modlist":
				if argquant(args, 1) and classfilter(TerminalClass.MOD):
					modlist()
			"about":
				if argquant(args, 2) and classfilter(TerminalClass.MOD):
					about(args)
			"add":
				if argquant(args, 2) and classfilter(TerminalClass.MOD):
					add(args)
	currentinput = ""
	newcommand()
