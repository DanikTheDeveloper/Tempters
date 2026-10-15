extends SceneTree
var game: Node
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if ok: print("PASS: ",message)
	else:
		failures += 1
		push_error(message)
func frames(n: int) -> void:
	for i in n: await physics_frame
func settle() -> void:
	for i in 800:
		await process_frame
		if game.frontier.initialized and game.frontier.jobs.is_empty(): return
	check(false,"stream jobs completed within frame budget")
func move_to(at: Vector3) -> void:
	game.cancel()
	game.hero.position = at
	game.frontier.update_chunks()
	await settle()
func _initialize() -> void: call_deferred("run")
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await settle()
	game.combat.set_physics_process(false)
	var world: WorldStream = game.frontier
	var layout: WorldLayout = world.layout
	var seed_copy := WorldLayout.new(layout.seed_value)
	check(layout.descriptors(Vector2i(3,-2)) == seed_copy.descriptors(Vector2i(3,-2)),"same seed reproduces exact resource layout")
	check(layout.descriptors(Vector2i(3,-2)) != WorldLayout.new(layout.seed_value+1).descriptors(Vector2i(3,-2)),"different seeds change resource layout")
	check(layout.biome(Vector3(120,0,0)) == "desert" and layout.biome(Vector3(-120,0,0)) == "snow" and layout.biome(Vector3.ZERO) == "forest","three coherent regional biomes")
	check(game.targets.size() == 21 and world.chunks.size()<=11,"authored home nodes preserved and streaming bounded")
	check(world.explored.size()>0 and world.explored.size()<100,"fog reveals only local exploration")
	await move_to(Vector3(27,0,0))
	var started := Time.get_ticks_usec()
	var path: PackedVector3Array = game.navigation.route(game.hero.position,Vector3(40,0,0))
	print("WORLD NAV ms: ",(Time.get_ticks_usec()-started)/1000.0)
	check(not path.is_empty() and path[-1].distance_to(Vector3(40,0,0))<1,"cross-chunk route reaches destination")
	game.hero.path = path
	await frames(180)
	check(game.hero.position.x>36,"actual player crosses chunk boundary")
	await settle()
	await move_to(Vector3(70,0,6))
	await frames(30)
	check(world.landmarks.has("1:0"),"nearby landmark is discovered")
	var resource: Interactable
	for node in world.resources:
		if node.kind == "ore" and WorldLayout.chunk(node.home) == Vector2i(1,0): resource = node
	check(resource != null,"streamed biome resource exists")
	var id: String = resource.persistent_id
	for item in game.state.inventory: game.state.inventory[item] = 0
	var drop: Dictionary = resource.harvest(game.state)
	check(not drop.is_empty() and resource.depleted,"procedural resource grants real inventory")
	world.record(resource)
	await move_to(Vector3(260,0,0))
	check(world.changes.has(id) and world.resources.size()<=704 and world.chunks.size()<=11,"unload retains sparse harvest state with bounded live nodes")
	await move_to(Vector3(70,0,6))
	for node in world.resources:
		if node.persistent_id == id: resource = node
	check(resource.depleted and resource.harvest(game.state).is_empty(),"revisit cannot duplicate harvested resource")
	game.save_path = "user://world_%d.json" % OS.get_process_id()
	game.persistence_enabled = true
	game.expedition.bond = 12
	game.expedition.grace = 7
	game.save_game()
	check(SaveStore.read(game.save_path,game).error.is_empty(),"remote world snapshot validates")
	game.load_game()
	await settle()
	check(game.hero.position.distance_to(Vector3(70,0,6))<1 and game.expedition.bond<=12 and world.changes.has(id) and world.landmarks.has("1:0"),"world reload preserves remote position Bond harvest and exploration")
	game.persistence_enabled = false
	game.hero.path = game.navigation.route(game.hero.position,Vector3(75,0,6))
	var start: Vector3 = game.hero.position
	await frames(60)
	check(game.hero.position.distance_to(start)>1,"movement works after remote reload")
	game.expedition.bond = 50
	var satisfaction: float = game.state.satisfaction
	game.expedition.tick(1)
	check(game.expedition.bond<50 and game.state.satisfaction==satisfaction,"Bond drains independently of Satisfaction")
	await move_to(Vector3(0,0,5))
	game.state.satisfaction = 40
	game.expedition.bond = 20
	game.expedition.tick(1)
	check(game.expedition.bond>20,"fed owned shrine recharges Bond")
	var cap: float = game.state.bond_cap()
	game.state.level += 1
	check(game.state.bond_cap()>cap,"shrine level increases expedition capacity")
	for scenario in ["movement","gathering","combat","full bag","reload"]:
		await move_to(Vector3(70,0,6))
		game.state.health = 8
		for item in game.state.inventory: game.state.inventory[item] = 0
		game.state.inventory.wood = 15
		game.expedition.bond = 0
		game.expedition.grace = 0.2
		game.hero.path = world.route(game.hero.position,Vector3(75,0,6),0)
		if scenario == "gathering": game.select_target(world.resources[-1])
		if scenario == "combat": game.combat.select(game.combat.add_unit("raider",Vector3(0,0,-7.8)))
		if scenario == "reload":
			game.combat.phase = "raid"
			game.persistence_enabled = true
			game.save_game()
			game.load_game()
			game.persistence_enabled = false
		game.expedition.tick(0.25)
		check(game.hero.position.distance_to(Vector3(0,0,5))<0.1 and game.hero.path.is_empty() and game.target == null and game.state.inventory.wood==12 and game.state.health>0,"safe recall during "+scenario)
		game.expedition.tick(0.25)
		check(game.state.inventory.wood==12,"recall penalty charged only once during "+scenario)
	for actor in game.combat.units.duplicate(): game.combat.remove_unit(actor)
	game.combat.phase = "peace"
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_M
	root.push_input(event,true)
	check(game.exploration_map.expanded,"M opens expanded exploration map")
	event = event.duplicate()
	event.keycode = KEY_ESCAPE
	root.push_input(event,true)
	check(not game.exploration_map.expanded and not game.paused,"Escape dismisses map without locking input")
	await settle()
	game.combat.start_raid()
	game.combat.set_physics_process(true)
	await frames(480)
	check(game.combat.hostiles().size()>0 and game.combat.hostiles()[0].position.z>-32,"raiders navigate from the northern streamed chunk toward home")
	game.combat.set_physics_process(false)
	for actor in game.combat.units.duplicate(): game.combat.remove_unit(actor)
	game.combat.phase = "peace"
	var legacy := SaveStore.snapshot(game)
	legacy.version = 3
	legacy.erase("exploration")
	legacy.erase("expedition")
	var file := FileAccess.open(game.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	var migrated := SaveStore.read(game.save_path,game)
	check(migrated.error.is_empty() and migrated.data.version==5 and migrated.data.character.inventory.wood==legacy.character.inventory.wood and migrated.data.character.level==legacy.character.level,"W3 migration preserves character and grants Bond: "+migrated.error)
	var bad: Dictionary = migrated.data.duplicate(true)
	bad.expedition.bond = -1
	check(not SaveStore.validate(bad,game).is_empty(),"invalid Bond rejected")
	bad = migrated.data.duplicate(true)
	bad.exploration.changes["bad"] = {"remaining":10}
	check(not SaveStore.validate(bad,game).is_empty(),"invalid procedural resource rejected")
	if "--visual" in OS.get_cmdline_user_args():
		game.combat.refresh()
		game.hud.notice.text = ""
		for biome in ["desert","snow"]:
			await move_to(Vector3(100 if biome == "desert" else -100,0,6))
			game.expedition.bond = game.state.bond_cap()
			await frames(90)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://captures/w4-"+biome+".png")
	print("MAX STREAM JOB ms: ",world.max_job_ms)
	game.persistence_enabled = false
	game.queue_free()
	await frames(2)
	print("WORLD: ",checks," checks; failures: ",failures)
	quit(failures)
