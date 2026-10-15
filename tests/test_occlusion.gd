extends SceneTree
var game: Node
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	else: print("PASS: ",message)
func frames(count: int) -> void:
	for i in count: await physics_frame
func click(point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = point
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await frames(4)
	game.combat.set_physics_process(false)
	game.combat.phase = "raid"
	var enemy: CombatUnit = game.combat.add_unit("raider",Vector3(0,0,-5.2))
	for zoom in [16,18.5,28]:
		game.camera.size = zoom
		await frames(50)
		check(game.occlusion.markers.has(enemy),"behind shrine indicator at zoom %s" % zoom)
		if game.occlusion.markers.has(enemy):
			click(game.occlusion.markers[enemy].point)
			check(game.combat.attack_target == enemy and not game.hud.menu.visible,"indicator targets enemy instead of shrine")
		check(not game.combat.can_hit(Vector3(0,0,1),enemy.position,enemy),"selection does not permit attacks through shrine")
		game.cancel()
		var hotspot: Vector2 = game.camera.unproject_position(game.shrine.position+Vector3(0,0.35,2.3))
		check(game.pick(hotspot).get("collider") == game.shrine,"dedicated service hotspot remains selectable")
	game.camera.size = 18.5
	var other: CombatUnit = game.combat.add_unit("raider",enemy.position)
	await frames(30)
	check(game.occlusion.markers.size() == 2,"overlapping hidden enemies both have indicators")
	check(game.occlusion.markers[enemy].point != game.occlusion.markers[other].point,"overlapping indicators are separated")
	for actor in [enemy,other]:
		click(game.occlusion.markers[actor].point)
		check(game.combat.attack_target == actor,"each overlapping enemy can be selected")
	for at in [Vector3(0,0,-5.2),Vector3(-4,0,-2),Vector3(4,0,-2),Vector3(0,0,2)]:
		enemy.position = at
		other.position = Vector3(8,0,8)
		await frames(20)
		var point: Vector2 = game.occlusion.markers[enemy].point if game.occlusion.markers.has(enemy) else game.camera.unproject_position(enemy.position+Vector3.UP)
		check(game.pick(point).get("collider") == enemy,"enemy approachable from %s" % at)
	enemy.position = Vector3(0,0,-5.2)
	await frames(40)
	game.save_path = "user://occlusion_%d.json" % OS.get_process_id()
	game.persistence_enabled = true
	game.save_game()
	game.load_game()
	game.persistence_enabled = false
	await frames(40)
	check(game.occlusion.markers.size() > 0,"occlusion reconstructs after active raid load")
	game.cancel()
	for i in 8: click(game.camera.unproject_position(Vector3(-2.6,0,-5.2)))
	check(game.target != game.shrine and not game.hero.path.is_empty(),"rapid rear-ground clicks navigate without opening shrine")
	var start: Vector3 = game.hero.position
	await frames(90)
	check(game.hero.position.distance_to(start)>1,"player moves around shrine after repeated clicks")
	if "--visual" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://captures/occlusion.png")
	game.hero.position = Vector3(0,0,5)
	for actor in game.combat.units: actor.position = Vector3(10,0,12)
	await frames(90)
	var restored := true
	for piece in game.occlusion.pieces:
		if piece.mesh.is_ancestor_of(game.shrine): continue
		if piece.hold == 0 and piece.alpha == 1:
			restored = restored and piece.mesh.material_override == piece.original
	check(restored,"original material identities restored after fade")
	game.queue_free()
	await frames(2)
	print("OCCLUSION: ",checks," checks; failures: ",failures)
	quit(failures)
