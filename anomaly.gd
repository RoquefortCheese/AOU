extends CharacterBody3D

const floatconst = 4
const wobbleconst = 4
const friction = -4
@export var boxmesh: BoxMesh

var boxes: Array[MeshInstance3D]
var spinvels: Dictionary[MeshInstance3D, Vector3]
var chamber: Node
var color: Color
var offset: float

func create(chamber: Node, color: Color):
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
	spinboxes(delta)
	hover(delta)

func spinboxes(delta: float):
	for box in boxes:
		for axis in range(3):
			box.rotation[axis] += spinvels[box][axis] * delta

func hover(delta: float):
	velocity.y *= exp(friction) ** delta
	velocity.y += wobbleconst * sin(Global.time() * PI + offset) * delta
	var grounddist = INF
	for x in [-0.4, 0.4]:
		for z in [-0.4, 0.4]:
			var voxel = floor(position + Vector3(x, 0, z))
			if voxel in chamber.groundmap:
				var ground = chamber.groundmap[voxel]
				grounddist = min(grounddist, position.y - ground.y)
	if grounddist != INF:
		var error = grounddist - 1
		velocity.y += floatconst * error ** 2 * -sign(error) * delta
	move_and_slide()
