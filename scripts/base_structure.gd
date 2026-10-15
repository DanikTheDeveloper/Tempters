class_name BaseStructure
extends StaticBody3D

var uid := 0
var kind := "palisade"
var tier := 1
var health := 100.0
var fuel := 0.0
var radius := 0.8
var art: Node3D
var marker: MeshInstance3D
var config: Dictionary
var ember: MeshInstance3D

func setup(data: Dictionary, settings: Dictionary) -> void:
	config = settings
	uid = int(data.id)
	kind = data.kind
	tier = int(data.tier)
	health = data.health
	fuel = data.fuel
	position = Vector3(data.position[0],0,data.position[2])
	rotation.y = data.angle
	radius = config.types[kind].radius
	collision_layer = 2
	collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = 1.7
	collision.shape = shape
	collision.position.y = 0.85
	add_child(collision)
	marker = Sculpt.torus(self,Vector3(0,0.06,0),radius+0.1,0.025,Sculpt.mat("baa473",0.7,0,0.15))
	marker.hide()
	if kind == "totem":
		ember = Sculpt.rock(self,Vector3(0,1.17,0.15),Vector3(0.065,0.12,0.04),Sculpt.mat("b8ba83",0.6,0,0.5))
	rebuild_art()

func maximum_health() -> float:
	return config.types[kind].health*(config.upgrade_multiplier if tier == 2 else 1.0)

func rebuild_art() -> void:
	if is_instance_valid(art):
		remove_child(art)
		art.queue_free()
	art = Fortifications.build(self,kind,tier)
	update_damage()

func update_damage() -> void:
	art.rotation.z = (1.0-health/maximum_health())*0.18
	art.position.y = -(1.0-health/maximum_health())*0.13
	if ember != null: ember.visible = fuel > 0

func serialize() -> Dictionary:
	return {"id":uid,"kind":kind,"tier":tier,"health":health,"fuel":fuel,"position":[position.x,0,position.z],"angle":rotation.y}
