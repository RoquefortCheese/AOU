extends CharacterBody3D

const sensitivity = 0.005
const jumpspeed = 10
const cruisespeed = 10
const friction = -6
const acc = cruisespeed * -friction
var hookconst = 0.2
var hookpos
var pan: Vector3

func _ready():
	$Camera3D.rotation.y = randf() * PI * 2
	pan = $Camera3D.rotation
	hookpos = null

func _physics_process(delta: float):
	handlecam(delta)
	movementinput(delta)
	handlehookshot(delta)
	otherphysics(delta)

func movementinput(delta: float):
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
		if is_on_floor():
			velocity.y = jumpspeed
	direction = direction.rotated(Vector3.UP, $Camera3D.rotation.y).normalized() * acc * delta
	velocity.x += direction.x
	velocity.z += direction.z
	#print(sqrt(velocity.x ** 2 + velocity.z ** 2))

func handlecam(delta: float):
	for axis in range(2):
		$Camera3D.rotation[axis] += (pan[axis] - $Camera3D.rotation[axis]) * (1 - (2 ** 48) ** -delta)

func handlehookshot(delta: float):
	if Input.is_action_pressed("rightclick"):
		var campos = $Camera3D.global_position
		var gun = $Camera3D.get_node("GrappleGun").global_position
		var target = hookpos
		if hookpos == null:
			target = $Camera3D.get_node("RayCast3D").get_collision_point()
			hookpos = target
		$BoxLine.visible = true
		$BoxLine.line(gun, target)
		var direction = (target - campos).normalized()
		var springacc = hookconst * Global.dist(campos, target) ** 2
		velocity += direction * springacc * delta
	else:
		$BoxLine.visible = false
		hookpos = null

func otherphysics(delta: float):
	velocity.x *= exp(friction) ** delta
	velocity.z *= exp(friction) ** delta
	if not is_on_floor():
		velocity.y -= 10 * delta
	move_and_slide()

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			pan.y -= event.relative.x * sensitivity
			pan.x -= event.relative.y * sensitivity
			pan.x = clamp(pan.x, -PI * 0.49, PI * 0.49)
