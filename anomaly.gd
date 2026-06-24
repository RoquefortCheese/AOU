extends CharacterBody3D
class_name Anomaly

@export var freqs: Dictionary[Color, int]
const floatconst = 4
const wobbleconst = 4
const followconst = 3
const repelconst = 6
const fallconst = -12
const heightfriction = -4
const flatfriction = -1
const noticeradius = 20
const followradius = 40
const committhresh = 0.25
const steppingconst = 1
const knockbackconst = 2
@export var boxmesh: BoxMesh

var alive: bool
var following: bool
var boxes: Array[MeshInstance3D]
var spinvels: Dictionary[MeshInstance3D, Vector3]
var acceleration: Vector3
var color: Color
var offset: float

func create(color: Color):
	self.alive = true
	self.color = color
	following = false
	$AudioStreamPlayer3D.pitch_scale = 2 ** (freqs[color] / 12.)
	offset = randf() * TAU
	for i in 3:
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
	commit()
	domath(delta)
	move_and_slide()
	if alive:
		maybetouch()

func spinboxes(delta: float):
	for box in boxes:
		for axis in 3:
			box.rotation[axis] += spinvels[box][axis] * delta

func hover():
	acceleration.y += wobbleconst * sin(Global.time() * PI + offset)
	var grounddist = INF
	for x in [-0.4, 0.4]:
		for z in [-0.4, 0.4]:
			var voxel = floor(position + Vector3(x, 1, z))
			if not Global.chamber.issolid(voxel):
				var ground = Global.chamber.ground(voxel)
				grounddist = min(grounddist, position.y - ground.y)
	var path = Global.flatten(acceleration)
	if path.length() >= steppingconst:
		var nextpath = floor(position + path.normalized() * 0.8)
		if not Global.chamber.issolid(nextpath):
			nextpath = Global.chamber.ground(nextpath)
		while Global.chamber.issolid(nextpath) and nextpath in Global.chamber.voxmap:
			nextpath.y += 1
		if nextpath in Global.chamber.voxmap:
			grounddist = min(grounddist, position.y - nextpath.y)
	if grounddist != INF:
		var error = grounddist - 1
		acceleration.y += min(floatconst * error ** 2, 32) * -sign(error)

func follow():
	var diff = Global.player.position - position
	var distance = diff.length()
	if not following and distance <= noticeradius:
		following = true
	if following and distance > followradius:
		following = false
	if following:
		acceleration += Global.flatten(diff).normalized() * followconst

func spaceout():
	for anomaly in Global.chamber.anomalies:
		if anomaly != self and anomaly.alive:
			var diff = position - anomaly.position
			if diff.length() >= 2 ** -4.: 
				acceleration += Global.flatten(diff.normalized() * repelconst / diff.length() ** 2)

func fall():
	if not is_on_floor():
		acceleration.y = fallconst

func commit():
	for axis in 3:
		if abs(acceleration[axis]) <= committhresh:
			acceleration[axis] = 0

func domath(delta: float):
	velocity.y *= exp(heightfriction) ** delta
	velocity.x *= exp(flatfriction) ** delta
	velocity.z *= exp(flatfriction) ** delta
	velocity += acceleration * delta

func maybetouch():
	for i in get_slide_collision_count():
		if get_slide_collision(i).get_collider() == Global.player:
			die(Global.player.position)
			Global.player.impacthealth(-1)
			break

func die(source: Vector3):
	velocity += (position - source).normalized() * knockbackconst
	if alive:
		alive = false
		$AudioStreamPlayer3D.playing = false
		for box in boxes:
			box.mesh.material.albedo_color *= 0.25
