extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	game.combat.set_physics_process(false)
	game.combat.refresh()
	for biome in ["desert","snow"]:
		game.hero.position = Vector3(134 if biome=="desert" else -122,0,12)
		for i in 900:
			await process_frame
			if game.frontier.initialized and game.frontier.jobs.is_empty(): break
		game.state.health = 75
		game.expedition.bond = game.state.bond_cap()
		game.hud.notice.text = ""
		game.hud.hint.text = "Click to move or gather. M opens the map."
		for i in 90: await physics_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://captures/w4-"+biome+".png")
		print("CAPTURE ",biome," / active chunks ",game.frontier.chunks.size()," / stream max ms ",game.frontier.max_job_ms)
	game.queue_free()
	await process_frame
	quit()
