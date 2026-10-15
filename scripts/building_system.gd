class_name BuildingSystem
extends Node3D

var game: Node
var config: Dictionary
var structures: Array[BaseStructure] = []
var next_id := 1
var placing := ""
var angle := 0.0
var preview: Node3D
var preview_position := Vector3.ZERO
var selected: BaseStructure
var panel: PanelContainer
var details: Label
var placement_status: Label
var economy_text: Label
var choice: OptionButton
var actions: Dictionary = {}
var cached_cell := Vector2i(999,999)
var cached_validity := ""

func setup(owner_game: Node) -> void:
	game = owner_game
	config = game.state.balance.defense.building
	for kind in config.types: config.types[kind].inputs = game.state.balance.recipes[kind].inputs
	var toolbar: Button = game.hud.button(game.hud,"Build [G]",toggle)
	toolbar.position = Vector2(350,22)
	toolbar.custom_minimum_size.x = 120
	panel = game.hud.panel(Vector2(876,150),Vector2(380,0))
	var box := VBoxContainer.new()
	panel.add_child(box)
	game.hud.text(box,"Defenses",20)
	choice = OptionButton.new()
	choice.custom_minimum_size.y = 35
	box.add_child(choice)
	for kind in config.types: choice.add_item(config.types[kind].name)
	choice.item_selected.connect(func(_index): stop_placement(); clear_selection(); placement_status.text = ""; refresh())
	details = game.hud.text(box,"",14)
	details.custom_minimum_size = Vector2(345,90)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	actions.place = game.hud.button(box,"Choose location",begin_placement)
	placement_status = game.hud.text(box,"",13,Color("d6b18a"))
	placement_status.custom_minimum_size = Vector2(345,30)
	placement_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for id in ["repair","refuel","upgrade","dismantle"]:
		actions[id] = game.hud.button(box,id.capitalize(),func(): interact(id))
	economy_text = game.hud.text(box,"",12)
	economy_text.custom_minimum_size = Vector2(345,40)
	economy_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game.hud.button(box,"Close",close)
	panel.hide()
	refresh()

func cost_text(cost: Dictionary) -> String:
	var parts := PackedStringArray()
	for item in cost: parts.append("%d %s" % [cost[item],item.replace("_"," ")])
	return ", ".join(parts)

func can_pay(cost: Dictionary) -> String:
	var missing := PackedStringArray()
	for item in cost:
		if game.state.inventory[item] < cost[item]: missing.append("%d %s" % [cost[item]-game.state.inventory[item],item])
	return "" if missing.is_empty() else "Need " + ", ".join(missing) + "."

func pay(cost: Dictionary) -> void:
	for item in cost: game.state.inventory[item] -= cost[item]
	game.state.changed.emit()

func toggle() -> void:
	if panel.visible: close()
	else:
		game.cancel()
		panel.show()
		refresh()

func clear_selection() -> void:
	if is_instance_valid(selected): selected.marker.hide()
	selected = null

func stop_placement() -> void:
	if not placing.is_empty(): game.hud.hint.text = "Click to move or interact."
	placing = ""
	if is_instance_valid(preview): preview.queue_free()
	preview = null
	cached_cell = Vector2i(999,999)

func close() -> void:
	stop_placement()
	clear_selection()
	panel.hide()

func begin_placement() -> void:
	if game.paused or game.feed_lock > 0: return
	game.cancel()
	panel.show()
	clear_selection()
	stop_placement()
	placing = config.types.keys()[choice.selected]
	preview = Fortifications.build(self,placing)
	game.hud.hint.text = "Click to build / R rotate / Right-click cancel. Move closer before placing."
	refresh()

func inspect(structure: BaseStructure) -> void:
	stop_placement()
	clear_selection()
	selected = structure
	game.hud.hint.text = config.types[selected.kind].name + " / Maintain or reinforce"
	choice.select(config.types.keys().find(selected.kind))
	placement_status.text = ""
	selected.marker.show()
	panel.show()
	game.hero.path = game.navigation.route(game.hero.position,structure.position,config.interaction_reach)
	refresh()

func navigation_for(entries: Array) -> GridNavigation:
	var nav := GridNavigation.new()
	for node in game.targets:
		if node.kind != "hare": nav.block(node.home,node.radius)
	for entry in entries: nav.block(Vector3(entry.position[0],0,entry.position[2]),config.types[entry.kind].radius)
	return nav

func rebuild_navigation() -> void:
	game.navigation = navigation_for(serialize().structures)
	if is_instance_valid(game.frontier):
		game.navigation.external_route = game.frontier.route
		game.frontier.nav_dirty = true
	game.hero.path.clear()
	game.target = null
	game.hero.working = false
	cached_cell = Vector2i(999,999)

