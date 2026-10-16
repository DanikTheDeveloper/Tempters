class_name CreatureManager
extends Node

var game: Node
var records: Dictionary = {}
var nodes: Dictionary = {}
var templates: Dictionary = {}
var config: Dictionary
var selected := ""
var capturing := ""
var travel_pending := ""
var travel_source := ""
var travel_elapsed := 0.0
var recall_destination := ""
var capture_health := 0.0
var panel: PanelContainer
var box: VBoxContainer
var details: Label
var actions: VBoxContainer
var refresh_clock := 0.0

func setup(owner_game: Node) -> void:
	game = owner_game
	config = game.state.balance.territory
	var button: Button = game.hud.button(game.hud,"Territory [T]",toggle)
	button.position = Vector2(350,68)
	button.custom_minimum_size.x = 120
	panel = game.hud.panel(Vector2(860,145),Vector2(396,0))
	box = VBoxContainer.new()
	panel.add_child(box)
	details = game.hud.text(box,"",14)
	details.custom_minimum_size = Vector2(364,0)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(364,280)
	box.add_child(scroll)
	actions = VBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(actions)
	game.hud.button(box,"Close",close)
	panel.hide()

func home_record() -> Dictionary:
	return {"id":game.shrine.persistent_id,"position":[game.shrine.position.x,0,game.shrine.position.z],"biome":"forest","owner":"npc" if game.state.services_locked else "player","satisfaction":game.state.satisfaction,"level":game.state.level,"discovered":true,"activated":not game.state.services_locked,"capture":0.0}

func all_records() -> Array:
	return [home_record()]+records.values()

static func point(record: Dictionary) -> Vector3:
	return Vector3(record.position[0],0,record.position[2])

func cap(record: Dictionary) -> float:
	return game.state.balance.temptress.max_satisfaction_per_level[int(record.level)-1]

func get_record(id: String) -> Dictionary:
	return home_record() if id == game.shrine.persistent_id else records.get(id,{})

func set_satisfaction(id: String, value: float) -> void:
	if id == game.shrine.persistent_id: game.state.satisfaction = value
	else: records[id].satisfaction = value

func nearest(at: Vector3, require_energy := false) -> Dictionary:
	var found := {}
	var best := INF
	for record in all_records():
		if record.owner != "player" or not record.activated or (require_energy and record.satisfaction<=0): continue
		var distance := at.distance_to(point(record))
		if distance < best:
			best = distance
			found = record
	return found

func bond_capacity(record: Dictionary) -> float:
	return game.state.balance.expedition_bond.initial_max+(record.level-1)*game.state.balance.expedition_bond.max_bonus_per_core_level+config.types[record.biome].bond_bonus

func build_template(biome: String) -> Node3D:
	game.occlusion.reset()
	var root: Node3D = game.shrine.art.get_parent().duplicate()
	# Duplicate the full sculpture (mound, roots, bowls and breathing folds).
	for mesh in root.find_children("*","MeshInstance3D",true,false):
		if mesh.material_override is StandardMaterial3D:
			var material: StandardMaterial3D = mesh.material_override.duplicate()
			var tint := Color("bd9870") if biome == "desert" else Color("bbcbdc")
			material.albedo_color = material.albedo_color.lerp(tint,0.55)
			material.roughness = 0.72 if biome == "desert" else 0.42
			mesh.material_override = material
	var stone := Sculpt.mat("9c7956" if biome == "desert" else "8aafbb",0.8 if biome == "desert" else 0.32)
	for side in [-1,1]:
		var points: Array[Vector3] = [Vector3(side*3.6,0,-1.2),Vector3(side*3.4,0.8,-1.2),Vector3(side*3.6,1.9,-1.1),Vector3(side*3.4,2.6,-1.3)]
		Sculpt.loft(root,points,[0.7,0.6,0.4,0.12],[0.6,0.55,0.4,0.06],stone,7)
		if biome == "snow":
			for i in 4: Sculpt.rock(root,Vector3(side*(2.3+i*0.2),0.4+i*0.15,1.0),Vector3(0.12,0.5+i*0.1,0.16),stone,i)
	root.hide()
	game.add_child(root)
	templates[biome] = root
	return root

