extends CharacterBody3D
class_name Player

const sensitivity = 0.005
const jumpspeed = 12
const cruisespeed = 8
const friction = -6
const coyotetime = 0.25
const reloadtime = 15
const acc = cruisespeed * -friction

var pan: Vector3
var timesinceground: float
var timesinceempty: float
var terminalinuse: Computer
var jumpsleft: int
var fallvel: float
var compassindex: int

var score: Dictionary[Anomaly.AnomColor, int]
var modifiers: Array[Global.Modifier]
var alive: bool
var balance: int
var health: int
var ammo: int
var acceleration: Vector3

func getfollowers():
	var following = 0
	for anomaly in Global.chamber.anomalies:
		if anomaly.alive and anomaly.following:
			following += 1
	return following

func maxammo():
	return Global.ifmod(12, 24, Global.Modifier.MOREAMMO)

func maxjumps():
	if Global.hasmod(Global.Modifier.TRIPLEJUMP):
		return 3
	if Global.hasmod(Global.Modifier.DOUBLEJUMP):
		return 2
	return 1

func invine():
	return Global.chamber.getvox(position) == Global.Vox.PILLARVINE

func scoremult(color: Anomaly.AnomColor):
	var mult = 1
	for mod in modifiers:
		if Global.modcolors[mod] == color:
			mult *= 2 ** (Global.modcosts[mod] / 4.)  # used to be modcosts[color]; this took embarrasingly long to notice
	return mult

func productscore(color: Anomaly.AnomColor):
	return int(score[color] * scoremult(color))

func totalscore():
	var total = 0
	for color in 3:
		total += productscore(color)
	return total

func _ready():
	Global.player = self
	$Camera3D/RayCast3D.add_exception(self)
	score = {Anomaly.AnomColor.BLUE: 0, Anomaly.AnomColor.CYAN: 0, Anomaly.AnomColor.MAGENTA: 0}
	modifiers = []
	alive = true
	balance = 0
	health = 6
	ammo = maxammo()
	timesinceground = 0
	terminalinuse = null
	jumpsleft = 0
	fallvel = 0
	compassindex = 0

func _physics_process(delta: float):
	acceleration = Vector3.ZERO
	handlecam(delta)
	movementinput()
	useequipment()
	reload(delta)
	considerfocusing()
	otherphysics(delta)
	domath(delta)
	belikelumi()

func movementinput():
	if terminalinuse == null:
		var direction = Vector3.ZERO
		if Input.is_action_pressed("forward"):
			direction += Vector3.FORWARD
		if Input.is_action_pressed("back"):
			direction += Vector3.BACK
		if Input.is_action_pressed("left"):
			direction += Vector3.LEFT
		if Input.is_action_pressed("right"):
			direction += Vector3.RIGHT
		if is_on_floor() or invine():
			jumpsleft = maxjumps()
		if timesinceground >= coyotetime and not invine():
			jumpsleft = min(maxjumps() - Global.ifmod(1, 0, Global.Modifier.AIRJUMP), jumpsleft)
		var finalacc = acc * Global.ifmod(1, 1.25, Global.Modifier.RUNNING) * Global.ifmod(1, 0.75, Global.Modifier.STROLLING)
		if Global.hasmod(Global.Modifier.WALLRUN) and is_on_wall():
			finalacc *= 2
		acceleration = Global.flatten(direction.rotated(Vector3.UP, $Camera3D.rotation.y).normalized()) * finalacc

func useterminal(terminal: Computer):
	terminalinuse = terminal
	$PostProcessing.material.set_shader_parameter("crosshair", false)

func stopusingterminal():
	terminalinuse = null
	$PostProcessing.material.set_shader_parameter("crosshair", true)

func handlecam(delta: float):
	for axis in 2:
		$Camera3D.rotation[axis] += (pan[axis] - $Camera3D.rotation[axis]) * (1 - (2 ** 48) ** -delta)
	$MeshInstance3D.rotation.y = $Camera3D.rotation.y + PI

func useequipment():
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_action_just_pressed("leftclick"):
		if terminalinuse != null:
			stopusingterminal()
		else:
			var target = $Camera3D/RayCast3D.get_collider()
			if target is Computer:
				if Global.dist(target.position, $Camera3D/RayCast3D.global_position) <= 1.5:
					useterminal(target)
			if terminalinuse == null:
				$Camera3D/HandPos/Pistol.fire()

func reload(delta: float):
	if ammo != 0:
		timesinceempty = 0
	timesinceempty += delta
	if ammo != maxammo() and (getfollowers() == 0 or timesinceempty >= reloadtime):
		ammo = maxammo()
		$ReloadAudioPlayer.play()

func considerfocusing():
	if Input.is_action_just_pressed("leftclick"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func otherphysics(delta: float):
	if is_on_floor():
		timesinceground = 0
		if Global.hasmod(Global.Modifier.FALLDAMAGE):
			impacthealth(min(0, floor((fallvel + 16) / 8)))
	else:
		var gravity = 12
		if Global.hasmod(Global.Modifier.FLOATY):
			gravity -= 3
		if Global.hasmod(Global.Modifier.DENSE):
			gravity += 3
		acceleration.y -= gravity
		timesinceground += delta
	if Global.hasmod(Global.Modifier.PHOTOFIELD):
		for light in Global.chamber.lights:
			var diff = position - light.position
			acceleration += diff.normalized() * diff.length() ** -2 * 2 ** 9
	fallvel = velocity.y
	move_and_slide()

func domath(delta: float):
	if invine():
		for axis in 3:
			velocity[axis] *= exp(friction * 2) ** delta
	else:
		for axis in [0, 2]:
			velocity[axis] *= exp(friction) ** delta
	velocity += acceleration * delta

func belikelumi():
	for i in get_slide_collision_count():
		if get_slide_collision(i).get_collider() == Global.chamber.door:
			$DoorAudioPlayer.play()
			Global.world.enterdoor()
			break

func impacthealth(amount: int):
	if alive:
		if amount < 0:
			$HitAudioPlayer.play()
			if Global.hasmod(Global.Modifier.VENGEANCE):
				for anomaly in Global.chamber.anomalies:
					if Global.dist(position, anomaly.position) <= 6:
						anomaly.die($Camera3D.position, true)
		if amount > 0:
			$HealingAudioPlayer.play()
		if not Global.settings[Global.Setting.IMMORTALITY]:
			health = min(health + amount, 6)
		if health < 0:
			die()

func die():
	alive = false
	Global.finishcause = "You died."
	Global.world.finish()

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			pan.y -= event.relative.x * sensitivity
			pan.x -= event.relative.y * sensitivity
			pan.x = clamp(pan.x, -PI / 2, PI / 2)
	if event.is_action_pressed("jump") and terminalinuse == null:
		if jumpsleft != 0:
			var finaljumpspeed = jumpspeed
			if Global.hasmod(Global.Modifier.PLANTJUMP) and Global.meshtypes[Global.chamber.getvox(position)] == Global.MeshType.PLANT:
				finaljumpspeed *= 2
			velocity.y = finaljumpspeed
			jumpsleft -= 1
	if event.is_action_pressed("switchcompass") and terminalinuse == null:
		compassindex += 1
