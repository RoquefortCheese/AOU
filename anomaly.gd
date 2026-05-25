extends CharacterBody3D
class_name Anomaly

const floatconst = 4
const wobbleconst = 4
const followconst = 3
const repelconst = 6
const fallconst = -12
const heightfriction = -4
const flatfriction = -1
const followradius = 20
@export var boxmesh: BoxMesh

var alive: bool
var boxes: Array[MeshInstance3D]
var spinvels: Dictionary[MeshInstance3D, Vector3]
var acceleration: Vector3
var chamber: Node
var color: Color
var offset: float

func create(chamber: Node, color: Color):
	self.alive = true
	self.chamber = chamber
	self.color = color
	offset = randf() * TAU
	for i in range(3):
		var box = MeshInstance3D.new()
		box.mesh = boxmesh.duplicate_deep()
		box.mesh.material.albedo_color = color
		boxes.append(box)
		spinvels[box] = Vector3(randf(), randf(), randf()) * PI
		add_child(box)

func _physics_process(delta: float):
	acceleration = Vector3.ZERO
	if alive:
		spinboxes(delta)
		follow()
		spaceout()
		hover()
	else:
		fall()
	domath(delta)
	move_and_slide()

func spinboxes(delta: float):
	for box in boxes:
		for axis in range(3):
			box.rotation[axis] += spinvels[box][axis] * delta

func hover():
	acceleration.y += wobbleconst * sin(Global.time() * PI + offset)
	var grounddist = INF
	for x in [-0.4, 0.4]:
		for z in [-0.4, 0.4]:
			var voxel = floor(position + Vector3(x, 1, z))
			if voxel in chamber.groundmap:
				var ground = chamber.groundmap[voxel]
				grounddist = min(grounddist, position.y - ground.y)
	var nextpath = floor(position + Global.flatten(acceleration).normalized() * 0.8)
	if nextpath in chamber.groundmap:
		nextpath = chamber.groundmap[nextpath]
	while nextpath not in chamber.groundmap and nextpath in chamber.voxmap:
		nextpath.y += 1
	if nextpath in chamber.voxmap:
		grounddist = min(grounddist, position.y - nextpath.y)
	if grounddist != INF:
		var error = grounddist - 1
		acceleration.y += min(floatconst * error ** 2, 32) * -sign(error)

func follow():
	var diff = Global.player.position - position
	if diff.length() <= followradius:
		acceleration += Global.flatten(diff).normalized() * followconst

func spaceout():
	for anomaly in chamber.anomalies:
		if anomaly != self:
			var diff = position - anomaly.position
			if diff.length() >= 2 ** -4.:
				acceleration += diff.normalized() * repelconst / diff.length() ** 2

func fall():
	if not is_on_floor():
		acceleration.y = fallconst

func domath(delta: float):
	velocity.y *= exp(heightfriction) ** delta
	velocity.x *= exp(flatfriction) ** delta
	velocity.z *= exp(flatfriction) ** delta
	velocity += acceleration * delta

func die():
	if alive:
		alive = false
		for box in boxes:
			box.mesh.material.albedo_color *= 0.25