func spawn_site(cell: Vector2i) -> void:
	var site: Dictionary = game.frontier.layout.creature_site(cell)
	if site.is_empty() or nodes.has(site.id): return
	if not records.has(site.id):
		var record: Dictionary = site.duplicate(true)
		record.merge({"owner":"neutral","satisfaction":0.0,"level":1,"discovered":false,"activated":false,"capture":0.0,"guards":[],"enemy_capture":0.0,"ever_owned":false,"threat":"stable","threat_timer":config.raid_interval})
		if site.biome == "desert":
			record.owner = "npc"
			for i in 2:
				var at := point(site)+Vector3(-3.2 if i==0 else 3.2,0,2.2)
				record.guards.append({"id":i+1,"kind":"raider","health":game.state.balance.defense.combat.units.raider.health,"position":[at.x,0,at.z],"home":[at.x,0,at.z],"scout":false,"cooldown":0.0})
		record.id = site.id
		records[site.id] = record
	var template: Node3D = templates.get(site.biome)
	if template == null: template = build_template(site.biome)
	var visual: Node3D = template.duplicate()
	visual.show()
	var node := Interactable.new()
	game.add_child(node)
	node.setup("shrine",point(site),0,visual)
	node.art = visual.get_node("BreathingFolds")
	node.persistent_id = site.id
	node.title = config.types[site.biome].name
	node.add_to_group("camera_occluder_body")
	game.occlusion.register(visual)
	var banner := CombatArt.banner(node)
	banner.position = Vector3(-2.7,0,1.8)
	banner.visible = records[site.id].owner in ["npc","contested"]
	node.set_meta("territory_banner",banner)
	nodes[site.id] = node
	for guard in records[site.id].guards:
		var unit: CombatUnit = game.combat.restore_unit(guard)
		unit.territory_id = site.id
	game.frontier.nav_dirty = true

func unload_site(cell: Vector2i) -> void:
	for id in nodes.keys():
		var node: Interactable = nodes[id]
		if WorldLayout.chunk(node.position) != cell: continue
		park_guards(id)
		if game.target == node: game.cancel()
		if game.hover == node: game.hover = null
		game.remove_child(node)
		node.queue_free()
		nodes.erase(id)

func close() -> void:
	panel.hide()
	capturing = ""
	travel_pending = ""
	travel_source = ""
	if is_instance_valid(game.frontier): game.frontier.center = Vector2i(999,999)

func toggle() -> void:
	if panel.visible: close()
	else:
		game.cancel()
		selected = ""
		panel.show()
		refresh()

func inspect(id: String) -> void:
	selected = id
	panel.show()
	refresh()

func near_record(record: Dictionary) -> bool:
	return not record.is_empty() and game.hero.position.distance_to(point(record))<3.6

func capture_error(id: String) -> String:
	var record := get_record(id)
	if record.is_empty() or record.owner == "player": return "Unavailable."
	if game.paused or not near_record(record): return "Approach the shrine."
	for unit in game.combat.hostiles(true):
		if unit.position.distance_to(point(record))<12: return "Clear nearby enemies."
	if record.get("ever_owned",false): return ""
	for item in config.capture_inputs:
		if game.state.inventory[item]<config.capture_inputs[item]: return "Requires "+game.buildings.cost_text(config.capture_inputs)+"."
	return ""

func begin_capture(id: String) -> bool:
	var error := capture_error(id)
	if not error.is_empty():
		game.hud.notice.text = error
		return false
	capturing = id
	capture_health = game.state.health
	game.hero.path.clear()
	return true

func tick(delta: float) -> void:
	if game.paused: return
	for id in records:
		var record: Dictionary = records[id]
		if record.owner == "player":
			var drain: float = game.state.balance.temptress.passive_drain_per_second*game.state.balance.temptress.higher_tier_appetite_multiplier[int(record.level)-1]*config.types[record.biome].appetite*config.maintenance_multiplier
			record.satisfaction = maxf(0,record.satisfaction-delta*drain)
		if nodes.has(id):
			nodes[id].satisfaction_ratio = record.satisfaction/cap(record)
			nodes[id].get_meta("territory_banner").visible = record.owner in ["npc","contested"]
			if not record.discovered and game.hero.position.distance_to(point(record))<config.discovery_radius:
				record.discovered = true
				game.hud.notice.text = config.types[record.biome].name+" discovered."
	advance_territories(delta)
	if not capturing.is_empty():
		var id := capturing
		if not capture_error(id).is_empty() or game.state.health<capture_health:
			records[id].capture = 0.0
			capturing = ""
		else:
			records[id].capture = minf(config.capture_seconds,records[id].capture+delta)
			if records[id].capture >= config.capture_seconds:
				if not records[id].ever_owned:
					for item in config.capture_inputs: game.state.inventory[item] -= config.capture_inputs[item]
				records[id].merge({"owner":"player","activated":true,"satisfaction":(records[id].satisfaction if records[id].ever_owned else config.initial_satisfaction),"capture":0.0,"ever_owned":true,"threat":"stable","threat_timer":config.raid_interval},true)
				capturing = ""
				game.state.changed.emit()
				game.hud.notice.text = "Shrine claimed."
				nodes[id].pulse = 1
				game.save_game(false)
	if not travel_pending.is_empty(): advance_travel(delta)
	refresh_clock += delta
	if panel.visible and refresh_clock>0.5 and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		refresh_clock = 0
		refresh()

