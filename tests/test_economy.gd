extends SceneTree

var failures := 0
var checks := 0
var game: Node

func check(condition: bool, label: String) -> void:
	checks += 1
	if condition: print("PASS: ",label)
	else:
		failures += 1
		push_error(label)

func stock(state: GameState, id: String) -> void:
	for item in state.inventory: state.inventory[item] = 0
	for item in state.specification(id).inputs: state.inventory[item] = state.specification(id).inputs[item]
	state.satisfaction = state.cap()

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var state := GameState.new()
	var before := state.serialize()
	check(not state.try_service("unknown").ok and before == state.serialize(),"unknown services leave state unchanged")
	check(not state.try_service("primitive_axe").ok and before == state.serialize(),"missing resources leave entire state unchanged")
	stock(state,"primitive_axe")
	state.satisfaction = 11
	before = state.serialize()
	check(not state.try_service("primitive_axe").ok and before == state.serialize(),"insufficient Satisfaction preserves resources")
	state.satisfaction = 12
	check(state.try_service("primitive_axe").ok and state.satisfaction == 0 and state.inventory.wood == 0 and state.action_duration("pine") == 0.55,"exact-cost craft commits equipment and improves chopping")
	before = state.serialize()
	check(not state.try_service("primitive_axe").ok and before == state.serialize(),"unique equipment cannot be purchased twice")
	stock(state,"ingot_from_ore")
	state.satisfaction = 0
	before = state.serialize()
	check(not state.try_service("ingot_from_ore").ok and before == state.serialize(),"dormant shrine rejects services")
	state.inventory.raw_meat = 1
	check(state.feed() and state.satisfaction == 4,"feeding remains possible during dormancy")
	stock(state,"ingot_from_ore")
	state.satisfaction = 10
	check(state.try_service("ingot_from_ore").ok and state.inventory.ore == 0 and state.inventory.ingot == 1 and state.satisfaction == 0,"smelting consumes exactly two ore and ten Satisfaction")
	stock(state,"spear")
	before = state.serialize()
	check(not state.try_service("spear").ok and before == state.serialize(),"equipment enforces shrine level")
	stock(state,"reinforced_backpack")
	check(state.try_service("reinforced_backpack").ok and state.capacity() == 40 and state.slot_limit() == 16,"backpack expands weight and slots")
	stock(state,"heal")
	state.health = 90
	check(state.try_service("heal").ok and state.health == 100,"healing clamps to maximum health")
	before = state.serialize()
	check(not state.try_service("heal").ok and before == state.serialize(),"full-health healing charges nothing")
	for level in range(2,6):
		stock(state,"level_up")
		check(state.try_service("level_up").ok and state.level == level and state.cap() == state.balance.temptress.max_satisfaction_per_level[level-1],"level %d increases Satisfaction cap" % level)
		for id in state.balance.progression.w2_recipes:
			var spec := state.specification(id)
			if spec.required_level != level: continue
			stock(state,id)
			check(state.try_service(id).ok,"level %d recipe %s usable" % [level,id])
	check(state.max_health() == 140 and state.action_duration("pine") == 0.35 and state.action_duration("ore") == 0.5 and state.hunting_reach_bonus() == 0.65,"all equipment benefits apply")
	before = state.serialize()
	check(not state.try_service("level_up").ok and before == state.serialize(),"maximum level cannot consume resources")
	check(is_equal_approx(state.drain(),0.025*1.75) and state.bond_cap() == 220,"level five appetite and Bond scale correctly")
	check(state.validate_data(state.serialize()).is_empty(),"complete progression serializes validly")
	# Force capacity/stack constraints independently; all production recipes reduce bag weight.
	var small := GameState.new()
	stock(small,"ingot_from_ore")
	small.balance.player.base_weight_capacity = 0
	before = small.serialize()
	check(not small.try_service("ingot_from_ore").ok and before == small.serialize(),"output capacity rejection is atomic")
	small.balance.player.base_weight_capacity = 30
	small.balance.player.default_inventory_slots = 0
	check(not small.try_service("ingot_from_ore").ok and before == small.serialize(),"output slot rejection is atomic")
	check(not state.collect({"wood":0.5}) and not state.collect({"unknown":1}),"invalid resource grants rejected")
	game = load("res://scenes/main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	await physics_frame
	stock(game.state,"primitive_axe")
	before = game.state.serialize()
	game.service("primitive_axe")
	check(before == game.state.serialize(),"remote services rejected")
	game.hero.position = Vector3(0,0,1.5)
	game.service("primitive_axe")
	before = game.state.serialize()
	game.service("heal")
	check(before == game.state.serialize() and game.feed_lock > 0,"rapid service clicks blocked")
	game.feed_lock = 0
	game.service("heal")
	check(game.state.health == 100 and game.ritual != null,"healing starts actual scene animation")
	game.feed_lock = 0
	stock(game.state,"ingot_from_ore")
	game.hud.services.select(0)
	game.hud.busy = false
	game.hud.refresh()
	game.hud.service_button.pressed.emit()
	check(game.state.inventory.ingot == 1 and game.state.inventory.ore == 0,"service button performs selected smelting transaction")
	game.paused = true
	game.feed_lock = 0
	stock(game.state,"ingot_from_ore")
	before = game.state.serialize()
	game.hud.service_button.pressed.emit()
	check(before == game.state.serialize(),"paused scene rejects service callbacks")
	game.paused = false
	game.state.restore(state.serialize())
	game.update_equipment()
	var hare: Interactable = game.targets[-1]
	for item in game.state.inventory: game.state.inventory[item] = 0
	hare.harvest(game.state)
	game.save_path = "user://w2_test_save_%d.json" % OS.get_process_id()
	game.persistence_enabled = true
	game.save_game()
	var saved := SaveStore.read(game.save_path,game)
	check(saved.error.is_empty(),"atomic save writes and validates")
	game.state.inventory.raw_meat = 0
	hare.remaining = 0.01
	game.load_game()
	check(game.state.level == 5 and game.state.equipment.size() == 7 and game.state.inventory.raw_meat == 1 and hare.depleted and hare.remaining > 30,"load restores gear inventory progression and depleted nodes")
	check(hare.harvest(game.state).is_empty(),"reloaded prey cannot duplicate loot")
	var bad: Dictionary = saved.data.duplicate(true)
	bad.world[1] = bad.world[0]
	check(not SaveStore.validate(bad,game).is_empty(),"duplicate world IDs rejected")
	bad = saved.data.duplicate(true)
	bad.character.inventory.wood = -1
	check(not SaveStore.validate(bad,game).is_empty(),"negative save counts rejected")
	for invalid in [null,[],{}, {"version":1}, {"version":1,"seed":game.state.balance.world.seed,"character":[]}]:
		check(not SaveStore.validate(invalid,game).is_empty(),"malformed save shape rejected")
	bad = saved.data.duplicate(true)
	bad.version = 99
	check(not SaveStore.validate(bad,game).is_empty(),"unsupported schema rejected")
	bad = saved.data.duplicate(true)
	bad.position = [0,0,-2]
	check(not SaveStore.validate(bad,game).is_empty(),"obstructed player saves rejected")
	var file := FileAccess.open(game.save_path,FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	before = game.state.serialize()
	game.load_game()
	game.save_game(false)
	check(before == game.state.serialize() and FileAccess.get_file_as_string(game.save_path) == "{broken","malformed load preserves live state and blocks automatic overwrite")
	game.save_game()
	check(SaveStore.read(game.save_path,game).error.is_empty(),"explicit save recovers from corrupt slot")
	check(not SaveStore.write("user://missing_directory/save.json",game).is_empty(),"write failure reports error")
	game.hud.menu.show()
	game.hud.inventory_panel.show()
	for i in 3: await process_frame
	print("PANEL SIZES: ",game.hud.menu.size," / ",game.hud.inventory_panel.size)
	if "--visual" in OS.get_cmdline_user_args():
		game.persistence_enabled = false
		game.select_target(game.shrine)
		game.hud.inventory_panel.show()
		game.hud.services.select(7)
		game.hud.refresh()
		for i in 90: await physics_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://captures/w2-services.png")
	check(game.hud.menu.position.y+game.hud.menu.size.y < 624 and game.hud.inventory_panel.position.y+game.hud.inventory_panel.size.y < 624,"service and inventory panels fit above controls")
	DirAccess.remove_absolute(game.save_path)
	game.persistence_enabled = false
	game.queue_free()
	await process_frame
	print("ECONOMY: ",checks," checks; failures: ",failures)
	quit(failures)
