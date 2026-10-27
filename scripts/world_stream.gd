class_name WorldStream
extends Node3D
var game: Node
var layout: WorldLayout
var chunks: Dictionary = {}
var resources: Array[Interactable] = []
var changes: Dictionary = {}
var explored: Dictionary = {}
var landmarks: Dictionary = {}
var templates: Dictionary = {}
var ruin_templates: Dictionary = {}
var jobs: Array[Dictionary] = []
var retired: Array[Node] = []
var center := Vector2i(999,999)
var nav: GridNavigation
var nav_cache: Dictionary = {}
var nav_dirty := true
var initialized := false
var explore_clock := 0.0
var max_job_ms := 0.0

func setup(owner_game: Node) -> void:
	game = owner_game
	layout = WorldLayout.new(int(game.state.balance.world.seed))
	call_deferred("prepare")

func prepare() -> void:
	# Reuse already-authored, baked meshes; duplicate nodes share immutable meshes.
	await get_tree().process_frame
	for biome in ["forest","desert","snow"]:
		for kind in ["pine","hare","ore","stone"]:
			var source: Node3D
			if biome == "desert" and kind == "pine":
				source = FrontierArt.dry_tree(self)
				await get_tree().process_frame
			else:
				for existing in game.targets:
					if existing.kind == kind:
						game.occlusion.reset()
						source = existing.art.duplicate()
						add_child(source)
						break
			if biome != "forest":
				for mesh in source.find_children("*","MeshInstance3D",true,false):
					if mesh.material_override is StandardMaterial3D:
						var mat: StandardMaterial3D = mesh.material_override.duplicate()
						if mat.metallic < 0.3: mat.albedo_color = mat.albedo_color.lerp(Color("d6ded7") if biome == "snow" else Color("ba9464"),0.7 if biome == "snow" else 0.45)
						mesh.material_override = mat
			source.hide()
			templates[biome+kind] = source
	for biome in ["forest","desert","snow"]:
		var root := Node3D.new()
		add_child(root)
		FrontierArt.landmark(root,Vector3.ZERO,biome)
		await get_tree().process_frame
		root.hide()
		ruin_templates[biome] = root
	for node in game.targets:
		if node.kind == "stone":
			FrontierArt.pebble_mesh = node.art.get_child(0).mesh
			break
	# Prepare immutable actor/creature visuals between startup frames, never in a
	# terrain-completion job during an expedition. Instances share mesh resources.
	for kind in ["raider","golem"]:
		var model: Dictionary = CombatArt.unit(self,kind)
		model.root.hide()
		model.root.queue_free()
		await get_tree().process_frame
	for biome in ["desert","snow"]:
		if not game.creatures.templates.has(biome): game.creatures.build_template(biome)
		await get_tree().process_frame
	initialized = true
	update_chunks()

func update_chunks() -> void:
	if not initialized: return
	var next := WorldLayout.chunk(game.hero.position)
	if next == center: return
	center = next
	var wanted: Array[Vector2i] = [Vector2i.ZERO,Vector2i(0,-1)]
	for pinned in game.creatures.pinned_chunks():
		if not wanted.has(pinned): wanted.append(pinned)
	for x in range(-1,2):
		for z in range(-1,2):
			var cell := center+Vector2i(x,z)
			if not wanted.has(cell): wanted.append(cell)
	for cell in chunks.keys():
		if not wanted.has(cell): unload(cell)
	jobs = jobs.filter(func(job): return wanted.has(job.cell))
	wanted.sort_custom(func(a,b): return a.distance_squared_to(center)<b.distance_squared_to(center))
	for cell in wanted:
		if chunks.has(cell): continue
		var root := Node3D.new()
		add_child(root)
		chunks[cell] = {"root":root,"nodes":[],"ready":false}
		for row in range(0,32,4): jobs.append({"cell":cell,"row":row})
		for entry in layout.descriptors(cell): jobs.append({"cell":cell,"resource":entry})
		jobs.append({"cell":cell,"dressing":true})
		jobs.append({"cell":cell,"finish":true})
	nav_dirty = true

func unload(cell: Vector2i) -> void:
	game.creatures.unload_site(cell)
	for node in chunks[cell].nodes:
		record(node)
		if game.target == node: game.cancel()
		if game.hover == node: game.hover = null
		resources.erase(node)
		remove_child(node)
		retired.append(node)
	remove_child(chunks[cell].root)
	retired.append(chunks[cell].root)
	chunks.erase(cell)
	nav_dirty = true