func feed(id: String) -> bool:
	var record := get_record(id)
	if game.paused or game.feed_lock>0 or not near_record(record) or record.owner!="player" or game.state.inventory.raw_meat<1: return false
	game.state.inventory.raw_meat -= 1
	set_satisfaction(id,minf(cap(record),record.satisfaction+config.types[record.biome].feed_gain))
	game.feed_lock = game.state.balance.runtime.service_cooldown
	if nodes.has(id): nodes[id].pulse = 1
	game.state.offerings += 1
	game.state.changed.emit()
	game.save_game(false)
	return true

# Secondary service quotes use an isolated state view. Global inventory/gear/HP
# commit only after validation, without temporarily swapping the home shrine state.
func service_view(record: Dictionary) -> GameState:
	var view := GameState.new()
	view.balance = game.state.balance.duplicate(true)
	view.inventory = game.state.inventory.duplicate()
	view.equipment = game.state.equipment.duplicate()
	view.health = game.state.health
	view.level = int(record.level)
	view.satisfaction = record.satisfaction
	view.balance.recipes.ingot_from_ore.satisfaction *= config.types[record.biome].smelt_multiplier
	return view

func service(id: String, recipe: String) -> bool:
	var record := get_record(id)
	if record.is_empty() or record.owner!="player" or not near_record(record) or game.paused or game.feed_lock>0: return false
	var arrival: Variant = null
	if recipe=="stone_golem":
		if game.combat.defenders().size()>=game.state.balance.defense.combat.max_golems:
			game.hud.notice.text = "Defender limit reached."
			return false
		arrival = safe_arrival(record)
		if arrival==null: return false
	var view := service_view(record)
	var result := view.try_service(recipe)
	if not result.ok:
		game.hud.notice.text = result.message
		return false
	if recipe=="stone_golem":
		var defender: CombatUnit = game.combat.add_unit("golem",arrival)
		defender.base_id = id
	game.state.inventory = view.inventory
	game.state.equipment = view.equipment
	game.state.health = view.health
	records[id].level = view.level
	records[id].satisfaction = view.satisfaction
	game.feed_lock = game.state.balance.runtime.service_cooldown
	nodes[id].pulse = 1
	game.update_equipment()
	game.state.changed.emit()
	game.save_game(false)
	return true

