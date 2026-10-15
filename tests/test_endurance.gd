extends SceneTree

var failures := 0
var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	else: print("PASS: ",message)

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	game.persistence_enabled = false
	game.save_path = "user://endurance_%d.json" % OS.get_process_id()
	root.add_child(game)
	await physics_frame
	game.hero.position = Vector3(3.25,0,0)
	game.state.inventory.wood = 4
	check(game.buildings.place("palisade",Vector3(4.55,0,-3.25)),"endurance palisade placement")
	game.hero.position = Vector3(-3.25,0,0)
	game.state.inventory.wood = 8
	game.state.inventory.hide = 2
	check(game.buildings.place("totem",Vector3(-4.55,0,-3.25)),"endurance active totem placement")
	game.state.level = 5
	game.state.equipment.spear = true
	game.state.equipment.hide_armor = true
	game.state.equipment.reinforced_armor = true
	for at in [Vector3(-3.9,0,0),Vector3(3.9,0,0),Vector3(0,0,1.3)]: game.combat.add_unit("golem",at)
	game.combat.wave = 8
	game.combat.start_raid()
	game.persistence_enabled = true
	for cycle in 12:
		game.cancel()
		game.hero.position = Vector3(0,0,10)
		game.save_game(false)
		var saved: Dictionary = SaveStore.read(game.save_path,game)
		check(saved.error.is_empty(),"active battle snapshot validates cycle %d: %s" % [cycle,saved.error])
		game.load_game()
		var start: Vector3 = game.hero.position
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.position = game.camera.unproject_position(Vector3(0,0,5))
		root.push_input(click,true)
		click = click.duplicate()
		click.pressed = false
		root.push_input(click,true)
		for i in 90: await physics_frame
		check(game.hero.position.distance_to(start) > 1 and not game.paused,"mouse movement after battle reload cycle %d" % cycle)
		var error := SaveStore.validate(SaveStore.snapshot(game),game)
		check(error.is_empty(),"live battle state valid cycle %d: %s" % [cycle,error])
	game.persistence_enabled = false
	game.queue_free()
	await process_frame
	print("ENDURANCE: ",checks," checks; failures: ",failures)
	quit(failures)