func placement_error(kind: String, at: Vector3, check_routes := true) -> String:
	if not at.is_finite() or at.y != 0 or not is_finite(angle): return "Invalid placement."
	if not config.types.has(kind): return "Unknown structure."
	if structures.size() >= config.max_structures: return "Structure limit reached."
	var count := 0
	for node in structures:
		if node.kind == "totem": count += 1
	if kind == "totem" and count >= config.max_totems: return "Totem limit reached."
	var base := construction_base()
	var anchor := CreatureManager.point(base)
	if at.distance_to(anchor) > config.build_radius: return "Build within %dm of the shrine." % config.build_radius
	if at.distance_to(game.hero.position) > config.placement_reach: return "Move closer to build."
	var radius: float = config.types[kind].radius
	if at.distance_to(game.hero.position) < radius+0.65: return "Player occupies this location."
	# Preserve the authored roots, offering ring and a walkable southern escape lane.
	if at.distance_to(anchor) < 3.7+radius: return "Keep the shrine and offerings clear."
	if absf(at.x-anchor.x) < 1.3+radius and at.z > anchor.z+2: return "Keep the shrine approach clear."
	for node in game.targets+game.frontier.resources:
		var clearance: float = 2.25 if node.kind == "hare" else node.radius+0.4
		if at.distance_to(node.home) < clearance+radius: return "Resource area must remain clear."
	for node in structures:
		if at.distance_to(node.position) < node.radius+radius+0.15: return "Structures overlap."
	if is_instance_valid(game.combat):
		for unit in game.combat.units:
			if at.distance_to(unit.position) < radius+0.65: return "Unit occupies this location."
	if check_routes and base.id==game.shrine.persistent_id:
		var entries: Array = serialize().structures
		entries.append({"kind":kind,"position":[at.x,0,at.z]})
		var nav := navigation_for(entries)
		var start := nav.cell(game.hero.position)
		if nav.grid.is_point_solid(start): return "Player needs a clear exit."
		for node in game.targets:
			var route := nav.route(game.hero.position,node.home,game.reach(node))
			if route.is_empty() or route[-1].distance_to(node.home) > game.reach(node)+0.1: return "Placement blocks resource access."
	return ""

func place(kind: String, at: Vector3) -> bool:
	if game.paused or game.feed_lock > 0: return false
	var error := placement_error(kind,at)
	if error.is_empty(): error = can_pay(config.types[kind].inputs)
	if not error.is_empty():
		placement_status.text = error
		return false
	# No yields between validation, object creation and deduction.
	var base := construction_base()
	var data := {"base_id":"" if base.id==game.shrine.persistent_id else base.id,"id":next_id,"kind":kind,"tier":1,"health":config.types[kind].health,"fuel":config.totem_fuel_seconds if kind == "totem" else 0,"position":[at.x,0,at.z],"angle":angle}
	add_structure(data)
	next_id += 1
	pay(config.types[kind].inputs)
	rebuild_navigation()
	stop_placement()
	game.save_game(false)
	refresh()
	return true

func add_structure(data: Dictionary) -> BaseStructure:
	var node := BaseStructure.new()
	add_child(node)
	node.setup(data,config)
	structures.append(node)
	return node

func action_error(id: String) -> String:
	if game.paused or game.feed_lock > 0: return "Unavailable while paused or busy."
	if not is_instance_valid(selected): return "Select a structure in the world."
	if selected.position.distance_to(game.hero.position) > config.interaction_reach+0.2: return "Approach the structure."
	if id == "dismantle": return ""
	if id == "repair" and selected.health >= selected.maximum_health(): return "Durability is full."
	if id == "refuel" and (selected.kind != "totem" or selected.fuel > config.totem_fuel_seconds-1): return "No maintenance needed."
	if id == "upgrade":
		if selected.tier >= 2: return "Maximum tier reached."
		if base_record(selected.base_id).level < config.upgrade_level: return "Requires shrine level %d." % config.upgrade_level
	if not id in ["repair","refuel","upgrade"]: return "Unknown action."
	return can_pay(config[id])

func interact(id: String) -> bool:
	var error := action_error(id)
	if not error.is_empty():
		placement_status.text = error
		return false
	if id == "dismantle":
		destroy(selected)
	else:
		pay(config[id])
		if id == "repair": selected.health = minf(selected.maximum_health(),selected.health+config.repair_amount)
		if id == "refuel": selected.fuel = config.totem_fuel_seconds
		if id == "upgrade":
			selected.tier = 2
			selected.rebuild_art()
		selected.update_damage()
	game.save_game(false)
	refresh()
	return true