func refresh() -> void:
	for child in actions.get_children():
		actions.remove_child(child)
		child.queue_free()
	var record := get_record(selected)
	if record.is_empty():
		details.text = "Territory\nDiscovered living shrines"
		for entry in all_records():
			if not entry.discovered: continue
			game.hud.button(actions,"%s · %s · (%d, %d)\nLevel %d · Satisfaction %.0f / %d" % [config.types[entry.biome].name,entry.owner,entry.position[0],entry.position[2],entry.level,entry.satisfaction,cap(entry)],func(): inspect(entry.id))
		return
	details.text = "%s · %s\n%s · Level %d\nSatisfaction %.0f / %d" % [config.types[record.biome].name,record.biome.capitalize(),record.owner.capitalize(),record.level,record.satisfaction,cap(record)]
	if record.id!=game.shrine.persistent_id:
		var structures := 0
		var defenders := 0
		for structure in game.buildings.structures:
			if structure.base_id==record.id: structures += 1
		for defender in game.combat.defenders():
			if defender.base_id==record.id: defenders += 1
		details.text += "\n%d structures · %d defenders" % [structures,defenders]
	if record.has("threat"):
		details.text += "\nTerritory: %s · %ds" % [record.threat,ceili(record.threat_timer)]
		if record.owner=="contested": details.text += " · Capture %.1fs" % record.enemy_capture
	if record.owner=="player":
		for destination in all_records():
			if destination.id==record.id or not destination.discovered or destination.owner!="player" or not destination.activated: continue
			var label := "%s · %s · %.0f Satisfaction\nTravel: %d here + %d there" % [config.types[destination.biome].name,destination.biome,destination.satisfaction,config.travel_source_cost,config.travel_destination_cost]
			var button: Button = game.hud.button(actions,label,func(): begin_travel(record.id,destination.id))
			button.disabled = not travel_error(record.id,destination.id).is_empty() or not travel_pending.is_empty()
			button.tooltip_text = travel_error(record.id,destination.id)
	if record.owner!="player":
		details.text += "\n%s · %.1f / %ds" % ["Reclaim" if record.ever_owned else "Claim: "+game.buildings.cost_text(config.capture_inputs),record.capture,config.capture_seconds]
		game.hud.button(actions,"Reclaim shrine" if record.ever_owned else "Claim shrine",func(): begin_capture(selected))
	elif record.id!=game.shrine.persistent_id:
		game.hud.button(actions,"Feed · 1 raw meat",func(): feed(selected))
		var view := service_view(record)
		for recipe in game.state.balance.progression.w2_recipes+["stone_golem","heal","level_up"]:
			var quote := view.quote(recipe)
			var cost := ""
			for item in quote.spec.inputs: cost += "%d %s · " % [quote.spec.inputs[item],item.replace("_"," ")]
			var button: Button = game.hud.button(actions,"%s\n%s%.0f Satisfaction" % [quote.spec.name,cost,quote.spec.satisfaction],func(): service(selected,recipe))
			button.disabled = not quote.ok or not near_record(record)
			button.tooltip_text = quote.message
	game.hud.button(actions,"All territories",func(): selected=""; refresh())

func serialize() -> Dictionary:
	for id in nodes: snapshot_guards(id)
	return {"records":records.duplicate(true)}

func validate(data: Variant) -> String:
	if not data is Dictionary or not data.get("records") is Dictionary or data.records.size()>300: return "Invalid creature registry."
	for id in data.records:
		if not id is String: return "Invalid creature ID."
		var record: Variant = data.records[id]
		if not record is Dictionary or not SaveStore.valid_position(record.get("position")): return "Invalid creature position."
		var site: Dictionary = game.frontier.layout.creature_site(WorldLayout.chunk(point(record)))
		if site.is_empty() or id!=site.id or record.get("id")!=id or record.get("biome")!=site.biome or point(record)!=point(site): return "Creature identity mismatch."
		if record.get("owner") not in ["neutral","npc","player","contested"] or not record.get("discovered") is bool or not record.get("activated") is bool: return "Invalid creature ownership."
		if not GameState.whole_number(record.get("level")) or record.level<1 or record.level>5: return "Invalid creature level."
		for key in ["satisfaction","capture"]:
			if not (record.get(key) is float or record.get(key) is int) or not is_finite(float(record[key])) or record[key]<0: return "Invalid creature value."
		if record.satisfaction>cap(record) or record.capture>config.capture_seconds: return "Creature value exceeds limits."
		if record.owner=="player" and (not record.discovered or not record.activated): return "Incomplete creature claim."
		if not record.get("guards") is Array or record.guards.size()>2: return "Invalid territorial guards."
		var guard_data: Dictionary = game.combat.fresh_data()
		guard_data.merge({"phase":"occupied","units":record.guards,"next_id":3},true)
		var guard_error: String = game.combat.validate_data(guard_data,{"structures":[]})
		if not guard_error.is_empty(): return guard_error
		for guard in record.guards:
			if guard.kind!="raider" or guard.scout or Vector3(guard.position[0],0,guard.position[2]).distance_to(point(record))>18 or Vector3(guard.position[0],0,guard.position[2]).distance_to(point(record))<2.23 or Vector3(guard.home[0],0,guard.home[2]).distance_to(point(record))>8: return "Invalid territorial guard."
		if record.owner=="player" and not record.guards.is_empty(): return "Owned shrine has hostile guards."
		var channel: Variant = record.get("enemy_capture",0.0)
		if not (channel is int or channel is float) or not is_finite(float(channel)) or channel<0 or channel>game.state.balance.defense.capture_channel_seconds: return "Invalid territory capture."
		if not record.get("ever_owned") is bool or record.get("threat") not in ["stable","warning","contested","occupied"]: return "Invalid territory condition."
		if not (record.get("threat_timer") is int or record.get("threat_timer") is float) or not is_finite(float(record.threat_timer)) or record.threat_timer<0 or record.threat_timer>config.raid_interval: return "Invalid territory timer."
		if record.owner=="contested" and (record.threat!="contested" or not record.ever_owned): return "Invalid territory contest."
		if record.owner=="player" and not record.ever_owned: return "Invalid territory history."
	return ""

