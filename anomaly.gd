extends CharacterBody3D
class_name Anomaly

enum AnomColor {BLUE, CYAN, MAGENTA}
const colname: Dictionary[AnomColor, String] = {AnomColor.BLUE: "Blue", AnomColor.CYAN: "Cyan", AnomColor.MAGENTA: "Magenta"}
const actualcolor = {
	AnomColor.BLUE: Color.BLUE,
	AnomColor.CYAN: Color.CYAN,
	AnomColor.MAGENTA: Color.MAGENTA
}

const floatconst = 4
const wobbleconst = 4
const followconst = 6
const flyconst = 32
const steppingconst = 1
const repelconst = 6
const fallconst = -12
const wanderconst = 3
const heightfriction = -4
const flatfriction = -1
const noticeradius = 20
const followbuffer = 1.5
const committhresh = 0.25
const knockbackconst = 2
@export var boxmesh: BoxMesh

var alive: bool
var following: bool
var boxes: Array[MeshInstance3D]
var spinvels: Dictionary[MeshInstance3D, Vector3]
var acceleration: Vector3
var color: AnomColor
var offset: float
var timedead: float
var undead: bool
var tamed: bool
var wandergoal: Vector2

func create(color: AnomColor):
	self.alive = true
	self.color = color
	following = false
	offset = randf() * TAU
	undead = false
	tamed = false
	for i in 3:
		var box = MeshInstance3D.new()
		box.mesh = boxmesh.duplicate_deep()
		box.mesh.material.albedo_color = actualcolor[color]
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
		mayberegen(delta)
	commit()
	domath(delta)
	move_and_slide()
	if alive:
		maybetouch()

func flying():
	var diff = Global.player.position - position
	return Global.flatten(diff).length() <= 3 and diff.y >= 0

func spinboxes(delta: float):
	for box in boxes:
		for axis in 3:
			box.rotation[axis] += spinvels[box][axis] * delta

func hover():
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
	if not flying():
		acceleration.y += wobbleconst * sin(Global.time() * PI + offset)

func follow():
	var diff = Global.player.position - position
	var distance = diff.length()
	var actualnoticeradius = noticeradius
	if tamed:
		actualnoticeradius = 4
	elif color == AnomColor.BLUE and Global.hasmod(Global.Modifier.HYPERBLUE):
		actualnoticeradius = INF
	elif Global.hasmod(Global.Modifier.ALERTANOMS):
		actualnoticeradius *= 2
	if not following and distance <= actualnoticeradius:
		following = true
	if following and distance > actualnoticeradius * followbuffer:
		following = false
	if following:
		acceleration += Global.flatten(diff).normalized() * followconst
		if flying():
			acceleration += Vector3.UP * flyconst
	elif tamed:
		if wandergoal == null or randf() < 0.02:
			wandergoal = Vector2(randf_range(1, StartChamber.anomroomsize), randf_range(1, StartChamber.anomroomsize))
		acceleration += Global.flatten(Vector3(wandergoal.x, 0, wandergoal.y) - position).normalized() * wanderconst

func spaceout():
	if following or tamed:
		for anomaly in Global.chamber.anomalies:
			if anomaly != self and anomaly.alive:
				var diff = position - anomaly.position
				var length = diff.length()
				if length < 2 ** 4 and length >= 2 ** -4.:
					acceleration += Global.flatten(diff.normalized() * repelconst / length ** 2)

func fall():
	if not is_on_floor():
		acceleration.y = fallconst

func mayberegen(delta: float):
	timedead += delta
	if Global.hasmod(Global.Modifier.REGEN):
		if timedead >= 20:
			alive = true
			undead = true
			for box in boxes:
				box.mesh.material.albedo_color /= 0.25

func commit():
	for axis in 3:
		if abs(acceleration[axis]) <= committhresh:
			acceleration[axis] = 0

func domath(delta: float):
	velocity.y *= exp(heightfriction) ** delta
	velocity.x *= exp(flatfriction) ** delta
	velocity.z *= exp(flatfriction) ** delta
	if Global.hasmod(Global.Modifier.HYPERCYAN) and color == AnomColor.CYAN:
		acceleration *= 2
	elif Global.hasmod(Global.Modifier.FASTANOMS):
		acceleration *= 1.5
	velocity += acceleration * delta

func maybetouch():
	for i in get_slide_collision_count():
		if get_slide_collision(i).get_collider() == Global.player:
			die(Global.player.position, false)
			Global.player.impacthealth(-1)
			if Global.hasmod(Global.Modifier.HYPERMAGENTA) and color == AnomColor.MAGENTA:
				Global.player.impacthealth(-2)
			elif Global.hasmod(Global.Modifier.MOREOUCH):
				Global.player.impacthealth(-1)
			break

func die(source: Vector3, shot: bool):
	velocity += (position - source).normalized() * knockbackconst
	if shot:
		$ShotAudioPlayer.play()
	else:
		$ContactAudioPlayer.play()
	if alive:
		alive = false
		timedead = 0
		if following and shot and not undead:
			Global.player.score[color] += 1
		for box in boxes:
			box.mesh.material.albedo_color *= 0.25
