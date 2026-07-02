extends CharacterBody3D
class_name Player

const sensitivity = 0.005
const jumpspeed = 12
const cruisespeed = 8
const friction = -6
const coyotetime = 0.25
const acc = cruisespeed * -friction

var pan: Vector3
var timesinceground: float
var terminalinuse: Computer
var jumpsleft: int

var score: Dictionary[Anomaly.AnomColor, int]
var modifiers: Array[Global.Modifier]
var balance: int
var health: int
var ammo: int

func getfollowers():
	var following = 0
	for anomaly in Global.chamber.anomalies:
		if anomaly.alive and anomaly.following:
			following += 1
	return following

func maxammo():
	return Global.ifmod(12, 18, Global.Modifier.MOREAMMO)

func currentblock():
	return Global.chamber.voxmap[floor(position)]

func scoremult(color: Anomaly.AnomColor):
	var mult = 1
	for mod in modifiers:
		if Global.modcolors[mod] == color:
			mult *= 2 ** (Global.modcosts[color] / -4.)
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
	balance = 0
	health = 6
	ammo = 0
	timesinceground = 0
	terminalinuse = null
	jumpsleft = 0

func _physics_process(delta: float):
	handlecam(delta)
	movementinput(delta)
	useequipment(delta)
	reload()
	considerfocusing()
	otherphysics(delta)
	belikelumi()

func movementinput(delta: float):
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
		if is_on_floor() or currentblock() == Global.Vox.PILLARVINE:
			jumpsleft = Global.ifmod(1, 2, Global.Modifier.DOUBLEJUMP)
		if timesinceground >= coyotetime and not currentblock() == Global.Vox.PILLARVINE:
			jumpsleft = min(Global.ifmod(0, 1, Global.Modifier.DOUBLEJUMP), jumpsleft)
		if Input.is_action_just_pressed("jump"):
			if jumpsleft != 0:
				velocity.y = jumpspeed
				jumpsleft -= 1
		direction = direction.rotated(Vector3.UP, $Camera3D.rotation.y).normalized() * acc * Global.ifmod(1, 1.25, Global.Modifier.RUNNING) * delta
		velocity.x += direction.x
		velocity.z += direction.z

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

func useequipment(delta: float):
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

func reload():
	if getfollowers() == 0:
		ammo = maxammo()

func considerfocusing():
	if Input.is_action_just_pressed("leftclick"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func otherphysics(delta: float):
	if is_on_floor():
		timesinceground = 0
	else:
		velocity.y -= Global.ifmod(12, 8, Global.Modifier.FLOATY) * delta
		timesinceground += delta
	velocity.x *= exp(friction) ** delta
	velocity.z *= exp(friction) ** delta
	if currentblock() == Global.Vox.PILLARVINE:
		for axis in 3:
			velocity[axis] *= exp(friction) ** delta
	move_and_slide()

func belikelumi():
	for i in get_slide_collision_count():
		if get_slide_collision(i).get_collider() == Global.chamber.door:
			stopusingterminal()
			Global.world.enterdoor()
			break

func impacthealth(amount: int):
	health = min(health + amount, 6)
	if health < 0:
		die()

func die():
	health = 0 ####
	print("oh no!!!")

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			pan.y -= event.relative.x * sensitivity
			pan.x -= event.relative.y * sensitivity
			pan.x = clamp(pan.x, -PI / 2, PI / 2)
