extends StaticBody3D
class_name Computer

const charsperline = 63
const maxlines = 35

@export var allowedchars: Array[Key]
@export_multiline var terminalstring: String
var inputhistory: Array[String]
var historyscroll: int
var currentinput: String

func _ready():
	historyscroll = 0
	newcommand()

func _process(delta: float):
	writeoutput()

func newcommand():
	terminalstring += "\n$root: "

func writeoutput():
	var output = terminalstring + currentinput
	if Global.player.usingterminal:
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
	if Global.player.usingterminal:
		if event is InputEventKey and not event.is_echo() and event.is_pressed():
			var key = event.keycode
			if key in allowedchars and len(currentinput) < 16:
				currentinput += char(key).to_lower()
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
	if currentinput != "":
		inputhistory.append(currentinput)
		historyscroll += 1
	terminalstring += currentinput
	currentinput = ""
	newcommand()
