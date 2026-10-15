extends Node3D

var state := GameState.new()
var navigation := GridNavigation.new()
var hero: Wretch
var camera: Camera3D
var hud: GameHUD
var shrine: Interactable
var targets: Array[Interactable] = []
var target: Interactable
var hover: Interactable
var action_time := 0.0
var feed_lock := 0.0
var elapsed := 0.0
var repath := 0.0
var paused := false
var destination: MeshInstance3D
var screenshot_taken := false
var performance_reported := false
var low_spec := false
var base_camera := Vector3(0,24,17)
var shrine_light: OmniLight3D
var last_mood := "IMPATIENT"
var persistence_enabled := DisplayServer.get_name() != "headless"
var save_path := "user://save_slot_1.json"
var autosave_time := 0.0
var autosave_blocked := false
var ritual: Tween
var gear_signature := ""
var gear_visual: Node3D

func _ready() -> void:
	low_spec = "--low-spec" in OS.get_cmdline_user_args()
	get_viewport().scaling_3d_scale = 0.65 if low_spec else 1.0
	build_stage()
	hero = preload("res://scenes/wretch.tscn").instantiate()
	add_child(hero)
	hero.position = Vector3(0,0,5)
	hero.model.root.scale = Vector3.ONE * 1.15
	hero.speed = state.balance.player.move_speed_world_units_per_second
	hud = GameHUD.new()
	add_child(hud)
	hud.setup(state)
	hud.feed_requested.connect(offer)
	hud.discard_requested.connect(func(item):
		if not paused and feed_lock <= 0:
			state.discard(item)
			save_game(false))
	hud.service_requested.connect(service)
	hud.save_requested.connect(save_game)
	hud.load_requested.connect(load_game)
	hud.close_requested.connect(cancel)
	destination = Sculpt.torus(self,Vector3.ZERO,0.27,0.025,Sculpt.mat("dac590",0.6,0,0.2))
	destination.visible = false
	if persistence_enabled and FileAccess.file_exists(save_path): load_game()
	if "--clay-review" in OS.get_cmdline_user_args():
		for node in shrine.find_children("*","MeshInstance3D",true,false):
			if node.material_override == null: continue
			var material: StandardMaterial3D = node.material_override.duplicate()
			material.albedo_color = Color("96938b")
			material.emission_enabled = false
			material.metallic = 0
			material.roughness = 0.85
			node.material_override = material

func build_stage() -> void:
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("182823")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("a6b7ae")
	settings.ambient_light_energy = 0.42
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = settings
	add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-52,-35,0)
	key.light_color = Color("ffe0b4")
	key.light_energy = 1.1
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 38
	key.shadow_bias = 0.035
	key.shadow_blur = 0.0
	add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-28,145,0)
	rim.light_color = Color("9abac1")
	rim.light_energy = 0.55
	add_child(rim)
	var lamp := OmniLight3D.new()
	shrine_light = lamp
	lamp.position = Vector3(0,3,1)
	lamp.light_color = Color("dfa3aa")
	lamp.light_energy = 0.65
	lamp.omni_range = 8
	add_child(lamp)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 18.5
	camera.position = base_camera
	add_child(camera)
	camera.look_at(Vector3(0,1,-1.5))
	camera.current = true
	var ground := Node3D.new()
	ground.name = "ForestFloor"
	add_child(ground)
	Woodland.terrain(ground,state.balance.world.seed)
	Sculpt.bake(ground)
	shrine = spawn("shrine",Vector3(0,0,-2),1)
	shrine.art.scale = Vector3.ONE * 1.08
	var positions := [Vector3(-7,0,-4),Vector3(7,0,-5),Vector3(-10,0,1),Vector3(10,0,1),Vector3(-6,0,-10),Vector3(5,0,-11),Vector3(-12,0,-8),Vector3(12,0,-9),Vector3(-12,0,8),Vector3(12,0,9)]
	for i in positions.size():
		var tree := spawn("pine",positions[i],i)
		tree.art.scale = Vector3.ONE * (0.85 + float(i % 4) * 0.13)
		tree.art.rotation.y = i * 1.71
	for i in 3: spawn("ore",Vector3(6+i*2.6,0,4.0+i*0.7),i)
	spawn("stone",Vector3(-4.8,0,3.0),3)
	spawn("stone",Vector3(-8,0,7.5),4)
	for i in 5: spawn("hare",Vector3(-6+i*2.7,0,5.2+(i%2)*1.1),i)
	# Crooked noticeboard and small candle procession.
	var props := Node3D.new()
	props.name = "VotiveProcession"
	add_child(props)
	var wood := Sculpt.mat("554537")
	Sculpt.limb(props,Vector3(-2.6,0,4.5),Vector3(-2.6,1.75,4.5),0.09,wood)
	var board := BoxMesh.new()
	board.size = Vector3(2.4,0.9,0.12)
	Sculpt.mesh(props,board,wood,Vector3(-2.6,1.45,4.5))
	for i in 8:
		var p := Vector3((-1 if i%2 == 0 else 1)*1.9,0,1+i*0.9)
		Sculpt.limb(props,p,p+Vector3(0,0.18+(i%3)*0.08,0),0.07,Sculpt.mat("d2c09c"))
		Sculpt.rock(props,p+Vector3(0,0.3+(i%3)*0.08,0),Vector3(0.035,0.08,0.035),Sculpt.mat("ffd28a",0.6,0,0.8))
	Sculpt.bake(props)

