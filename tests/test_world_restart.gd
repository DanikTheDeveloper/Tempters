extends SceneTree
func _initialize() -> void: call_deferred("run")
func settle(game: Node) -> void:
	for i in 900:
		await process_frame
		if game.frontier.initialized and game.frontier.jobs.is_empty(): return
func run() -> void:
	var writing := "--write" in OS.get_cmdline_user_args()
	var game: Node = load("res://scenes/main.tscn").instantiate()
	game.save_path = "user://w4_cross_process_test.json"
	game.persistence_enabled = not writing
	root.add_child(game)
	game.combat.set_physics_process(false)
	await settle(game)
	var valid := true
	if writing:
		game.state.level = 2
		game.state.inventory.wood = 4
		game.hero.position = Vector3(3.25,0,0)
		valid = game.buildings.place("palisade",Vector3(4.55,0,-3.25))
		game.combat.add_unit("golem",Vector3(-3.9,0,1.3)).health = 99
		game.combat.start_raid()
		game.hero.position = Vector3(70,0,6)
		game.frontier.update_chunks()
		await settle(game)
		for node in game.frontier.resources:
			if node.kind=="ore" and WorldLayout.chunk(node.home)==Vector2i(1,0):
				node.harvest(game.state)
				break
		game.frontier.explored["17:1"] = true
		game.frontier.landmarks["1:0"] = true
		game.expedition.bond = 17
		game.persistence_enabled = true
		game.save_game()
		valid = valid and SaveStore.read(game.save_path,game).error.is_empty()
	else:
		valid = game.hero.position.distance_to(Vector3(70,0,6))<0.5 and game.expedition.bond>10 and game.expedition.bond<=17
		valid = valid and game.buildings.structures.size()==1 and game.combat.defenders().size()==1 and game.combat.defenders()[0].health==99
		valid = valid and game.combat.phase=="raid" and game.combat.hostiles().size()==2 and game.state.inventory.ore>=2
		valid = valid and game.frontier.explored.has("17:1") and game.frontier.landmarks.has("1:0") and game.frontier.changes.size()==1
		var start: Vector3 = game.hero.position
		game.hero.path = game.navigation.route(start,Vector3(75,0,6))
		for i in 60: await physics_frame
		valid = valid and game.hero.position.distance_to(start)>1
	game.persistence_enabled = false
	game.queue_free()
	await process_frame
	print("WORLD CROSS-PROCESS: ","PASS" if valid else "FAIL")
	quit(0 if valid else 1)
