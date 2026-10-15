extends SceneTree

var game: Node
var buildings: BuildingSystem
var failures := 0
var checks := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if ok: print("PASS: ",description)
	else:
		failures += 1
		push_error(description)

func stock(kind: String) -> void:
	for item in game.state.inventory: game.state.inventory[item] = 0
	for item in buildings.config.types[kind].inputs: game.state.inventory[item] = buildings.config.types[kind].inputs[item]

func frames(count := 3) -> void:
	for i in count: await physics_frame

func _initialize() -> void: call_deferred("run")

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await frames()
	buildings = game.buildings
	game.set_process(false)
	game.hero.set_physics_process(false)
	game.hero.position = Vector3(3.25,0,0)
	var fence_at := Vector3(4.55,0,-3.25)
	check(buildings.placement_error("palisade",fence_at).is_empty(),"valid placement preserves shrine and resource routes")
	var before: Dictionary = game.state.serialize()
	check(not buildings.place("palisade",fence_at) and game.state.serialize() == before and buildings.structures.is_empty(),"missing building resources are atomic")
	stock("palisade")
	before = game.state.serialize()
	check(not buildings.place("palisade",game.shrine.position) and game.state.serialize() == before,"shrine overlap rejected without payment")
	check(not buildings.place("palisade",Vector3(0,0,8)) and game.state.serialize() == before,"approach lane cannot be blocked")
	check(not buildings.place("palisade",game.hero.position) and game.state.serialize() == before,"player overlap rejected")
	check(not buildings.place("palisade",Vector3(NAN,0,0)) and game.state.serialize() == before,"nonfinite placement rejected")
	game.paused = true
	check(not buildings.place("palisade",fence_at) and game.state.serialize() == before,"paused building rejected")
	game.paused = false
	check(buildings.place("palisade",fence_at) and game.state.inventory.wood == 0,"placing consumes exact materials")
	if buildings.structures.is_empty():
		quit(1)
		return
	var fence := buildings.structures[0]
	check(game.navigation.grid.is_point_solid(game.navigation.cell(fence_at)),"palisade changes navigation")
	await frames()
	check(game.pick(game.camera.unproject_position(fence_at+Vector3.UP*0.7)).get("collider") == fence,"palisade is mouse-selectable")
	game.hero.path = game.navigation.route(game.hero.position,Vector3(4.55,0,-5.85))
	var destination: Vector3 = game.hero.path[-1]
	var clear := true
	game.hero.set_physics_process(true)
	for i in 240:
		await physics_frame
		if game.hero.position.distance_to(fence_at) < fence.radius+0.23: clear = false
		if game.hero.path.is_empty(): break
	check(clear and game.hero.position.distance_to(destination) < 0.2,"actual player movement detours around a constructed barrier")
	game.hero.set_physics_process(false)
	game.hero.position = Vector3(3.25,0,0)
	stock("palisade")
	before = game.state.serialize()
	check(not buildings.place("palisade",fence_at) and game.state.serialize() == before,"overlap and repeated placement do not charge")
	buildings.inspect(fence)
	check(not buildings.interact("repair"),"remote repair rejected")
	game.hero.position = fence_at+Vector3(0,0,2)
	game.hero.path.clear()
	buildings.damage(fence,40)
	check(fence.health == 60 and fence.art.rotation.z > 0,"damage updates durability and visible lean")
	game.state.inventory.wood = 2
	game.state.inventory.stone = 1
	check(buildings.interact("repair") and fence.health == 100 and game.state.inventory.wood == 0,"repair consumes resources and caps durability")
	before = game.state.serialize()
	check(not buildings.interact("repair") and game.state.serialize() == before,"full durability repair charges nothing")
	game.state.inventory.wood = 2
	game.state.inventory.ingot = 1
	before = game.state.serialize()
	check(not buildings.interact("upgrade") and game.state.serialize() == before,"reinforcement enforces shrine level")
	game.state.level = 2
	check(buildings.interact("upgrade") and fence.tier == 2 and fence.maximum_health() == 150 and fence.health == 100,"reinforcement adds durability capacity without free repair")
	before = game.state.serialize()
	check(not buildings.interact("upgrade") and game.state.serialize() == before,"duplicate reinforcement rejected")
	game.hero.position = Vector3(-3.25,0,0)
	stock("totem")
	check(buildings.place("totem",Vector3(-4.55,0,-3.25)),"totem can be constructed with real resources")
	if buildings.structures.size() < 2:
		quit(1)
		return
	var totem := buildings.structures[1]
	check(is_equal_approx(buildings.production(),0.015),"inner totem produces configured Satisfaction")
	game.state.satisfaction = 0
	buildings.advance(100)
	check(is_equal_approx(game.state.satisfaction,1.5) and is_equal_approx(totem.fuel,200),"totem production consumes maintenance time")
	game.paused = true
	buildings.advance(100)
	check(is_equal_approx(totem.fuel,200),"pause freezes maintenance and production")
	game.paused = false
	buildings.advance(1000)
	check(is_equal_approx(game.state.satisfaction,4.5) and totem.fuel == 0 and buildings.production() == 0,"fuel expiry prevents unbounded passive generation")
	game.hero.position = totem.position+Vector3(0,0,2)
	buildings.inspect(totem)
	game.hero.path.clear()
	game.state.inventory.wood = 1
	game.state.inventory.hide = 1
	check(buildings.interact("refuel") and totem.fuel == 300 and game.state.inventory.hide == 0,"maintenance consumes resources and restores operating time")
	before = game.state.serialize()
	check(not buildings.interact("refuel") and before == game.state.serialize(),"full fuel cannot consume upkeep twice")
	game.hero.position = Vector3(0,0,-9.1)
	stock("totem")
	check(buildings.place("totem",Vector3(0,0,-7.15)),"second totem placed")
	check(is_equal_approx(buildings.production(),0.024),"second totem returns sixty percent")
	buildings.config.max_totems = 2
	check(buildings.placement_error("totem",Vector3(-3.25,0,-8.45)) == "Totem limit reached.","totem count limit enforced")
	buildings.config.max_totems = 5
	buildings.config.max_structures = 3
	check(buildings.placement_error("palisade",fence_at) == "Structure limit reached.","structure count limit enforced")
	buildings.config.max_structures = 24
	buildings.config.totem_output_cap = 0.02
	check(is_equal_approx(buildings.production(),0.02),"combined totem production cap enforced")
	buildings.config.totem_output_cap = 0.045
	var first_position := totem.position
	totem.position = Vector3(-3.25,0,-8.45)
	check(is_equal_approx(buildings.production(),0.0204),"outer totem has reduced efficiency before diminishing returns")
	totem.tier = 2
	check(is_equal_approx(buildings.production(),0.0231),"reinforced totem increases output")
	totem.tier = 1
	totem.position = first_position
	var second := buildings.structures[-1]
	second.fuel = 0
	check(is_equal_approx(buildings.production(),0.015),"expired totem does not dilute active output")
	second.fuel = 300
	game.state.satisfaction = game.state.cap()
	buildings.advance(1)
	check(game.state.satisfaction == game.state.cap(),"generation respects Satisfaction cap")
	game.hero.position = Vector3(0,0,5)
	game.hero.path.clear()
	game.save_path = "user://w3_build_test_%d.json" % OS.get_process_id()
	game.persistence_enabled = true
	game.save_game()
	var saved := SaveStore.read(game.save_path,game)
	check(saved.error.is_empty() and saved.data.version == 4,"current schema stores structures")
	buildings.damage(fence,500)
	check(buildings.structures.size() == 2 and not game.navigation.grid.is_point_solid(game.navigation.cell(fence_at)),"destroyed barrier removes collision and path blockage")
	# Restore the earlier snapshot directly through the same on-disk loader.
	var file := FileAccess.open(game.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(saved.data))
	file.close()
	game.load_game()
	check(buildings.structures.size() == 3 and buildings.structures[0].tier == 2 and buildings.structures[0].health == 100 and buildings.structures[1].fuel == 299,"load restores structure tiers durability and fuel")
	var bad: Dictionary = saved.data.duplicate(true)
	bad.buildings.structures[1].id = bad.buildings.structures[0].id
	check(not SaveStore.validate(bad,game).is_empty(),"duplicate structure IDs rejected")
	bad = saved.data.duplicate(true)
	bad.buildings.structures[0].position = [0,0,-2]
	check(not SaveStore.validate(bad,game).is_empty(),"invalid structure positions rejected")
	bad = saved.data.duplicate(true)
	bad.buildings.structures[0].health = -1
	check(not SaveStore.validate(bad,game).is_empty(),"negative structure durability rejected")
	bad = saved.data.duplicate(true)
	bad.buildings.structures[1].fuel = 301
	check(not SaveStore.validate(bad,game).is_empty(),"excess saved fuel rejected")
	bad = saved.data.duplicate(true)
	bad.buildings = []
	check(not SaveStore.validate(bad,game).is_empty(),"malformed building state rejected")
	var old: Dictionary = saved.data.duplicate(true)
	old.version = 1
	old.erase("buildings")
	file = FileAccess.open(game.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	game.load_game()
	check(buildings.structures.is_empty() and game.state.level == 2,"W2 save migrates without changing character progression")
	game.persistence_enabled = false
	# Exercise actual input dispatch and the placement preview, not only domain calls.
	game.hero.position = Vector3(3.25,0,0)
	stock("palisade")
	buildings.choice.select(0)
	buildings.toggle()
	buildings.actions.place.pressed.emit()
	var motion := InputEventMouseMotion.new()
	motion.position = game.camera.unproject_position(fence_at)
	root.push_input(motion,true)
	await frames()
	buildings.update_preview(motion.position)
	check(not buildings.placing.is_empty() and buildings.preview_position.distance_to(fence_at) < 0.01,"mouse position drives snapped placement preview")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = motion.position
	root.push_input(click,true)
	click = click.duplicate()
	click.pressed = false
	root.push_input(click,true)
	await frames()
	check(buildings.structures.size() == 1 and game.state.inventory.wood == 0 and game.hero.path.is_empty(),"world click builds preview without walking or duplicate payment")
	game.hero.position = Vector3(0,0,5)
	buildings.restore(saved.data.buildings)
	if "--visual" in OS.get_cmdline_user_args():
		buildings.inspect(buildings.structures[1])
		game.hero.path.clear()
		game.hero.position = Vector3(-3.25,0,-1.3)
		buildings.refresh()
		await frames(20)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://captures/w3-building.png")
	buildings.panel.show()
	buildings.refresh()
	await frames(3)
	check(buildings.panel.position.y+buildings.panel.size.y < 624,"building controls fit above bottom HUD")
	buildings.selected = buildings.structures[0]
	game.hero.position = buildings.selected.position+Vector3(0,0,2)
	before = game.state.serialize()
	check(buildings.interact("dismantle") and buildings.structures.size() == 2 and before == game.state.serialize(),"dismantling removes structure without duplicating resources")
	DirAccess.remove_absolute(game.save_path)
	game.queue_free()
	await frames()
	print("BUILDING: ",checks," checks; failures: ",failures)
	quit(failures)