func restore(data: Dictionary) -> void:
	recall_destination = ""
	close()
	travel_pending = ""
	travel_source = ""
	for id in nodes.keys(): unload_site(WorldLayout.chunk(nodes[id].position))
	records = data.records.duplicate(true)
	for record in records.values(): record.enemy_capture = record.get("enemy_capture",0.0)
func travel_error(source_id: String, destination_id: String) -> String:
	var source := get_record(source_id)
	var destination := get_record(destination_id)
	if source.is_empty() or destination.is_empty() or source_id==destination_id: return "Choose another shrine."
	for record in [source,destination]:
		if record.owner!="player" or not record.discovered or not record.activated: return "Both shrines must be claimed and active."
	if game.paused or game.feed_lock>0 or game.state.health<=0 or not near_record(source): return "Approach the departure shrine."
	for unit in game.combat.hostiles(true):
		if unit.position.distance_to(game.hero.position)<12: return "Clear nearby enemies before travel."
	if source.satisfaction<config.travel_source_cost or destination.satisfaction<config.travel_destination_cost: return "Insufficient Satisfaction at one or both shrines."
	return ""

func begin_travel(source_id: String, destination_id: String) -> bool:
	var error := travel_error(source_id,destination_id)
	if not error.is_empty() or not travel_pending.is_empty():
		game.hud.notice.text = error
		return false
	game.cancel()
	travel_pending = destination_id
	travel_source = source_id
	travel_elapsed = 0
	game.frontier.center = Vector2i(999,999)
	game.frontier.update_chunks()
	game.hud.notice.text = "Preparing destination. Right-click to cancel."
	return true

func pinned_chunks() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if travel_pending.is_empty() and recall_destination.is_empty(): return result
	var record := get_record(recall_destination if not recall_destination.is_empty() else travel_pending)
	if record.is_empty(): return result
	var cell := WorldLayout.chunk(point(record))
	for x in range(-1,2):
		for z in range(-1,2): result.append(cell+Vector2i(x,z))
	return result

func safe_arrival(record: Dictionary) -> Variant:
	var cell := WorldLayout.chunk(point(record))
	if record.id!=game.shrine.persistent_id and (not game.frontier.chunks.has(cell) or not game.frontier.chunks[cell].ready): return null
	for i in 16:
		var angle := i*TAU/16
		var at := point(record)+Vector3(sin(angle),0,cos(angle))*4.8
		if i==0 and record.id==game.shrine.persistent_id: at = Vector3(0,0,5)
		var query := PhysicsShapeQueryParameters3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.45
		query.shape = shape
		query.transform.origin = at+Vector3.UP*0.55
		query.collision_mask = 18
		if game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(): return at
	return null

func advance_travel(delta: float) -> void:
	travel_elapsed += delta
	var error := travel_error(travel_source,travel_pending)
	if not error.is_empty() or travel_elapsed>30:
		close()
		game.hud.notice.text = error if not error.is_empty() else "Destination unavailable. Travel cancelled."
		return
	var arrival: Variant = safe_arrival(get_record(travel_pending))
	if arrival == null: return
	# Validate again after asynchronous streaming, then commit both costs and arrival
	# together. Pending travel is transient; saves before this point pay nothing.
	var source := get_record(travel_source)
	var destination := get_record(travel_pending)
	set_satisfaction(source.id,source.satisfaction-config.travel_source_cost)
	set_satisfaction(destination.id,destination.satisfaction-config.travel_destination_cost)
	game.cancel()
	game.hero.position = arrival
	game.hero.velocity = Vector3.ZERO
	game.expedition.bond = minf(game.expedition.bond,bond_capacity(destination))
	game.expedition.grace = game.state.balance.expedition_bond.empty_warning_seconds
	game.occlusion.reset()
	game.frontier.center = Vector2i(999,999)
	game.frontier.update_chunks()
	var ring := Sculpt.torus(game,arrival+Vector3.UP*0.2,0.8,0.06,Sculpt.mat("bb8e9a",0.5,0,0.3))
	var motion := game.create_tween().set_parallel(true)
	motion.tween_property(ring,"scale",Vector3.ONE*0.05,0.8)
	motion.tween_property(ring,"position:y",1.8,0.8)
	motion.chain().tween_callback(ring.queue_free)
	game.state.changed.emit()
	game.hud.notice.text = "Arrived at "+config.types[destination.biome].name+"."
	game.save_game(false)