func damage(node: BaseStructure, amount: float) -> void:
	if not structures.has(node) or not is_finite(amount) or amount <= 0: return
	node.health = maxf(0,node.health-amount)
	if node.health <= 0: destroy(node)
	else: node.update_damage()
	# Damage is included in the periodic save; destruction saves immediately below.

func destroy(node: BaseStructure) -> void:
	if not structures.has(node): return
	if selected == node: clear_selection()
	structures.erase(node)
	node.collision_layer = 0
	remove_child(node)
	node.queue_free()
	rebuild_navigation()
	game.save_game(false)

func production(base_id := "") -> float:
	var base := base_record(base_id)
	if base.is_empty() or base.owner!="player": return 0.0
	var strengths: Array[float] = []
	for node in structures:
		if node.kind != "totem" or node.fuel <= 0 or node.base_id!=base_id: continue
		var strength: float = config.upgrade_multiplier if node.tier == 2 else 1.0
		if node.position.distance_to(CreatureManager.point(base)) > config.totem_inner_radius: strength *= config.totem_outer_efficiency
		strengths.append(strength)
	strengths.sort()
	strengths.reverse()
	var rate := 0.0
	for i in strengths.size(): rate += game.state.balance.defense.totem_satisfaction_per_second_first*strengths[i]*pow(config.totem_decay,i)
	return minf(rate,config.totem_output_cap)

func advance(delta: float) -> void:
	if game.paused or delta <= 0: return
	# Split at fuel expiry so large steps cannot generate beyond maintained lifetime.
	var left := delta
	while left > 0:
		var step := left
		for node in structures:
			if node.kind == "totem" and node.fuel > 0: step = minf(step,node.fuel)
		game.state.satisfaction = minf(game.state.cap(),game.state.satisfaction+production()*step)
		if is_instance_valid(game.creatures):
			for id in game.creatures.records:
				var record: Dictionary = game.creatures.records[id]
				record.satisfaction = minf(game.creatures.cap(record),record.satisfaction+production(id)*step)
		for node in structures:
			if node.kind == "totem":
				node.fuel = maxf(0,node.fuel-step)
				node.ember.visible = node.fuel > 0
		left = maxf(0,left-step)

func tick(delta: float) -> void:
	advance(delta)
	if panel.visible: refresh()
	update_preview(game.get_viewport().get_mouse_position())

func update_preview(mouse: Vector2) -> void:
	if placing.is_empty() or not is_instance_valid(preview): return
	var hit: Variant = Plane(Vector3.UP,0).intersects_ray(game.camera.project_ray_origin(mouse),game.camera.project_ray_normal(mouse))
	if hit == null: return
	preview_position = Vector3(snappedf(hit.x,config.snap),0,snappedf(hit.z,config.snap))
	preview.position = preview_position
	preview.rotation.y = angle
	var cell: Vector2i = game.navigation.cell(preview_position)
	if cell != cached_cell:
		cached_cell = cell
		cached_validity = placement_error(placing,preview_position)
	var error := cached_validity
	if error.is_empty(): error = can_pay(config.types[placing].inputs)
	placement_status.text = "Click to build. R rotates." if error.is_empty() else error
	var material := Sculpt.mat("8caa8c" if error.is_empty() else "b64f44",0.7,0,0.15)
	for mesh in preview.get_children():
		if mesh is MeshInstance3D: mesh.material_override = material

func refresh() -> void:
	var kind: String = config.types.keys()[choice.selected]
	var spec: Dictionary = config.types[kind]
	details.text = "%s\nCost: %s" % [spec.description,cost_text(spec.inputs)]
	if is_instance_valid(selected): details.text = "%s · Tier %d\nDurability %.0f / %.0f%s" % [config.types[selected.kind].name,selected.tier,selected.health,selected.maximum_health(),"\nMaintenance in %ds" % ceili(selected.fuel) if selected.kind == "totem" else ""]
	details.custom_minimum_size.y = 60 if is_instance_valid(selected) else 90
	actions.place.visible = not is_instance_valid(selected)
	actions.place.disabled = game.paused or game.feed_lock > 0 or not can_pay(spec.inputs).is_empty()
	actions.place.tooltip_text = can_pay(spec.inputs)
	for id in ["repair","refuel","upgrade","dismantle"]:
		actions[id].visible = is_instance_valid(selected)
		actions[id].disabled = not action_error(id).is_empty()
		actions[id].tooltip_text = action_error(id)
	actions.repair.text = "Repair +%d / %s" % [config.repair_amount,cost_text(config.repair)]
	actions.refuel.text = "Maintain / " + cost_text(config.refuel)
	actions.upgrade.text = "Reinforce / " + cost_text(config.upgrade)
	actions.upgrade.tooltip_text += "\nMaximum durability ×1.5; totem output ×1.5. No free repair."
	actions.dismantle.text = "Dismantle / no refund"
	economy_text.text = "Totems +%.3f Satisfaction/s · Cap %.3f\nEach additional totem: 60%% output. Maximum %d." % [production(),config.totem_output_cap,config.max_totems]