func spawn(kind: String, at: Vector3, variant: int) -> Interactable:
	var object: Interactable = preload("res://scenes/interactable.tscn").instantiate()
	add_child(object)
	object.setup(kind,at,variant)
	targets.append(object)
	if kind != "hare": navigation.block(at,object.radius)
	return object

func pick(mouse := Vector2(-1,-1)) -> Dictionary:
	if mouse.x < 0: mouse = get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse)
	var direction := camera.project_ray_normal(mouse)
	var query := PhysicsRayQueryParameters3D.create(origin,origin+direction*150,10)
	query.collide_with_areas = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		if hit.collider is Area3D: hit.collider = hit.collider.get_parent()
		return hit
	var ground = Plane(Vector3.UP,0).intersects_ray(origin,direction)
	return {"position":ground} if ground != null else {}

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5: save_game()
		if event.keycode == KEY_F9: load_game()
		if event.keycode == KEY_F2:
			low_spec = not low_spec
			get_viewport().scaling_3d_scale = 0.65 if low_spec else 1.0
			hud.hint.text = "3D render scale: 65% / HUD remains full resolution" if low_spec else "3D render scale: 100%"
		if event.keycode in [KEY_I,KEY_B]: hud.inventory_panel.visible = not hud.inventory_panel.visible
		if event.keycode == KEY_ESCAPE:
			if feed_lock > 0: return
			if target != null or not hero.path.is_empty() or hud.menu.visible:
				cancel()
			else:
				paused = not paused
				hero.set_physics_process(not paused)
				for node in targets: node.set_process(not paused)
				hud.busy = paused
				hud.refresh()
				hud.hint.text = "PAUSED / Escape to resume" if paused else "Click to move or interact."
	if not event is InputEventMouseButton or not event.pressed: return
	if event.button_index == MOUSE_BUTTON_WHEEL_UP: camera.size = maxf(16,camera.size-1)
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: camera.size = minf(28,camera.size+1)
	if paused or feed_lock > 0: return
	if event.button_index == MOUSE_BUTTON_RIGHT: cancel()
	if event.button_index != MOUSE_BUTTON_LEFT: return
	var hit := pick(event.position)
	if hit.is_empty(): return
	cancel()
	if hit.get("collider") is Interactable:
		var object: Interactable = hit.collider
		if object.depleted:
			hud.hint.text = "Available in %d seconds." % ceili(object.remaining)
			return
		select_target(object)
	else:
		var p: Vector3 = hit.position
		hero.path = navigation.route(hero.position,p)
		if not hero.path.is_empty():
			destination.position = hero.path[-1]+Vector3(0,0.06,0)
			destination.visible = true

func select_target(object: Interactable) -> void:
	target = object
	action_time = 0
	hero.path = navigation.route(hero.position,object.position,reach(object))
	hud.hint.text = object.title
	if hero.path.is_empty():
		hud.hint.text = "No clear route. Try another approach."
		target = null

func reach(object: Interactable) -> float:
	return object.radius + state.balance.player.interaction_range_world_units * 0.65 + (state.hunting_reach_bonus() if object.kind == "hare" else 0.0)

func cancel() -> void:
	target = null
	hero.path.clear()
	hero.working = false
	action_time = 0
	hud.menu.hide()
	destination.visible = false

