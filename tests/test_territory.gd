extends SceneTree
var game: Node
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: ",message)
	else:
		failures += 1
		push_error(message)
func settle() -> void:
	for i in 1600:
		await process_frame
		if game.frontier.initialized and game.frontier.jobs.is_empty(): return
	check(false,"streaming completes")
func move(at: Vector3) -> void:
	game.cancel()
	game.hero.position = at
	game.frontier.update_chunks()
	await settle()
	await physics_frame
func _initialize() -> void: call_deferred("run")
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await settle()
	game.combat.set_physics_process(false)
	game.set_process(false)
	var manager: CreatureManager = game.creatures
	var layout: WorldLayout = game.frontier.layout
	var east := layout.creature_site(Vector2i(4,0))
	var west := layout.creature_site(Vector2i(-4,0))
	check(not east.is_empty() and east.biome=="desert" and west.biome=="snow","rare eastern and western shrine opportunities")
	check(east==WorldLayout.new(layout.seed_value).creature_site(Vector2i(4,0)),"deterministic creature identity and location")
	check(layout.creature_site(Vector2i.ZERO).is_empty() and CreatureManager.point(east).distance_to(CreatureManager.point(west))>500,"separated sites outside starting region")
	for descriptor in layout.descriptors(Vector2i(4,0)):
		check(descriptor.position.distance_to(CreatureManager.point(east))>=6,"existing resource positions remain outside shrine clearing")
	await move(CreatureManager.point(east)+Vector3(0,0,3.3))
	manager.tick(0.1)
	check(manager.nodes.has(east.id) and manager.records[east.id].discovered,"streamed shrine discovery")
	game.camera.position = game.base_camera+CreatureManager.point(east)
	await physics_frame
	manager.toggle()
	await process_frame
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(410,85)
	root.push_input(click,true)
	var release := click.duplicate()
	release.pressed = false
	root.push_input(release,true)
	await process_frame
	check(not manager.panel.visible and game.hero.path.is_empty(),"territory UI consumes mouse clicks without moving player")
	click.position = game.camera.unproject_position(manager.nodes[east.id].position+Vector3(0,0.35,2.3))
	root.push_input(click,true)
	check(game.target==manager.nodes[east.id],"secondary shrine hotspot selects the correct live creature")
	release.position = click.position
	root.push_input(release,true)
	game.cancel()
	check(manager.nearest(game.hero.position).id==game.shrine.persistent_id,"neutral shrine grants no Bond source")
	check(not manager.begin_capture(east.id),"capture rejects insufficient resources")
	game.state.inventory.raw_meat = 6
	game.state.inventory.ingot = 2
	check(not manager.begin_capture(east.id),"hostile control blocks a prepared capture")
	var guard: CombatUnit = game.combat.units[0]
	game.hero.position = guard.position+Vector3(0,0,1.7)
	game.combat.select(guard)
	for i in 250:
		game.combat._physics_process(1.0/60)
		await physics_frame
	check(not is_instance_valid(guard) or not game.combat.units.has(guard),"equipped player combat defeats a territorial guard")
	for unit in game.combat.units.duplicate():
		if unit.territory_id==east.id: game.combat.hit_unit(unit,1000)
	game.hero.position = CreatureManager.point(east)+Vector3(0,0,3.3)
	check(manager.begin_capture(east.id),"prepared capture begins after defeating guards")
	manager.tick(5)
	var halfway := SaveStore.snapshot(game)
	check(SaveStore.validate(halfway,game).is_empty(),"save validates during capture")
	manager.restore(halfway.territory)
	check(manager.capturing.is_empty() and manager.records[east.id].capture==5,"capture progress persists without input lock")
	game.frontier.restore(halfway.exploration)
	await settle()
	check(manager.begin_capture(east.id),"capture resumes explicitly after reload")
	manager.tick(10)
	check(manager.records[east.id].owner=="player" and game.state.inventory.ingot==0 and game.state.inventory.raw_meat==0,"completed capture charges once and establishes ownership")
	manager.tick(20)
	check(not manager.begin_capture(east.id) and game.state.inventory.ingot==0,"repeated capture cannot duplicate rewards")
	manager.records[east.id].threat_timer = 0
	manager.advance_territories(0.1)
	manager.advance_territories(61)
	check(manager.records[east.id].owner=="player" and game.combat.hostiles(true).is_empty(),"enemies outside shrine cannot capture through defended terrain on timeout")
	manager.records[east.id].threat_timer = 0
	manager.advance_territories(0.1)
	var captor: CombatUnit = game.combat.hostiles(true)[0]
	captor.position = CreatureManager.point(east)+Vector3(-3.3,0,0)
	manager.advance_territories(5)
	check(manager.records[east.id].enemy_capture==5,"nearby raider channels territorial capture")
	game.combat.hit_unit(captor,1)
	check(manager.records[east.id].enemy_capture==0,"damage interrupts territorial capture")
	captor.hit = 0
	manager.advance_territories(10)
	check(manager.records[east.id].owner=="npc","completed channel captures secondary shrine")
	for unit in game.combat.units.duplicate():
		if unit.territory_id==east.id: game.combat.hit_unit(unit,1000)
	check(manager.begin_capture(east.id),"lost secondary shrine supports free recapture")
	manager.tick(15)
	var home_sat: float = game.state.satisfaction
	game.state.inventory.raw_meat = 1
	game.feed_lock = 0
	check(manager.feed(east.id) and game.state.satisfaction==home_sat,"secondary feeding preserves home Satisfaction")
	game.feed_lock = 0
	manager.records[east.id].satisfaction = 80
	game.state.inventory.ore = 2
	check(manager.service(east.id,"ingot_from_ore") and game.state.inventory.ingot==1 and manager.records[east.id].satisfaction==74 and game.state.satisfaction==home_sat,"desert smelting uses independent discounted Satisfaction")
	game.feed_lock = 0
	for item in game.state.inventory: game.state.inventory[item] = 0
	game.state.inventory.wood = 4
	game.state.inventory.stone = 3
	game.state.inventory.hide = 2
	check(manager.service(east.id,"level_up") and manager.records[east.id].level==2 and game.state.level==1,"secondary level upgrades remain independent")
	game.feed_lock = 0
	for item in game.state.inventory: game.state.inventory[item] = 0
	for item in game.buildings.config.types.palisade.inputs: game.state.inventory[item] = game.buildings.config.types.palisade.inputs[item]
	var built := false
	for i in 24:
		var at := CreatureManager.point(east)+Vector3(sin(i*TAU/24),0,cos(i*TAU/24))*5.8
		if game.buildings.placement_error("palisade",at).is_empty():
			built = game.buildings.place("palisade",at)
			break
	check(built and game.buildings.structures[-1].base_id==east.id,"secondary palisade consumes resources and retains base identity")
	game.state.inventory.stone = 8
	game.state.inventory.ingot = 2
	manager.records[east.id].satisfaction = 80
	game.feed_lock = 0
	check(manager.service(east.id,"stone_golem") and game.combat.defenders()[-1].base_id==east.id,"secondary golem has paid deployment and local defense anchor")
	check(SaveStore.validate(SaveStore.snapshot(game),game).is_empty(),"secondary structures and defenders validate for persistence")
	manager.records[east.id].threat_timer = 0
	manager.advance_territories(0.1)
	check(manager.records[east.id].owner=="contested" and game.combat.hostiles(true).size()==2,"territory warning escalates to a local attack")
	check(SaveStore.validate(SaveStore.snapshot(game),game).is_empty(),"contested territory and guards save safely")
	await move(Vector3(0,0,5))
	manager.advance_territories(61)
	check(manager.records[east.id].owner=="player" and manager.records[east.id].guards.is_empty(),"distant prepared defenses resolve without spawning enemy actors")
	await move(CreatureManager.point(east)+Vector3(0,0,3.3))
	check(game.combat.hostiles(true).is_empty(),"defeated distant attackers do not respawn")
	game.feed_lock = 0
	manager.records[east.id].satisfaction = 80
	game.state.satisfaction = 80
	var bag: Dictionary = game.state.inventory.duplicate()
	check(manager.begin_travel(east.id,game.shrine.persistent_id),"owned network travel begins")
	var pending := SaveStore.snapshot(game)
	check(pending.position[0]>200 and pending.character.satisfaction==80 and not pending.territory.has("travel_pending"),"pending travel saves departure without costs or locks")
	await settle()
	manager.advance_travel(0.1)
	check(game.hero.position.distance_to(game.shrine.position)<8 and game.state.satisfaction==70 and manager.records[east.id].satisfaction==60,"safe travel atomically charges both endpoints")
	check(game.state.inventory==bag and manager.travel_pending.is_empty(),"travel preserves inventory and clears transient state")
	game.feed_lock = 0
	game.hero.position = game.shrine.position+Vector3(0,0,3.3)
	check(manager.begin_travel(game.shrine.persistent_id,east.id),"return travel to distant chunks starts")
	await settle()
	await physics_frame
	manager.advance_travel(0.1)
	check(game.hero.position.x>250 and manager.nearest(game.hero.position).id==east.id,"distant arrival switches eligible Bond reference")
	game.expedition.bond = 10
	game.expedition.tick(1)
	check(game.expedition.bond>10,"owned secondary shrine restores Bond")
	var record_copy: Dictionary = manager.records[east.id].duplicate(true)
	await move(Vector3(0,0,5))
	check(not manager.nodes.has(east.id) and manager.records[east.id]==record_copy,"unloading retains independent shrine state")
	await move(CreatureManager.point(east)+Vector3(0,0,3.3))
	check(manager.nodes.size()==1 and manager.records[east.id]==record_copy,"reloading does not duplicate or reset shrine")
	var snapshot := SaveStore.snapshot(game)
	check(SaveStore.validate(snapshot,game).is_empty(),"W5 snapshot validates near secondary shrine")
	var broken: Dictionary = snapshot.duplicate(true)
	broken.territory.records[east.id].position[0] += 1
	check(not SaveStore.validate(broken,game).is_empty(),"relocated creature ID rejected")
	broken = snapshot.duplicate(true)
	broken.territory.records[east.id].satisfaction = NAN
	check(not SaveStore.validate(broken,game).is_empty(),"nonfinite creature state rejected")
	game.save_path = "user://test_w5_%d.json" % OS.get_process_id()
	game.persistence_enabled = true
	game.save_game()
	manager.records[east.id].satisfaction = 0
	game.paused = true
	game.load_game()
	await settle()
	check(not game.paused and is_equal_approx(manager.records[east.id].satisfaction,snapshot.territory.records[east.id].satisfaction),"load restores independent stats and control")
	game.hero.path = game.navigation.route(game.hero.position,game.hero.position+Vector3(1,0,0))
	var before: Vector3 = game.hero.position
	for i in 60: await physics_frame
	check(game.hero.position.distance_to(before)>0.5,"actual player movement after W5 reload")
	for cycle in 3:
		game.save_game()
		game.load_game()
		await settle()
		check(manager.nodes.size()==1 and game.combat.defenders().size()==1 and game.buildings.structures.size()==1 and game.feed_lock==0,"repeated reload preserves single base, defender and structure without input locks")
	game.persistence_enabled = false
	await move(CreatureManager.point(west)+Vector3(0,0,3.3))
	manager.tick(0.1)
	for item in game.state.inventory: game.state.inventory[item] = 0
	game.state.inventory.raw_meat = 6
	game.state.inventory.ingot = 2
	check(manager.begin_capture(west.id),"neutral frost shrine accepts prepared capture")
	manager.tick(15)
	check(manager.nearest(game.hero.position).id==west.id and manager.bond_capacity(manager.records[west.id])==130,"frost shrine grants its distinct Bond capacity")
	game.expedition.bond = 1
	game.expedition.recall()
	check(game.hero.position.distance_to(CreatureManager.point(west))<6 and game.expedition.bond==32.5,"emergency recall chooses nearest owned frost shrine")
	manager.records[west.id].threat_timer = 0
	manager.advance_territories(0.1)
	await move(Vector3(0,0,5))
	manager.advance_territories(61)
	check(manager.records[west.id].owner=="npc" and not manager.records[west.id].activated,"undefended distant base can be lost without deleting progress")
	check(SaveStore.validate(SaveStore.snapshot(game),game).is_empty(),"lost territory remains a valid recoverable save")
	await move(CreatureManager.point(west)+Vector3(0,0,3.3))
	for unit in game.combat.units.duplicate():
		if unit.territory_id==west.id: game.combat.hit_unit(unit,1000)
	for item in game.state.inventory: game.state.inventory[item] = 0
	var sat_before: float = manager.records[west.id].satisfaction
	check(manager.begin_capture(west.id),"recapture requires no resources after guards are defeated")
	manager.tick(15)
	check(manager.records[west.id].owner=="player" and manager.records[west.id].satisfaction==sat_before,"recapture restores ownership without generating free Satisfaction")
	game.feed_lock = 0
	manager.records[west.id].satisfaction = 80
	game.state.satisfaction = 80
	check(manager.begin_travel(west.id,game.shrine.persistent_id),"travel can start after recapture")
	manager.close()
	check(manager.travel_pending.is_empty() and manager.records[west.id].satisfaction==80 and game.state.satisfaction==80,"cancelling pending travel charges neither endpoint")
	if "--visual" in OS.get_cmdline_user_args():
		await move(CreatureManager.point(east)+Vector3(0,0,3.3))
		game.expedition.bond = 100
		game.set_process(true)
		manager.inspect(east.id)
		for i in 90: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://captures/w5-desert.png")
		game.set_process(false)
		await move(CreatureManager.point(west)+Vector3(0,0,3.3))
		manager.tick(0.1)
		manager.inspect(west.id)
		game.expedition.bond = 100
		game.set_process(true)
		for i in 90: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://captures/w5-frost.png")
	print("MAX W5 STREAM JOB ms: ",game.frontier.max_job_ms)
	game.queue_free()
	await process_frame
	print("W5 CHECKS ",checks," FAILURES ",failures)
	quit(1 if failures else 0)