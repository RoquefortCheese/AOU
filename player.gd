extends CharacterBody3D

const sensitivity = 0.005
const jumpspeed = 10
const cruisespeed = 10
const friction = -6
const acc = cruisespeed * -friction

var equipment: Dictionary[String, Variant]
var score: int
var pan: Vector3

func _ready():
	Global.player = self
	$Camera3D.rotation.y = randf() * PI * 2
	pan = $Camera3D.rotation
	$Camera3D/RayCast3D.add_exception(self)
	equipment = {"leftclick": null, "rightclick": null}
	score = 0
	
	equip("leftclick", Global.EquipmentType.PISTOL)

func _physics_process(delta: float):
	handlecam(delta)
	movementinput(delta)
	useequipment(delta)
	considerfocusing()
	otherphysics(delta)
	belikelumi()

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
	for axis in 2:
		$Camera3D.rotation[axis] += (pan[axis] - $Camera3D.rotation[axis]) * (1 - (2 ** 48) ** -delta)
	$MeshInstance3D.rotation.y = $Camera3D.rotation.y + PI

func useequipment(delta: float):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		for hand in equipment:
			if Input.is_action_just_pressed(hand) and equipment[hand] != null:
				equipment[hand].fire()

func considerfocusing():
	if Input.is_action_just_pressed("leftclick"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func otherphysics(delta: float):
	velocity.x *= exp(friction) ** delta
	velocity.z *= exp(friction) ** delta
	if not is_on_floor():
		velocity.y -= 10 * delta
	move_and_slide()

func belikelumi():
	for i in get_slide_collision_count():
		if get_slide_collision(i).get_collider() == Global.chamber.door:
			score += Global.chamber.score
			print(score)
			Global.world.enterdoor()

func equip(hand: String, eqtype: Global.EquipmentType):
	var item = Global.equipment[eqtype].instantiate()
	item.equip()
	equipment[hand] = item

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			pan.y -= event.relative.x * sensitivity
			pan.x -= event.relative.y * sensitivity
			pan.x = clamp(pan.x, -PI / 2, PI / 2)