func _process(delta: float) -> void:
	if paused: return
	elapsed += delta
	feed_lock = maxf(0,feed_lock-delta)
	hud.busy = feed_lock > 0
	autosave_time += delta
	if autosave_time >= state.balance.runtime.autosave_seconds:
		autosave_time = 0
		save_game(false)
	repath -= delta
	state.tick(delta)
	shrine.satisfaction_ratio = state.satisfaction/state.cap()
	shrine_light.light_energy = 0.12+shrine.satisfaction_ratio*0.8+shrine.pulse*0.5
	if state.mood() != last_mood:
		last_mood = state.mood()
		if state.satisfaction == 0: hud.notice.text = "Dormant. Feed raw meat to restore Satisfaction."
		elif state.satisfaction < 30: hud.notice.text = "Satisfaction low. Feed the shrine."
		else: hud.notice.text = ""
	var follow := Vector3(clampf(hero.position.x*0.23,-2.4,2.4),0,clampf((hero.position.z-5)*0.2,-1.5,1.8))
	camera.position = camera.position.lerp(base_camera+follow,delta*2)
	if hover != null: hover.marker.visible = false
	var hit := pick()
	hover = hit.get("collider") as Interactable
	if hover != null and not hover.depleted: hover.marker.visible = true
	for animal in targets:
		if animal.kind != "hare" or animal.depleted: continue
		animal.fleeing = animal.position.distance_to(hero.position) < 2.8 and not hero.working
		if animal.fleeing:
			var away := (animal.position-hero.position).normalized()
			var candidate := animal.position+away*delta*1.0
			if candidate.distance_to(animal.home) < 2 and not navigation.grid.is_point_solid(navigation.cell(candidate)):
				animal.position = candidate
				animal.art.rotation.y = atan2(away.x,away.z)
	if target != null:
		if target.depleted:
			cancel()
		elif hero.position.distance_to(target.position) <= reach(target)+0.12:
			hero.path.clear()
			if target == shrine:
				hud.menu.show()
				hero.working = false
			else:
				hero.working = true
				var direction := target.position-hero.position
				hero.model.root.rotation.y = atan2(direction.x,direction.z)
				action_time += delta
				if action_time > state.action_duration(target.kind): complete_harvest()
		elif target.kind == "hare" and repath <= 0:
			repath = 0.35
			hero.path = navigation.route(hero.position,target.position,reach(target))
	if hero.path.is_empty(): destination.visible = false
	if "--capture" in OS.get_cmdline_user_args() and elapsed > 2 and not screenshot_taken:
		screenshot_taken = true
		capture()
	if "--capture" in OS.get_cmdline_user_args() and elapsed > 8 and not performance_reported:
		performance_reported = true
		print("STEADY RENDER: FPS=",Engine.get_frames_per_second()," draws=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))

func complete_harvest() -> void:
	var at := target.position+Vector3(0,1.4,0)
	var drop := target.harvest(state)
	if drop.has("full"):
		hud.hint.text = "Inventory full. Press I to discard items."
	else:
		var parts := PackedStringArray()
		for item in drop: parts.append("+%d %s" % [drop[item],item.replace("_"," ")])
		popup("  ·  ".join(parts),at)
		hud.hint.text = "Click to move or interact."
	target = null
	hero.working = false
	action_time = 0
	save_game(false)

func offer() -> void:
	if paused or feed_lock > 0 or hero.position.distance_to(shrine.position) > reach(shrine)+0.3: return
	var before := state.satisfaction
	if not state.feed():
		hud.notice.text = "Raw meat required."
		return
	feed_lock = state.balance.runtime.service_cooldown
	shrine.pulse = 1.0
	hud.notice.text = "Satisfaction low. Feed the shrine." if state.satisfaction < 30 else ""
	popup("+%.1f Satisfaction" % (state.satisfaction-before),shrine.position+Vector3(0,5.8,1))
	var food := Sculpt.rock(self,hero.position+Vector3(0,1,0),Vector3(0.18,0.14,0.13),Sculpt.mat("b97878",0.5))
	var start := food.position
	var end := shrine.art.to_global(Vector3(0,3.3,1))
	var tween := create_tween()
	tween.tween_method(func(t: float): food.position = start.lerp(end,t)+Vector3.UP*sin(PI*t)*2,0.0,1.0,0.65)
	tween.tween_callback(food.queue_free)
	save_game(false)

func service(id: String) -> void:
	if paused or feed_lock > 0: return
	if hero.position.distance_to(shrine.position) > reach(shrine)+0.3:
		hud.notice.text = "Approach the shrine to use services."
		return
	var result := state.try_service(id)
	if not result.ok:
		hud.notice.text = result.message
		return
	feed_lock = state.balance.runtime.ritual_seconds
	hero.path.clear()
	shrine.pulse = 1.0
	hud.notice.text = result.spec.name + " complete."
	update_equipment()
	if id == "heal":
		ritual = create_tween()
		ritual.tween_property(hero.model.root,"scale",Vector3.ONE*0.03,0.4)
		ritual.tween_interval(0.15)
		ritual.tween_property(hero.model.root,"scale",Vector3.ONE*1.15,0.65)
		var ring := Sculpt.torus(self,hero.position+Vector3.UP*0.15,0.65,0.025,Sculpt.mat("b9c4a0",0.6,0,0.4))
		var glow := create_tween().set_parallel(true)
		glow.tween_property(ring,"position:y",1.7,1.2)
		glow.tween_property(ring,"scale",Vector3.ONE*0.05,1.2)
		glow.chain().tween_callback(ring.queue_free)
	else:
		# A bounded burst at the offering bowl; no persistent particle emitters.
		for i in 6:
			var origin := shrine.position+Vector3(2.3,0.85,1.4)
			var spark := Sculpt.rock(self,origin,Vector3.ONE*0.035,Sculpt.mat("d9bd7e",0.6,0,0.4),i)
			var motion := create_tween().set_parallel(true)
			motion.tween_property(spark,"position",origin+Vector3(cos(i)*0.5,0.6,sin(i)*0.5),0.6)
			motion.tween_property(spark,"scale",Vector3.ZERO,0.6)
			motion.chain().tween_callback(spark.queue_free)
	save_game(false)
	hud.busy = true
	hud.refresh()

func update_equipment() -> void:
	var signature := str(state.equipment)
	if signature == gear_signature: return
	gear_signature = signature
	if is_instance_valid(gear_visual): gear_visual.queue_free()
	gear_visual = Node3D.new()
	hero.model.root.add_child(gear_visual)
	var metal := Sculpt.mat("84958f",0.45,0.65)
	var leather := Sculpt.mat("654b3e")
	if state.equipment.has("backpack_upgrade"):
		for x in [-0.35,0.16]:
			Sculpt.rock(gear_visual,Vector3(x,0.76,-0.47),Vector3(0.16,0.3,0.19),leather)
	if state.equipment.has("hide_armor"):
		for x in [-0.3,0.3]: Sculpt.rock(gear_visual,Vector3(x,1.03,0),Vector3(0.2,0.12,0.25),metal if state.equipment.has("reinforced_armor") else leather)
	if state.equipment.has("spear"):
		Sculpt.limb(gear_visual,Vector3(-0.5,0.3,-0.25),Vector3(-0.5,1.95,-0.25),0.025,leather)
		Sculpt.rock(gear_visual,Vector3(-0.5,2.05,-0.25),Vector3(0.06,0.2,0.05),metal)
	if state.equipment.has("axe"):
		Sculpt.limb(gear_visual,Vector3(0.42,0.4,-0.3),Vector3(0.42,1.2,-0.3),0.035,leather)
		Sculpt.rock(gear_visual,Vector3(0.5,1.17,-0.3),Vector3(0.18,0.13,0.06),metal if state.equipment.has("tempered_axe") else Sculpt.mat("788079"))
	if state.equipment.has("iron_pickaxe"):
		Sculpt.limb(gear_visual,Vector3(-0.25,0.5,-0.6),Vector3(0.25,1.1,-0.6),0.03,leather)
		Sculpt.limb(gear_visual,Vector3(0.05,1.25,-0.6),Vector3(0.45,0.95,-0.6),0.035,metal)
	Sculpt.bake(gear_visual)

func save_game(manual := true) -> void:
	if not persistence_enabled or (autosave_blocked and not manual): return
	var error := SaveStore.write(save_path,self)
	if error.is_empty():
		autosave_blocked = false
		if manual: hud.notice.text = "Game saved."
	else: hud.notice.text = "Save failed: " + error

func load_game() -> void:
	if not persistence_enabled: return
	var result := SaveStore.read(save_path,self)
	if not result.error.is_empty():
		autosave_blocked = FileAccess.file_exists(save_path)
		hud.notice.text = "Load failed: " + result.error
		return
	cancel()
	if ritual != null and ritual.is_running(): ritual.kill()
	hero.model.root.scale = Vector3.ONE*1.15
	feed_lock = 0
	state.restore(result.data.character)
	hero.position = Vector3(result.data.position[0],0,result.data.position[2])
	for entry in result.data.world:
		for node in targets:
			if node.persistent_id == entry.id: node.restore_entry(entry)
	update_equipment()
	autosave_blocked = false
	autosave_time = 0
	hud.notice.text = "Game loaded."

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(hud): save_game(false)

func popup(content: String, at: Vector3) -> void:
	var label := Sculpt.label(self,content,at,24)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label,"position",at+Vector3.UP,1.6)
	tween.tween_property(label,"modulate:a",0.0,1.6)
	tween.chain().tween_callback(label.queue_free)

func capture() -> void:
	await RenderingServer.frame_post_draw
	var filename := "clay-review" if "--clay-review" in OS.get_cmdline_user_args() else "first-light"
	get_viewport().get_texture().get_image().save_png("res://captures/%s.png" % filename)
	print("CAPTURE: res://captures/%s.png" % filename)
	print("RENDER: FPS=",Engine.get_frames_per_second()," draws=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))



