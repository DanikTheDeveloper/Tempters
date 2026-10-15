extends SceneTree
## Exercises the actual main scene, physics, moving targets and UI input dispatch.
var game: Node3D
var failures := 0
var collision_free := true

func check(value: bool, description: String) -> void:
	if not value:
		push_error(description)
		failures += 1
	else: print("PASS: "+description)

func frames(count: int) -> void:
	for i in count: await physics_frame

func click_world(at: Vector3) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = game.camera.unproject_position(at)
	root.push_input(event, true)
	await frames(2)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)

func wait_action(limit := 600) -> void:
	for i in limit:
		await physics_frame
		for obstacle in game.targets:
			if obstacle.kind != "hare" and game.hero.position.distance_to(obstacle.position) < obstacle.radius+0.23:
				collision_free = false
		if game.target == null and game.hero.path.is_empty(): return

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await frames(3)
	await click_world(Vector3(2,0,5))
	await wait_action()
	check(game.hero.position.distance_to(Vector3(2,0,5)) < 0.6,"raycast ground click moves CharacterBody3D")
	var start: Vector3 = game.hero.position
	var event := InputEventMouseButton.new()
	event.position = Vector2(150,60)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event, true)
	await frames(4)
	check(game.hero.path.is_empty() and game.hero.position.distance_to(start) < 0.05,"HUD consumes world movement click")
	var hare: Interactable
	var pine: Interactable
	var ore: Interactable
	for item in game.targets:
		if item.kind == "hare": hare = item
		if item.kind == "pine": pine = item
		if item.kind == "ore": ore = item
	var canopy_hit: Dictionary = game.pick(game.camera.unproject_position(pine.position+Vector3(0,3.0,0)))
	check(canopy_hit.get("collider") == pine,"tree canopy ray resolves to harvestable owner")
	game.select_target(hare)
	await wait_action()
	check(game.state.inventory.raw_meat == 1 and game.state.inventory.hide == 1,"moving hare approach and hunt grants exact drop")
	check(hare.harvest(game.state).is_empty(),"depleted hare cannot grant duplicate loot")
	game.select_target(game.shrine)
	for i in 600:
		await physics_frame
		if game.hud.menu.visible: break
	check(game.hud.menu.visible,"shrine approach opens feeding menu")
	game.state.satisfaction = 0
	game.offer()
	game.offer()
	check(game.state.inventory.raw_meat == 0 and game.state.satisfaction == 4,"in-world dormant feeding and duplicate-click throttle")
	if "--visual" in OS.get_cmdline_user_args():
		await frames(12)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://captures/feeding.png")
		print("CAPTURE: captures/feeding.png")
	game.cancel()
	game.select_target(pine)
	game.cancel()
	game.select_target(ore)
	await wait_action()
	check(game.state.inventory.ore == 2 and game.state.inventory.wood == 0,"rapid target switch harvests only final target")
	game.select_target(pine)
	await wait_action()
	check(game.state.inventory.wood >= 2,"distant tree reached around intervening obstacles")
	check(collision_free,"observed locomotion never overlaps static blockers")
	var stone: Interactable
	for item in game.targets:
		if item.kind == "stone": stone = item
	game.state.inventory.ore = 10
	var before: Dictionary = game.state.inventory.duplicate()
	check(stone.harvest(game.state).get("full",false) and not stone.depleted and game.state.inventory == before,"full bag leaves resource node and inventory unchanged")
	hare.remaining = 0.01
	await create_timer(0.15).timeout
	await process_frame
	check(not hare.depleted and hare.art.visible,"prey renewal prevents food exhaustion")
	game.cancel()
	game.queue_free()
	await frames(3)
	print("SCENE TEST FAILURES: ",failures)
	quit(failures)



