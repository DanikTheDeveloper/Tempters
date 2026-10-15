extends SceneTree

var game: Node
var combat: CombatDirector
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: ",label)
	else:
		failures += 1
		push_error(label)

func frames(count: int) -> void:
	for i in count: await physics_frame

func clear_units() -> void:
	for unit in combat.units.duplicate(): combat.remove_unit(unit)
	combat.phase = "peace"
	combat.timer = 360
	combat.capture_progress = 0
	combat.set_occupied(false)
	game.cancel()

func stock_golem() -> void:
	for item in game.state.inventory: game.state.inventory[item] = 0
	game.state.inventory.stone = 8
	game.state.inventory.ingot = 2
	game.state.satisfaction = 16
	game.state.level = 2
	game.feed_lock = 0
	game.hero.position = Vector3(0,0,1.5)

func click(at: Vector3) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = game.camera.unproject_position(at)
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)

func _initialize() -> void: call_deferred("run")

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await frames(3)
	combat = game.combat
	combat.set_physics_process(false)
	combat.restore(combat.fresh_data())
	combat.advance_clock(329)
	check(combat.phase == "peace" and combat.units.is_empty(),"initial preparation grace has no hostiles")
	combat.advance_clock(1)
	check(combat.phase == "warning" and combat.units.size() == 1 and combat.units[0].scout,"visible scout precedes first raid by thirty seconds")
	combat.advance_clock(29)
	check(combat.phase == "warning","first raid cannot begin before six minutes")
	combat.advance_clock(1)
	check(combat.phase == "raid" and combat.hostiles().size() == 2 and combat.wave == 1,"first raid spawns two opponents after warning")
	clear_units()
	stock_golem()
	game.state.satisfaction = 15
	var before: Dictionary = game.state.serialize()
	check(not combat.summon() and game.state.serialize() == before and combat.defenders().is_empty(),"insufficient Satisfaction cannot consume summoning materials")
	game.state.satisfaction = 16
	check(combat.summon() and combat.defenders().size() == 1 and game.state.satisfaction == 0 and game.state.inventory.stone == 0 and game.state.inventory.ingot == 0,"golem summoning is atomic at exact cost")
	before = game.state.serialize()
	check(not combat.summon() and before == game.state.serialize(),"rapid summoning click is throttled")
	for i in 2:
		stock_golem()
		check(combat.summon(),"additional defender can be summoned")
	stock_golem()
	before = game.state.serialize()
	check(not combat.summon() and before == game.state.serialize(),"defender cap preserves resources")
	var golem := combat.defenders()[0]
	combat.select(golem)
	combat.deploy(Vector3(3.25,0,3.25))
	check(golem.home.distance_to(Vector3(3.25,0,3.25)) < 0.1,"golem accepts guard deployment")
	clear_units()
	game.feed_lock = 0
	game.hero.position = Vector3(0,0,5)
	game.state.equipment.spear = true
	game.state.health = 100
	combat.phase = "raid"
	combat.timer = 180
	var enemy := combat.add_unit("raider",Vector3(1.3,0,3.25))
	await frames(3)
	combat.set_physics_process(true)
	await click(enemy.position+Vector3.UP)
	check(combat.attack_target == enemy,"world click selects hostile for player combat")
	for i in 300:
		await physics_frame
		if combat.hostiles().is_empty(): break
	check(combat.hostiles().is_empty() and game.state.health > 0,"equipped spear pursues and defeats an enemy")
	check(combat.phase == "peace" and combat.pending_reward > 0,"successful defense schedules recovery interval and reward")
	combat.set_physics_process(false)
	game.hero.position = Vector3(0,0,1.5)
	for item in game.state.inventory: game.state.inventory[item] = 0
	game.state.inventory.wood = 15
	var reward := combat.pending_reward
	check(not combat.collect_reward() and combat.pending_reward == reward,"full inventory retains unclaimed raid reward")
	game.state.inventory.wood = 13
	check(combat.collect_reward() and game.state.inventory.raw_meat == 3 and combat.pending_reward == reward-3,"raid reward collected once when space is available")
	check(not combat.collect_reward(),"raid reward cannot be duplicated")
	clear_units()
	game.hero.position = Vector3(3.25,0,0)
	game.state.inventory.wood = 4
	check(game.buildings.place("palisade",Vector3(4.55,0,-3.25)),"combat fixture has a real barrier")
	var fence: BaseStructure = game.buildings.structures[0]
	game.hero.position = Vector3(0,0,10)
	combat.phase = "raid"
	combat.timer = 180
	enemy = combat.add_unit("raider",Vector3(4.55,0,-5.85))
	combat.set_physics_process(true)
	for i in 240:
		await physics_frame
		if fence.health < 100: break
	check(fence.health < 100,"hostile AI approaches and damages a barrier")
	var enemy_start := enemy.position
	game.buildings.damage(fence,1000)
	await frames(90)
	check(enemy.position.distance_to(enemy_start) > 0.3,"enemy navigation continues after barrier destruction")
	combat.set_physics_process(false)
	clear_units()
	game.hero.position = Vector3(0,0,10)
	combat.phase = "raid"
	combat.timer = 180
	golem = combat.add_unit("golem",Vector3(3.25,0,0))
	enemy = combat.add_unit("raider",Vector3(5.2,0,0))
	combat.set_physics_process(true)
	for i in 360:
		await physics_frame
		if combat.hostiles().is_empty(): break
	check(combat.hostiles().is_empty() and combat.defenders().size() == 1,"golem autonomously detects pursues and defeats a hostile")
	check(golem.health < golem.maximum_health,"enemy fights a defender and inflicts damage")
	combat.hit_unit(golem,1000)
	check(combat.defenders().is_empty(),"destroyed final defender is removed without locking gameplay")
	combat.set_physics_process(false)
	clear_units()
	combat.phase = "raid"
	combat.timer = 180
	enemy = combat.add_unit("raider",Vector3(0,0,-5.2))
	game.hero.position = Vector3(0,0,10)
	combat.set_physics_process(true)
	await frames(120)
	check(combat.capture_progress > 1,"undefended raider channels shrine capture")
	combat.hit_unit(enemy,1)
	check(combat.capture_progress == 0,"damage interrupts capture channel")
	game.save_path = "user://combat_regression_%d.json" % OS.get_process_id()
	game.persistence_enabled = true
	game.save_game()
	game.load_game()
	check(combat.phase == "raid" and combat.hostiles().size() == 1 and combat.capture_progress < 0.1,"load during encounter restores enemy health and raid state")
	var start: Vector3 = game.hero.position
	await click(Vector3(2,0,3))
	await frames(30)
	check(game.hero.position.distance_to(start) > 1,"player remains controllable after encounter reload")
	game.cancel()
	game.hero.position = Vector3(0,0,10)
	for i in 720:
		await physics_frame
		if combat.phase == "occupied": break
	check(combat.phase == "occupied" and game.state.services_locked and combat.banner.visible,"full capture channel creates temporary occupation")
	game.save_game()
	game.load_game()
	check(combat.phase == "occupied" and game.state.services_locked,"occupied shrine survives reload")
	check(game.buildings.production() == 0,"occupied shrine disables passive Satisfaction")
	game.state.inventory.raw_meat = 1
	game.state.satisfaction = 0
	check(game.state.feed() and game.state.satisfaction == 4,"feeding remains available during occupation and dormancy")
	check(not game.state.quote("primitive_axe").ok,"occupation blocks crafting services")
	game.state.satisfaction = 10
	game.state.health = 50
	check(game.state.try_service("heal").ok and game.state.health == 75,"occupation preserves paid healing")
	combat.advance_clock(121)
	check(combat.hostiles().is_empty(),"occupation has a guaranteed enemy withdrawal")
	game.hero.position = Vector3(0,0,1.5)
	combat.reclaim_button.pressed.emit()
	for i in 660:
		await physics_frame
		if combat.phase == "peace": break
	check(combat.phase == "peace" and not game.state.services_locked and not combat.banner.visible,"free reclaim channel restores shrine access")
	game.state.health = 0
	await frames(2)
	check(game.state.health > 0 and combat.immunity > 0 and game.hero.position.distance_to(Vector3(0,0,5)) < 0.1,"zero Health rescues player with temporary protection")
	game.save_game()
	game.load_game()
	check(game.state.health > 0 and not game.paused and game.hero.is_physics_processing(),"post-defeat reload remains playable")
	combat.set_physics_process(false)
	clear_units()
	combat.wave = 10
	game.state.level = 5
	combat.start_raid()
	check(combat.hostiles().size() == combat.config.max_raiders,"raid escalation is bounded")
	combat.advance_clock(181)
	check(combat.hostiles().is_empty(),"raid duration prevents indefinitely stuck attackers")
	clear_units()
	stock_golem()
	combat.summon()
	combat.phase = "raid"
	combat.timer = 100
	combat.add_unit("raider",Vector3(0,0,-7.8))
	var snapshot := SaveStore.snapshot(game)
	check(SaveStore.validate(snapshot,game).is_empty(),"complete combat snapshot validates")
	snapshot.combat.units[0].health = -1
	check(not SaveStore.validate(snapshot,game).is_empty(),"invalid saved actor health rejected")
	if "--visual" in OS.get_cmdline_user_args():
		game.persistence_enabled = false
		combat.defenders()[0].position = Vector3(2.6,0,2.6)
		combat.hostiles()[0].position = Vector3(4.55,0,2.6)
		combat.set_physics_process(true)
		game.hud.menu.hide()
		await frames(20)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://captures/w3-combat.png")
	game.persistence_enabled = false
	game.queue_free()
	await frames(3)
	print("COMBAT: ",checks," checks; failures: ",failures)
	quit(failures)
