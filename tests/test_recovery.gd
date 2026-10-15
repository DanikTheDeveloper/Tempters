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

func _initialize() -> void: call_deferred("run")

func move_after_load(label: String) -> void:
	check(not game.paused and Engine.time_scale == 1 and game.feed_lock == 0 and game.hero.is_physics_processing() and not game.hero.working and game.hero.path.is_empty() and game.target == null and game.buildings.placing.is_empty() and not game.hud.menu.visible and not game.hud.inventory_panel.visible,label+": transient state cleared")
	await physics_frame
	var start: Vector3 = game.hero.position
	var at := Vector3(-2 if start.x >= 0 else 2,0,3)
	var event := InputEventMouseButton.new()
	event.pressed = true
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = game.camera.unproject_position(at)
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
	for i in 120:
		await physics_frame
		if game.hero.position.distance_to(start) > 1.0: break
	check(game.hero.position.distance_to(start) > 1.0,label+": actual mouse movement works")
	game.cancel()

func write_raw(data: Variant) -> void:
	var file := FileAccess.open(game.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await physics_frame
	game.save_path = "user://recovery_regression_%d.json" % OS.get_process_id()
	game.persistence_enabled = true
	# Exact spatial arrangement from the backed-up player save. Old collision
	# layers blocked the first rounded grid point for every destination.
	game.hero.position = Vector3(2.51769971847534,0,7.52768468856812)
	var hare: Interactable
	for node in game.targets:
		if node.persistent_id == "hare_3": hare = node
	hare.position = Vector3(2.72031474113464,0,8.19784736633301)
	game.save_game()
	game.load_game()
	await move_after_load("original prey pinning reproduction")
	check(hare.collision_layer == 8,"prey remains pickable without blocking character physics")
	hare.depleted = true
	hare.remaining = 0.001
	await create_timer(0.05).timeout
	check(hare.collision_layer == 8 and not hare.depleted,"respawn retains nonblocking prey collision")
	game.hero.path = game.navigation.route(game.hero.position,Vector3(3,0,4))
	game.save_game()
	game.load_game()
	await move_after_load("saved while moving")
	game.buildings.toggle()
	game.buildings.begin_placement()
	game.save_game()
	game.load_game()
	await move_after_load("saved during placement")
	game.hud.inventory_panel.show()
	game.hud.menu.show()
	game.save_game()
	game.load_game()
	await move_after_load("saved with interfaces open")
	game.paused = true
	Engine.time_scale = 0.25
	game.hero.set_physics_process(false)
	for node in game.targets: node.set_process(false)
	game.save_game()
	game.load_game()
	await move_after_load("saved while paused")
	game.hero.position = Vector3(0,0,1.5)
	game.state.health = 50
	game.state.satisfaction = 65
	game.service("heal")
	game.save_game()
	game.load_game()
	await move_after_load("interrupted healing interaction")
	check(game.hero.model.root.scale.is_equal_approx(Vector3.ONE*1.15),"load resets interrupted visual ritual")
	game.hero.path = PackedVector3Array([game.shrine.position])
	game.hero.working = true
	game.target = game.shrine
	game.save_game()
	game.load_game()
	await move_after_load("unreachable transient request")
	game.hero.position = Vector3(3.25,0,0)
	game.state.inventory.wood = 12
	game.state.inventory.hide = 2
	check(game.buildings.place("palisade",Vector3(4.55,0,-3.25)),"recovery fixture includes actual palisade")
	game.hero.position = Vector3(-3.25,0,0)
	check(game.buildings.place("totem",Vector3(-4.55,0,-3.25)),"recovery fixture includes active totem")
	game.hero.position = Vector3(4.55,0,-2.1)
	game.save_game()
	game.load_game()
	await move_after_load("saved next to a constructed obstacle")
	check(game.buildings.structures.size() == 2 and game.buildings.production() > 0,"load preserves active structures and production")
	for cycle in 12:
		game.save_game(false)
		game.load_game()
		await move_after_load("autosave/reload cycle %d" % cycle)
	var saved := SaveStore.snapshot(game)
	var resources: Dictionary = game.state.inventory.duplicate()
	var old := saved.duplicate(true)
	old.version = 1
	old.erase("buildings")
	write_raw(old)
	game.load_game()
	await move_after_load("pre-W3 migration")
	check(game.state.inventory == resources,"W2 migration preserves resources")
	write_raw(saved)
	game.load_game()
	game.save_game()
	check(FileAccess.file_exists(game.save_path+".previous"),"previous valid snapshot retained")
	var invalid := saved.duplicate(true)
	invalid.position = [0,0,-2]
	write_raw(invalid)
	game.load_game()
	check(game.hero.position == Vector3(0,0,5) and game.buildings.structures.size() == 2 and game.state.inventory == resources,"invalid spawn repairs only player position")
	check(game.autosave_blocked and JSON.parse_string(FileAccess.get_file_as_string(game.save_path)).position == [0.0,0.0,-2.0],"repair preserves original slot pending explicit save")
	await move_after_load("repaired obstructed spawn")
	game.save_game()
	var file := FileAccess.open(game.save_path,FileAccess.WRITE)
	file.store_string("{truncated")
	file.close()
	game.load_game()
	check(game.autosave_blocked and FileAccess.get_file_as_string(game.save_path) == "{truncated","corrupt slot remains untouched after fallback")
	await move_after_load("previous valid snapshot fallback")
	game.save_game()
	invalid = SaveStore.snapshot(game)
	invalid.buildings.structures[0].erase("health")
	write_raw(invalid)
	game.load_game()
	await move_after_load("incomplete structure snapshot fallback")
	game.load_game(true)
	await move_after_load("explicit previous-snapshot recovery")
	if "--visual" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://captures/recovery-regression.png")
	game.persistence_enabled = false
	game.queue_free()
	await process_frame
	print("RECOVERY: ",checks," checks; failures: ",failures)
	quit(failures)
