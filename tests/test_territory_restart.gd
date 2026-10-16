extends SceneTree
func _initialize() -> void: call_deferred("run")
func settle(game: Node) -> void:
	for i in 1600:
		await process_frame
		if game.frontier.initialized and game.frontier.jobs.is_empty(): return
func run() -> void:
	var writing := "--write" in OS.get_cmdline_user_args()
	var game: Node = load("res://scenes/main.tscn").instantiate()
	game.save_path = "user://w5_cross_process_test.json"
	game.persistence_enabled = not writing
	root.add_child(game)
	game.set_process(false)
	game.combat.set_physics_process(false)
	await settle(game)
	var valid := true
	var id := "shrine:4:0"
	if writing:
		game.hero.position = Vector3(262,0,9.3)
		game.frontier.update_chunks()
		await settle(game)
		for unit in game.combat.units.duplicate():
			if unit.territory_id==id: game.combat.remove_unit(unit)
		game.creatures.records[id].merge({"owner":"player","ever_owned":true,"discovered":true,"activated":true,"satisfaction":80.0,"level":2,"guards":[]},true)
		game.state.inventory.stone = 8
		game.state.inventory.ingot = 2
		valid = game.creatures.service(id,"stone_golem")
		game.feed_lock = 0
		game.state.inventory.wood = 4
		for i in 24:
			var at := Vector3(262,0,6)+Vector3(sin(i*TAU/24),0,cos(i*TAU/24))*5.8
			if game.buildings.placement_error("palisade",at).is_empty():
				valid = game.buildings.place("palisade",at) and valid
				break
		game.creatures.records[id].threat_timer = 0
		game.creatures.advance_territories(0.1)
		game.creatures.records[id].threat_timer = 40
		game.expedition.bond = 83
		game.frontier.explored["65:2"] = true
		game.persistence_enabled = true
		game.save_game()
		valid = valid and SaveStore.read(game.save_path,game).error.is_empty()
	else:
		valid = game.hud.notice.text=="Game loaded." and game.creatures.records.has(id)
		if valid:
			var record: Dictionary = game.creatures.records[id]
			valid = record.owner=="contested" and record.threat_timer==40 and record.level==2 and record.satisfaction==64
			valid = valid and game.buildings.structures.size()==1 and game.buildings.structures[0].base_id==id
			valid = valid and game.combat.defenders().size()==1 and game.combat.defenders()[0].base_id==id
			valid = valid and game.combat.hostiles(true).size()==2 and game.combat.hostiles().is_empty()
			valid = valid and game.expedition.bond==83 and game.frontier.explored.has("65:2") and game.creatures.capturing.is_empty() and game.creatures.travel_pending.is_empty()
			var start: Vector3 = game.hero.position
			game.hero.path = game.navigation.route(start,start+Vector3(1,0,0))
			for i in 60: await physics_frame
			valid = valid and game.hero.position.distance_to(start)>0.5
	game.persistence_enabled = false
	game.queue_free()
	await process_frame
	print("TERRITORY CROSS-PROCESS ","WRITE " if writing else "READ ","PASS" if valid else "FAIL")
	quit(0 if valid else 1)