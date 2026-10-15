extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var fixture := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fixture="): fixture = arg.trim_prefix("--fixture=")
	if fixture.is_empty():
		push_error("Pass --fixture=<backed-up save path>")
		quit(1)
		return
	var test_path := "user://diagnostic_copy_%d.json" % OS.get_process_id()
	var file := FileAccess.open(test_path,FileAccess.WRITE)
	file.store_string(FileAccess.get_file_as_string(fixture))
	file.close()
	print("DIAG scene start ",Time.get_ticks_msec())
	var game: Node = load("res://scenes/main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	print("DIAG scene ready ",Time.get_ticks_msec())
	game.save_path = test_path
	game.persistence_enabled = true
	print("DIAG load start ",Time.get_ticks_msec())
	game.load_game()
	print("DIAG load returned ",Time.get_ticks_msec()," ",game.hud.notice.text)
	game.persistence_enabled = false
	for i in 3: await physics_frame
	print("DIAG physics alive ",Time.get_ticks_msec()," pause=",game.paused," scale=",Engine.time_scale," lock=",game.feed_lock," working=",game.hero.working," process=",game.hero.is_physics_processing()," position=",game.hero.position)
	var before: Vector3 = game.hero.position
	var at := Vector3(0,0,3)
	var event := InputEventMouseButton.new()
	event.position = game.camera.unproject_position(at)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	print("DIAG dispatch click ",event.position," at ",Time.get_ticks_msec())
	root.push_input(event,true)
	print("DIAG dispatch returned path=",game.hero.path," ",Time.get_ticks_msec())
	for i in 180:
		await physics_frame
		if i % 30 == 0:
			print("DIAG heartbeat ",i," position=",game.hero.position," path=",game.hero.path.size()," ",Time.get_ticks_msec())
			if game.hero.get_slide_collision_count() > 0:
				var collider: Object = game.hero.get_slide_collision(0).get_collider()
				print("DIAG blocked by ",collider.get("kind")," at ",collider.get("position"))
	if "--visual" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://captures/save-diagnostic.png")
	var moved: bool = before.distance_to(game.hero.position) > 1
	print("DIAG moved=",moved)
	game.queue_free()
	await process_frame
	quit(0 if moved else 1)