func snapshot_guards(id: String) -> void:
	if not records.has(id): return
	records[id].guards = []
	for unit in game.combat.units:
		if unit.territory_id==id: records[id].guards.append(unit.serialize())

func park_guards(id: String) -> void:
	snapshot_guards(id)
	for unit in game.combat.units.duplicate():
		if unit.territory_id==id: game.combat.remove_unit(unit)

func make_guards(record: Dictionary) -> void:
	record.guards = []
	for i in 2:
		var at := guard_arrival(record,i)
		var guard_home := point(record)+Vector3(-3.2 if i==0 else 3.2,0,2.2)
		var data := {"id":i+1,"kind":"raider","health":game.state.balance.defense.combat.units.raider.health,"position":[at.x,0,at.z],"home":[guard_home.x,0,guard_home.z],"scout":false,"cooldown":0.0}
		record.guards.append(data)
		if nodes.has(record.id):
			var unit: CombatUnit = game.combat.restore_unit(data)
			unit.territory_id = record.id

func advance_territories(delta: float) -> void:
	var changed := false
	for id in records:
		var record: Dictionary = records[id]
		if record.owner not in ["player","contested"]: continue
		record.threat_timer = maxf(0,record.threat_timer-delta)
		if record.owner=="player":
			if record.threat_timer<=config.raid_warning and record.threat=="stable":
				record.threat = "warning"
				game.hud.notice.text = config.types[record.biome].name+": raid approaching."
				changed = true
			if record.threat_timer<=0:
				record.owner = "contested"
				record.threat = "contested"
				record.enemy_capture = 0.0
				record.threat_timer = config.contest_seconds
				make_guards(record)
				if nodes.has(id): nodes[id].pulse = 1
				game.hud.notice.text = config.types[record.biome].name+": under attack."
				changed = true
			continue
		var victory := false
		if nodes.has(id):
			snapshot_guards(id)
			victory = record.guards.is_empty()
			var channeling := false
			for unit in game.combat.units:
				if unit.territory_id==id and unit.hit<=0 and unit.position.distance_to(point(record))<=3.6: channeling = true
			record.enemy_capture = minf(game.state.balance.defense.capture_channel_seconds,record.enemy_capture+delta) if channeling else 0.0
			if record.enemy_capture>=game.state.balance.defense.capture_channel_seconds:
				record.threat_timer = 0
			elif record.threat_timer<=0:
				# Raiders which never reach the shrine withdraw; walls genuinely defend it.
				victory = true
		elif record.threat_timer<=0:
			# Bounded strategic resolution; no actors or paths are spawned offscreen.
			var strength := 0.0
			for defender in game.combat.defenders():
				if defender.base_id==id: strength += defender.health/60.0
			for structure in game.buildings.structures:
				if structure.base_id==id and structure.kind=="palisade": strength += structure.health/150.0
			victory = strength>=2.0
			if victory:
				for defender in game.combat.defenders():
					if defender.base_id==id: defender.health = maxf(1,defender.health-25)
				for structure in game.buildings.structures:
					if structure.base_id==id: structure.health = maxf(1,structure.health-20); structure.update_damage()
		if victory:
			for unit in game.combat.units.duplicate():
				if unit.territory_id==id: game.combat.remove_unit(unit)
			record.enemy_capture = 0.0
			record.merge({"owner":"player","threat":"stable","threat_timer":config.raid_interval,"guards":[]},true)
			game.hud.notice.text = config.types[record.biome].name+": defended."
			changed = true
		elif record.threat_timer<=0:
			record.owner = "npc"
			record.enemy_capture = 0.0
			record.activated = false
			record.threat = "occupied"
			game.hud.notice.text = config.types[record.biome].name+": occupied. Defeat the guards to reclaim it."
			changed = true
	if changed: game.save_game(false)

func guard_arrival(record: Dictionary, side: int) -> Vector3:
	for i in 24:
		var angle := (i+side*12)*TAU/24
		var at := point(record)+Vector3(sin(angle),0,cos(angle))*12
		var clear := true
		for entry in game.frontier.layout.descriptors(WorldLayout.chunk(at)):
			if entry.kind!="hare" and at.distance_to(entry.position)<1.2: clear = false
		for structure in game.buildings.structures:
			if at.distance_to(structure.position)<structure.radius+0.4: clear = false
		if clear: return at
	return point(record)+Vector3(-3.2 if side==0 else 3.2,0,2.2)