func record(node: Interactable) -> void:
	if node.depleted:
		changes[node.persistent_id] = {"remaining":node.remaining}
	else: changes.erase(node.persistent_id)

func run_job() -> void:
	if jobs.is_empty(): return
	var start := Time.get_ticks_usec()
	var job: Dictionary = jobs.pop_front()
	if not chunks.has(job.cell): return
	var chunk_data: Dictionary = chunks[job.cell]
	if job.has("row"):
		FrontierArt.terrain(chunk_data.root,layout,job.cell,job.row,4)
	elif job.has("dressing"):
		FrontierArt.dressing(chunk_data.root,layout,job.cell)
	elif job.has("resource"):
		var entry: Dictionary = job.resource
		var node := Interactable.new()
		add_child(node)
		var art: Node3D = templates[entry.biome+entry.kind].duplicate()
		art.show()
		node.setup(entry.kind,entry.position,entry.variant,art)
		node.persistent_id = entry.id
		if entry.biome == "snow" and entry.kind == "hare":
			node.title = "Snow hare / Hunt"
			node.drop_override = {"raw_meat":2,"hide":2}
		if entry.biome == "desert" and entry.kind == "hare": node.title = "Sand hare / Hunt"
		if entry.biome == "desert" and entry.kind == "pine": node.title = "Dry timber / Gather"
		if entry.biome == "desert" and entry.kind == "ore":
			node.title = "Copper ore / Mine"
			node.drop_override = {"ore":3}
		if changes.has(entry.id): node.restore_entry({"position":[entry.position.x,0,entry.position.z],"depleted":true,"remaining":changes[entry.id].remaining})
		resources.append(node)
		chunk_data.nodes.append(node)
		if node.kind == "pine":
			node.add_to_group("camera_occluder_body")
			game.occlusion.register(node.art)
	else:
		chunk_data.ready = true
		if not layout.creature_site(job.cell).is_empty():
			game.creatures.spawn_site(job.cell)
		elif job.cell != Vector2i.ZERO:
			var landmark_at := layout.landmark(job.cell)
			var ruin: Node3D = ruin_templates[layout.biome(landmark_at)].duplicate()
			chunk_data.root.add_child(ruin)
			ruin.position = landmark_at
			ruin.show()
			game.occlusion.register(ruin)
			for side in [-1,1]:
				var body := StaticBody3D.new()
				chunk_data.root.add_child(body)
				body.position = landmark_at+Vector3(side*1.6,0,0)
				body.collision_layer = 2
				body.collision_mask = 0
				body.add_to_group("camera_occluder_body")
				var shape := CollisionShape3D.new()
				var cylinder := CylinderShape3D.new()
				cylinder.radius = 0.6
				cylinder.height = 3.5
				shape.shape = cylinder
				shape.position.y = 1.75
				body.add_child(shape)
		nav_dirty = true
	var duration := (Time.get_ticks_usec()-start)/1000.0
	max_job_ms = maxf(max_job_ms,duration)
	if duration > 50 and "--world-performance" in OS.get_cmdline_user_args(): print("SLOW STREAM ",job.keys()," ms ",duration)

func rebuild_nav(around: Vector2i) -> void:
	var lower := Vector2i(floori((around.x*64-96)/GridNavigation.STEP),floori((around.y*64-96)/GridNavigation.STEP))
	var bound := floori(WorldLayout.LIMIT/GridNavigation.STEP)
	nav = GridNavigation.new(Rect2i(lower,Vector2i(297,297)).intersection(Rect2i(-bound,-bound,bound*2+1,bound*2+1)))
	# Bulk native region fills avoid a synchronous per-cell GDScript scan.
	for x in range(around.x-2,around.x+3):
		for z in range(around.y-2,around.y+3):
			var cell := Vector2i(x,z)
			if chunks.has(cell) and chunks[cell].ready: continue
			var first := Vector2i(ceili((x*64-32)/GridNavigation.STEP),ceili((z*64-32)/GridNavigation.STEP))
			var last := Vector2i(ceili((x*64+32)/GridNavigation.STEP),ceili((z*64+32)/GridNavigation.STEP))
			var region := Rect2i(first,last-first).intersection(nav.grid.region)
			if region.has_area(): nav.grid.fill_solid_region(region,true)
	for node in game.targets+resources:
		if node.kind != "hare": nav.block(node.home,node.radius)
	for node in game.creatures.nodes.values(): nav.block(node.position,node.radius)
	for structure in game.buildings.structures: nav.block(structure.position,structure.radius)
	for cell in chunks:
		if cell != Vector2i.ZERO and chunks[cell].ready and layout.creature_site(cell).is_empty():
			for side in [-1,1]: nav.block(layout.landmark(cell)+Vector3(side*1.6,0,0),0.6)
	if nav_cache.size()>=2: nav_cache.clear()
	nav_cache[around] = nav
	nav_dirty = false