func serialize() -> Dictionary:
	var entries := []
	for node in structures: entries.append(node.serialize())
	return {"next_id":next_id,"structures":entries}

func restore(data: Dictionary) -> void:
	close()
	for node in structures:
		remove_child(node)
		node.queue_free()
	structures.clear()
	next_id = int(data.next_id)
	for entry in data.structures: add_structure(entry)
	rebuild_navigation()

func validate_data(data: Variant, player: Vector3, registry: Dictionary = {}) -> String:
	if not data is Dictionary or not data.get("structures") is Array: return "Invalid structures."
	if not GameState.whole_number(data.get("next_id")) or data.next_id < 1 or data.next_id > 1000000000: return "Invalid structure sequence."
	if data.structures.size() > config.max_structures: return "Structure limit exceeded."
	var ids := {}
	var positions: Array[Vector3] = []
	var radii: Array[float] = []
	var totems := 0
	for entry in data.structures:
		if not entry is Dictionary: return "Invalid structure entry."
		for key in ["id","kind","tier","health","fuel","position","angle"]:
			if not entry.has(key): return "Incomplete structure entry."
		if not GameState.whole_number(entry.id) or entry.id < 1 or entry.id >= data.next_id or ids.has(entry.id): return "Invalid structure ID."
		ids[entry.id] = true
		if not entry.kind is String or not config.types.has(entry.kind): return "Unknown structure kind."
		if not GameState.whole_number(entry.tier) or entry.tier < 1 or entry.tier > 2: return "Invalid structure tier."
		if not SaveStore.valid_position(entry.position): return "Invalid structure position."
		for key in ["health","fuel","angle"]:
			if not (entry[key] is int or entry[key] is float) or not is_finite(float(entry[key])): return "Invalid structure value."
		if entry.health <= 0 or entry.health > config.types[entry.kind].health*(config.upgrade_multiplier if entry.tier == 2 else 1): return "Invalid durability."
		if entry.fuel < 0 or entry.fuel > config.totem_fuel_seconds or (entry.kind != "totem" and entry.fuel != 0): return "Invalid totem fuel."
		if absf(entry.angle) > TAU: return "Invalid structure rotation."
		if not entry.get("base_id","") is String: return "Invalid structure territory."
		var base := base_record(entry.get("base_id",""),registry)
		if base.is_empty(): return "Unknown structure territory."
		var anchor := CreatureManager.point(base)
		var at := Vector3(entry.position[0],0,entry.position[2])
		var radius: float = config.types[entry.kind].radius
		if at.distance_to(anchor) > config.build_radius or at.distance_to(anchor) < 3.7+radius or (absf(at.x-anchor.x) < 1.3+radius and at.z > anchor.z+2): return "Structure blocks shrine access."
		if at.distance_to(player) < radius+0.23: return "Player overlaps a structure."
		for node in game.targets:
			var clearance: float = 2.25 if node.kind == "hare" else node.radius+0.4
			if at.distance_to(node.home) < clearance+radius: return "Structure blocks a resource."
		for i in positions.size():
			if at.distance_to(positions[i]) < radius+radii[i]+0.15: return "Structures overlap."
		positions.append(at)
		radii.append(radius)
		if entry.kind == "totem": totems += 1
	if totems > config.max_totems: return "Totem limit exceeded."
	var nav := navigation_for(data.structures)
	for node in game.targets:
		var route := nav.route(player if maxf(absf(player.x),absf(player.z))<=16 else Vector3(0,0,5),node.home,game.reach(node))
		if route.is_empty() or route[-1].distance_to(node.home) > game.reach(node)+0.1: return "Structures block resource access."
	return ""

func base_record(id := "", registry: Dictionary = {}) -> Dictionary:
	if not is_instance_valid(game.creatures): return {"position":[0,0,-2],"level":game.state.level,"owner":"player","id":"shrine_1"}
	if id.is_empty() or id==game.shrine.persistent_id: return game.creatures.home_record()
	return registry.get(id,{}) if not registry.is_empty() else game.creatures.get_record(id)

func construction_base() -> Dictionary:
	if not is_instance_valid(game.creatures): return base_record()
	var record: Dictionary = game.creatures.nearest(game.hero.position)
	return base_record() if record.is_empty() else record
