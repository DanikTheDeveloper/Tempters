class_name Wretch
extends CharacterBody3D

var path := PackedVector3Array()
var model: Dictionary
var speed := 5.0
var clock := 0.0
var working := false

func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	var collider := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.28
	shape.height = 1.3
	collider.shape = shape
	collider.position.y = 0.65
	add_child(collider)
	model = Creatures.wretch(self)

func _physics_process(delta: float) -> void:
	clock += delta
	velocity = Vector3.ZERO
	if not path.is_empty() and not working:
		var direction := path[0]-position
		direction.y = 0
		if direction.length() < 0.14:
			path.remove_at(0)
		else:
			velocity = direction.normalized()*minf(speed,direction.length()/delta)
			model.root.rotation.y = lerp_angle(model.root.rotation.y,atan2(direction.x,direction.z),delta*12)
	move_and_slide()
	position.y = 0
	var walking := velocity.length() > 0.1
	model.legs[0].rotation.x = sin(clock*12)*0.55 if walking else 0.0
	model.legs[1].rotation.x = -sin(clock*12)*0.55 if walking else 0.0
	model.root.position.y = absf(sin(clock*12))*0.045 if walking else sin(clock*2)*0.015
	model.arm.rotation.x = sin(clock*16)*1.1-0.6 if working else sin(clock*12)*0.2 if walking else 0.0

