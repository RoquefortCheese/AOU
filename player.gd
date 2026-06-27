extends CharacterBody3D

const sensitivity = 0.005
const jumpspeed = 10
const cruisespeed = 8
const friction = -6
const acc = cruisespeed * -friction

var modifiers: Array[Global.Modifier] = [Global.Modifier.MORESPACE]
var health: int
var usingterminal: bool
var pan: Vector3

func currentblock():
	return Global.chamber.voxmap[floor(position)]

func _ready():
	Global.player = self
	$Camera3D.rotation.y = randf() * PI * 2
	pan = $Camera3D.rotation
	$Camera3D/RayCast3D.add_exception(self)
	usingterminal = false
	health = 6

func _physics_process(delta: float):
	handlecam(delta)
	movementinput(delta)
	useequipment(delta)
	considerfocusing()
	otherphysics(delta)
	belikelumi()

func movementinput(delta: float):
	if not usingterminal:
		var direction = Vector3.ZERO
		if Input.is_action_pressed("forward"):
			direction += Vector3.FORWARD
		if Input.is_action_pressed("back"):
			direction += Vector3.BACK
		if Input.is_action_pressed("left"):
			direction += Vector3.LEFT
		if Input.is_action_pressed("right"):
			direction += Vector3.RIGHT
		if Input.is_action_just_pressed("jump"):
			if is_on_floor() or currentblock() == Global.Vox.PILLARVINE:
				velocity.y = jumpspeed
		direction = direction.rotated(Vector3.UP, $Camera3D.rotation.y).normalized() * acc * delta
		velocity.x += direction.x
		velocity.z += direction.z

func handlecam(delta: float):
	for axis in 2:
		$Camera3D.rotation[axis] += (pan[axis] - $Camera3D.rotation[axis]) * (1 - (2 ** 48) ** -delta)
	$MeshInstance3D.rotation.y = $Camera3D.rotation.y + PI

func useequipment(delta: float):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_action_just_pressed("leftclick"):
		if usingterminal:
			usingterminal = false
		else:
			$Camera3D/HandPos/Pistol.fire()

func considerfocusing():
	if Input.is_action_just_pressed("leftclick"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func otherphysics(delta: float):
	if not is_on_floor():
		velocity.y -= Global.ifmod(12, 8, Global.Modifier.FLOATY) * delta
	velocity.x *= exp(friction) ** delta
	velocity.z *= exp(friction) ** delta
	if currentblock() == Global.Vox.PILLARVINE:
		for axis in 3:
			velocity[axis] *= exp(friction) ** delta
	move_and_slide()

func belikelumi():
	for i in get_slide_collision_count():
		if get_slide_collision(i).get_collider() == Global.chamber.door:
			usingterminal = false
			impacthealth(1)
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
