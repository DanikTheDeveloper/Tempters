extends SceneTree
var game: Node
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in 1600:
		await process_frame
		if game.frontier.initialized and game.frontier.jobs.is_empty(): return
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	game.set_process(false)
	game.combat.set_physics_process(false)
	await settle()
	game.state.satisfaction = 80
	for cell in [Vector2i(4,0),Vector2i(-4,0)]:
		var site: Dictionary = game.frontier.layout.creature_site(cell)
		game.cancel()
		game.hero.position = CreatureManager.point(site)+Vector3(0,0,3.3)
		game.frontier.update_chunks()
		await settle()
		for unit in game.combat.units.duplicate():
			if not unit.territory_id.is_empty(): game.combat.remove_unit(unit)
		game.creatures.records[site.id].merge({"owner":"player","discovered":true,"activated":true,"ever_owned":true,"satisfaction":80.0,"guards":[]},true)
		game.expedition.bond = 100
		game.set_process(true)
		game.creatures.inspect(site.id)
		for i in 100: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://captures/w5-%s.png" % ("desert" if cell.x>0 else "frost"))
		print("W5 rendered ",site.biome," maximum stream job ms ",game.frontier.max_job_ms," FPS ",Engine.get_frames_per_second())
		game.set_process(false)
	game.queue_free()
	await process_frame
	quit()