func route(from: Vector3, to: Vector3, reach: float) -> PackedVector3Array:
	if not initialized: return PackedVector3Array()
	update_chunks()
	if nav_dirty: nav_cache.clear()
	var around := WorldLayout.chunk(from)
	if not nav_cache.has(around): rebuild_nav(around)
	nav = nav_cache[around]
	var cell := WorldLayout.chunk(to)
	if absf(to.x)>WorldLayout.LIMIT or absf(to.z)>WorldLayout.LIMIT or not chunks.has(cell) or not chunks[cell].ready:
		game.hud.hint.text = "Terrain loading. Choose a nearer destination."
		return PackedVector3Array()
	return nav.route(from,to,reach)

func _process(delta: float) -> void:
	if not initialized: return
	update_chunks()
	var start := Time.get_ticks_usec()
	for i in 2:
		if not jobs.is_empty(): run_job()
		if Time.get_ticks_usec()-start>3000: break
	for i in mini(2,retired.size()): retired.pop_front().queue_free()
	for node in resources: node.set_process(not game.paused)
	if game.paused: return
	explore_clock += delta
	if explore_clock >= 0.4:
		explore_clock = 0
		var tile := Vector2i(floori(game.hero.position.x/4),floori(game.hero.position.z/4))
		for x in range(-3,4):
			for z in range(-3,4):
				if x*x+z*z<=9: explored[WorldLayout.key(tile+Vector2i(x,z))] = true
		for cell in chunks:
			if cell != Vector2i.ZERO and game.hero.position.distance_to(layout.landmark(cell))<16: landmarks[WorldLayout.key(cell)] = true

func serialize() -> Dictionary:
	for node in resources: record(node)
	return {"generator":1,"changes":changes.duplicate(true),"explored":explored.keys(),"landmarks":landmarks.keys()}

func restore(data: Dictionary) -> void:
	for cell in chunks.keys(): unload(cell)
	jobs.clear()
	changes = data.changes.duplicate(true)
	explored.clear()
	landmarks.clear()
	for key in data.explored: explored[key] = true
	for key in data.landmarks: landmarks[key] = true
	center = Vector2i(999,999)
	update_chunks()

func validate(data: Variant) -> String:
	if not data is Dictionary or data.get("generator") != 1 or not data.get("changes") is Dictionary or not data.get("explored") is Array or not data.get("landmarks") is Array: return "Incomplete exploration state."
	if data.changes.size()>30000 or data.explored.size()>100000 or data.landmarks.size()>20000: return "Exploration data exceeds limits."
	for key in data.changes:
		if not key is String: return "Invalid resource ID."
		var parts: PackedStringArray = key.split(":")
		if parts.size()!=4 or parts[0]!="c" or not parts[1].is_valid_int() or not parts[2].is_valid_int() or not parts[3].is_valid_int(): return "Invalid resource ID."
		if abs(int(parts[1]))>65 or abs(int(parts[2]))>65: return "Resource outside world bounds."
		var found := false
		var kind := ""
		for entry in layout.descriptors(Vector2i(int(parts[1]),int(parts[2]))):
			if entry.id == key:
				found = true
				kind = entry.kind
		if not found: return "Unknown procedural resource."
		var entry: Variant = data.changes[key]
		if not entry is Dictionary or not entry.get("remaining") is float and not entry.get("remaining") is int: return "Invalid resource change."
		var limit: float = game.state.balance.runtime.prey_renew_seconds if kind == "hare" else game.state.balance.runtime.resource_renew_seconds
		if not is_finite(entry.remaining) or entry.remaining<=0 or entry.remaining>limit: return "Invalid resource renewal."
	for list in [data.explored,data.landmarks]:
		for key in list:
			if not key is String: return "Invalid explored cell."
			var parts: PackedStringArray = key.split(":")
			if parts.size()!=2 or not parts[0].is_valid_int() or not parts[1].is_valid_int() or abs(int(parts[0]))>2048 or abs(int(parts[1]))>2048: return "Invalid explored coordinate."
	return ""

func _exit_tree() -> void:
	for node in retired:
		if is_instance_valid(node): node.free()
	retired.clear()
