class_name CombatUnit
extends CharacterBody3D

var uid := 0
var territory_id := ""
var base_id := ""
var kind := "raider"
var health := 42.0
var maximum_health := 42.0
var home := Vector3.ZERO
var path := PackedVector3Array()
var cooldown := 0.0
var repath := 0.0
var swing := 0.0
var hit := 0.0
var clock := 0.0
var scout := false
var stats: Dictionary
var model: Dictionary
var label: Label3D

func setup(data: Dictionary, config: Dictionary, wave: int) -> void:
	uid = int(data.id)
	base_id = data.get("base_id","")
	kind = data.kind
	health = data.health
	position = Vector3(data.position[0],0,data.position[2])
	home = Vector3(data.home[0],0,data.home[2])
	scout = data.scout
	cooldown = data.cooldown
	stats = config.units[kind]
	maximum_health = stats.health + (minf(wave,config.max_wave_bonus)*config.health_per_wave if kind == "raider" else 0)
	collision_layer = 16
	collision_mask = 2
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.28
	shape.height = 1.7
	collision.shape = shape
	collision.position.y = 0.85
	add_child(collision)
	model = CombatArt.unit(self,kind)
	label = Sculpt.label(self,"",Vector3(0,2.5,0),18)
	label.modulate = Color("b64f44") if kind == "raider" else Color("b9c4a0")

func step(delta: float) -> void:
	clock += delta
	cooldown = maxf(0,cooldown-delta)
	repath -= delta
	swing = maxf(0,swing-delta)
	hit = maxf(0,hit-delta)
	velocity = Vector3.ZERO
	if not path.is_empty() and swing <= 0:
		var direction := path[0]-position
		if direction.length() < 0.14: path.remove_at(0)
		else:
			velocity = direction.normalized()*minf(stats.speed,direction.length()/delta)
			model.root.rotation.y = lerp_angle(model.root.rotation.y,atan2(direction.x,direction.z),delta*8)
	move_and_slide()
	position.y = 0
	var walking := velocity.length() > 0.1
	for i in 2:
		model.legs[i].rotation.x = sin(clock*8+i*PI)*0.4 if walking else 0
		model.arms[i].rotation.x = -sin(swing/0.4*PI)*1.5 if swing > 0 else sin(clock*8+i*PI)*0.15 if walking else 0
	model.root.rotation.z = sin(hit*40)*hit*0.4
	label.text = "%d / %d" % [health,maximum_health] if health < maximum_health else ""

func serialize() -> Dictionary:
	return {"id":uid,"base_id":base_id,"kind":kind,"health":health,"position":[position.x,0,position.z],"home":[home.x,0,home.z],"cooldown":cooldown,"scout":scout}
