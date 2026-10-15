class_name Interactable
extends StaticBody3D

var kind := "pine"
var persistent_id := ""
var title := ""
var radius := 0.7
var art: Node3D
var depleted := false
var remaining := 0.0
var age := 0.0
var home := Vector3.ZERO
var fleeing := false
var pulse := 0.0
var marker: MeshInstance3D
var drop_label: Label3D
var stump: Node3D
var satisfaction_ratio := 0.65

func setup(type: String, at: Vector3, variant: int) -> void:
	kind = type
	persistent_id = "%s_%d" % [type,variant]
	position = at
	home = at
	# Prey remain ray-pickable, but cannot pin the player against a grid waypoint.
	collision_layer = 8 if kind == "hare" else 2
	collision_mask = 0
	match kind:
		"shrine":
			title = "Widow of Roots / Services"
			radius = 2.0
			art = Creatures.shrine(self)
		"pine":
			title = "Pine / Chop wood"
			radius = 0.65
			art = Woodland.pine(self,variant)
			stump = Sculpt.rock(self,Vector3(0,0.23,0),Vector3(0.4,0.3,0.36),Sculpt.mat("776044"),variant)
			stump.visible = false
		"hare":
			title = "Hare / Hunt for meat and hide"
			radius = 0.42
			art = Creatures.hare(self)
		_:
			title = "Ore / Mine" if kind == "ore" else "Stone / Quarry"
			radius = 0.85
			art = Woodland.ore(self,variant,kind == "ore")
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = 1.1 if kind != "shrine" else 6.0
	shape.shape = cylinder
	shape.position.y = cylinder.height*0.5
	add_child(shape)
	if kind == "pine":
		var pick_area := Area3D.new()
		pick_area.collision_layer = 8
		pick_area.collision_mask = 0
		var canopy := CollisionShape3D.new()
		var volume := CylinderShape3D.new()
		volume.radius = 1.65
		volume.height = 4.4
		canopy.shape = volume
		canopy.position.y = 3.2
		pick_area.add_child(canopy)
		add_child(pick_area)
	marker = Sculpt.torus(self,Vector3(0,0.06,0),radius+0.22,0.025,Sculpt.mat("d3bd80",0.6,0,0.2))
	marker.visible = false

func _process(delta: float) -> void:
	age += delta
	pulse = maxf(0,pulse-delta)
	if depleted:
		remaining -= delta
		if remaining <= 0:
			depleted = false
			art.visible = true
			collision_layer = 8 if kind == "hare" else 2
			if stump != null: stump.visible = false
			if is_instance_valid(drop_label): drop_label.queue_free()
		return
	if kind == "shrine":
		art.scale.x = 1.08+sin(age*1.3)*(0.008+satisfaction_ratio*0.016)+sin(pulse*9)*pulse*0.045
		art.scale.y = 1.04+satisfaction_ratio*0.04+sin(age*1.3+0.6)*0.009
	elif kind == "hare":
		art.position.y = maxf(0,sin(age*(12 if fleeing else 3.5)))*(0.22 if fleeing else 0.045)
		art.rotation.x = sin(age*3.5)*0.035

func harvest(state: GameState) -> Dictionary:
	if depleted: return {}
	var drop: Dictionary
	match kind:
		"hare": drop = state.balance.drops.hare.duplicate()
		"pine": drop = {"wood":state.balance.drops.pine.wood_min + (int(home.x*10) % 3 + 3) % 3}
		"ore": drop = {"ore":state.balance.drops.ore_rock.ore_min}
		_: drop = {"stone":state.balance.drops.stone_rock.stone_min}
	if not state.collect(drop): return {"full":true}
	depleted = true
	remaining = state.balance.runtime.prey_renew_seconds if kind == "hare" else state.balance.runtime.resource_renew_seconds
	art.visible = false
	if kind == "hare": collision_layer = 0
	if stump != null: stump.visible = true
	marker.visible = false
	# Renewable nodes retain a low stump/marker and collider, keeping navigation stable.
	if kind != "hare":
		drop_label = Sculpt.label(self,"Regrowing",Vector3(0,0.4,0),18)
	return drop

func restore_entry(entry: Dictionary) -> void:
	position = Vector3(entry.position[0],0,entry.position[2])
	depleted = entry.depleted
	remaining = entry.remaining
	art.visible = not depleted
	collision_layer = (0 if depleted else 8) if kind == "hare" else 2
	if stump != null: stump.visible = depleted
	if is_instance_valid(drop_label): drop_label.queue_free()
	if depleted and kind != "hare": drop_label = Sculpt.label(self,"Regrowing",Vector3(0,0.4,0),18)
	marker.visible = false

