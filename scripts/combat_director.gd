class_name CombatDirector
extends Node3D

var game: Node
var config: Dictionary
var units: Array[CombatUnit] = []
var next_id := 1
var phase := "peace"
var timer := 360.0
var wave := 0
var capture_progress := 0.0
var reclaim_progress := 0.0
var reclaiming := false
var pending_reward := 0
var immunity := 0.0
var player_cooldown := 0.0
var attack_target: CombatUnit
var deploying: CombatUnit
var banner: Node3D
var status: Label
var reclaim_button: Button

func setup(owner_game: Node) -> void:
	game = owner_game
	config = game.state.balance.defense.combat
	timer = game.state.balance.defense.first_raid_min_time_seconds
	status = game.hud.text(game.hud,"",13,Color("d6b18a"))
	status.position = Vector2(490,22)
	status.size = Vector2(360,70)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backdrop := StyleBoxFlat.new()
	backdrop.bg_color = Color("202e2b",0.92)
	backdrop.set_content_margin_all(8)
	status.add_theme_stylebox_override("normal",backdrop)
	var box: Node = game.hud.menu.get_child(0)
	reclaim_button = game.hud.button(box,"Reclaim shrine / 10s",func(): reclaiming = true)
	reclaim_button.hide()
	banner = CombatArt.banner(self)
	banner.position = Vector3(-2.7,0,0)
	banner.hide()

func clear_orders() -> void:
	if is_instance_valid(attack_target): game.hero.working = false
	attack_target = null
	deploying = null
	reclaiming = false
	reclaim_progress = 0

func hostiles(include_scouts := false) -> Array[CombatUnit]:
	var result: Array[CombatUnit] = []
	for unit in units:
		if unit.kind == "raider" and (include_scouts or not unit.scout): result.append(unit)
	return result

func defenders() -> Array[CombatUnit]:
	var result: Array[CombatUnit] = []
	for unit in units:
		if unit.kind == "golem": result.append(unit)
	return result

func add_unit(kind: String, at: Vector3, scout := false) -> CombatUnit:
	var health: float = config.units[kind].health+(minf(wave,config.max_wave_bonus)*config.health_per_wave if kind == "raider" else 0)
	var data := {"id":next_id,"kind":kind,"health":health,"position":[at.x,0,at.z],"home":[at.x,0,at.z],"scout":scout,"cooldown":0}
	next_id += 1
	return restore_unit(data)

func restore_unit(data: Dictionary) -> CombatUnit:
	var unit := CombatUnit.new()
	add_child(unit)
	unit.setup(data,config,wave)
	units.append(unit)
	return unit

func summon() -> bool:
	if game.paused or game.feed_lock > 0: return false
	if game.hero.position.distance_to(game.shrine.position) > game.reach(game.shrine)+0.3:
		game.hud.notice.text = "Approach the shrine to summon."
		return false
	if defenders().size() >= config.max_golems:
		game.hud.notice.text = "Defender limit reached."
		return false
	var spawn := Vector3(3.5 if defenders().size()%2 == 0 else -3.5,0,1)
	spawn = game.navigation.point(game.navigation.nearest(spawn))
	var result: Dictionary = game.state.try_service("stone_golem")
	if not result.ok:
		game.hud.notice.text = result.message
		return false
	add_unit("golem",spawn)
	game.feed_lock = game.state.balance.runtime.service_cooldown
	game.shrine.pulse = 1
	game.hud.notice.text = "Golem summoned. Click it to set a guard position."
	game.save_game(false)
	return true

func select(unit: CombatUnit) -> void:
	if unit.kind == "golem":
		deploying = unit
		game.hud.hint.text = "Click ground within the shrine's defense radius to set guard position."
	else:
		attack_target = unit
		game.hud.hint.text = "Attack raider"

func deploy(at: Vector3) -> void:
	if not is_instance_valid(deploying): return
	if at.distance_to(game.shrine.position) > config.defense_radius:
		game.hud.notice.text = "Guard position is outside the defense radius."
		return
	deploying.home = game.navigation.point(game.navigation.nearest(at))
	deploying.repath = 0
	deploying = null
	game.save_game(false)

func player_reach() -> float:
	return config.spear_reach if game.state.equipment.has("spear") else config.player_reach

func player_damage() -> float:
	if game.state.equipment.has("spear"): return config.spear_damage
	if game.state.equipment.has("tempered_axe"): return config.iron_axe_damage
	return config.player_damage

func can_hit(from: Vector3, to: Vector3, object: Object) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from+Vector3.UP*0.8,to+Vector3.UP*0.8,2)
	var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == object

func route(unit: CombatUnit, at: Vector3, reach: float) -> void:
	if unit.repath > 0: return
	unit.repath = 0.7
	unit.path = game.navigation.route(unit.position,at,reach)

func hit_unit(unit: CombatUnit, amount: float) -> void:
	if not units.has(unit): return
	unit.health = maxf(0,unit.health-amount)
	unit.hit = 0.25
	if unit.kind == "raider" and unit.position.distance_to(game.shrine.position) < 3.6: capture_progress = 0
	game.popup("−%d" % amount,unit.position+Vector3.UP*2)
	if unit.health <= 0: remove_unit(unit)

func remove_unit(unit: CombatUnit) -> void:
	if not units.has(unit): return
	if attack_target == unit:
		attack_target = null
		game.hero.path.clear()
		game.hero.working = false
	if deploying == unit: deploying = null
	units.erase(unit)
	unit.collision_layer = 0
	remove_child(unit)
	unit.queue_free()

func hurt_player(amount: float) -> void:
	if immunity > 0: return
	var reduction := 0.65 if game.state.equipment.has("reinforced_armor") else 0.8 if game.state.equipment.has("hide_armor") else 1.0
	game.state.health = maxf(0,game.state.health-amount*reduction)
	reclaim_progress = 0
	game.popup("−%d Health" % ceili(amount*reduction),game.hero.position+Vector3.UP*1.8)
	if game.state.health <= 0: rescue()
	game.state.changed.emit()

func rescue() -> void:
	game.cancel()
	game.hero.position = Vector3(0,0,5)
	game.hero.velocity = Vector3.ZERO
	game.state.health = minf(game.state.max_health(),config.rescue_health)
	for item in game.state.inventory: game.state.inventory[item] -= floori(game.state.inventory[item]*0.2)
	immunity = config.rescue_immunity
	game.hud.notice.text = "Rescued. Some carried resources were lost."
	game.save_game(false)

func advance_clock(delta: float) -> void:
	if game.paused: return
	timer = maxf(0,timer-delta)
	if phase == "peace" and timer <= config.warning_seconds:
		phase = "warning"
		add_unit("raider",Vector3(0,0,-13),true)
		game.save_game(false)
	if phase == "warning" and timer <= 0: start_raid()
	if phase == "raid" and timer <= 0:
		for unit in hostiles(true): remove_unit(unit)
	if phase == "occupied" and timer <= 0:
		for unit in hostiles(true): remove_unit(unit)

func start_raid() -> void:
	for scout in hostiles(true): remove_unit(scout)
	phase = "raid"
	timer = config.raid_duration
	wave += 1
	capture_progress = 0
	var count: int = mini(config.max_raiders,int(game.state.balance.defense.first_raid_opponents)+floori((wave-1)/2.0)+floori((game.state.level-1)/2.0))
	for i in count:
		var at := Vector3((i-(count-1)*0.5)*1.3,0,-40)
		add_unit("raider",at)
	game.save_game(false)

func set_occupied(occupied: bool) -> void:
	game.state.services_locked = occupied
	banner.visible = occupied
	game.shrine.pulse = 1
	game.state.changed.emit()

func capture() -> void:
	phase = "occupied"
	timer = config.occupation_seconds
	capture_progress = 0
	set_occupied(true)
	game.hud.notice.text = "Shrine occupied. Defeat the raiders, then reclaim it."
	game.save_game(false)

func reclaim() -> void:
	phase = "peace"
	timer = game.state.balance.defense.minimum_repeat_raid_interval_seconds
	reclaiming = false
	reclaim_progress = 0
	set_occupied(false)
	game.hud.notice.text = "Shrine reclaimed."
	game.save_game(false)

func collect_reward() -> bool:
	if pending_reward <= 0 or game.hero.position.distance_to(game.shrine.position) > game.reach(game.shrine)+0.3: return false
	var amount := mini(pending_reward,int(config.reward_meat))
	if not game.state.collect({"raw_meat":amount}): return false
	pending_reward -= amount
	game.popup("+%d raw meat" % amount,game.hero.position+Vector3.UP*2)
	game.save_game(false)
	return true

func _physics_process(delta: float) -> void:
	if game == null or game.paused: return
	advance_clock(delta)
	immunity = maxf(0,immunity-delta)
	player_cooldown = maxf(0,player_cooldown-delta)
	if game.state.health <= 0: rescue()
	if is_instance_valid(attack_target) and units.has(attack_target):
		var distance: float = game.hero.position.distance_to(attack_target.position)
		if distance <= player_reach() and can_hit(game.hero.position,attack_target.position,attack_target):
			game.hero.path.clear()
			game.hero.working = true
			game.hero.model.root.rotation.y = atan2(attack_target.position.x-game.hero.position.x,attack_target.position.z-game.hero.position.z)
			if player_cooldown <= 0:
				player_cooldown = config.player_cooldown
				hit_unit(attack_target,player_damage())
		else:
			game.hero.working = false
			if game.hero.path.is_empty() or game.repath <= 0:
				game.repath = 0.5
				game.hero.path = game.navigation.route(game.hero.position,attack_target.position,player_reach()*0.85)
	var channeling := false
	for unit in units.duplicate():
		if not units.has(unit): continue
		unit.step(delta)
		if unit.scout: continue
		var victim: Node3D = null
		var best := INF
		if unit.kind == "golem":
			for enemy in hostiles():
				var d: float = unit.position.distance_to(enemy.position)
				if enemy.position.distance_to(game.shrine.position) <= config.defense_radius and d < best:
					victim = enemy
					best = d
		else:
			if immunity <= 0 and unit.position.distance_to(game.hero.position) < 4.5:
				victim = game.hero
				best = unit.position.distance_to(game.hero.position)
			for defender in defenders():
				var d: float = unit.position.distance_to(defender.position)
				if d < 6 and d < best:
					victim = defender
					best = d
			if victim == null:
				for structure in game.buildings.structures:
					var d: float = unit.position.distance_to(structure.position)
					if d < 4 and d < best:
						victim = structure
						best = d
		# Attack a barrier directly shielding a target instead of pursuing through it.
		if unit.kind == "raider" and victim != null and not victim is BaseStructure:
			var ray := PhysicsRayQueryParameters3D.create(unit.position+Vector3.UP*0.8,victim.position+Vector3.UP*0.8,2)
			var obstruction: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(ray)
			if obstruction.get("collider") is BaseStructure:
				victim = obstruction.collider
		if victim != null:
			var reach: float = unit.stats.reach+(victim.radius if victim is BaseStructure else 0)
			if unit.position.distance_to(victim.position) <= reach and can_hit(unit.position,victim.position,victim):
				unit.path.clear()
				unit.model.root.rotation.y = atan2(victim.position.x-unit.position.x,victim.position.z-unit.position.z)
				if unit.cooldown <= 0:
					unit.cooldown = unit.stats.cooldown
					unit.swing = 0.4
					if victim is CombatUnit: hit_unit(victim,unit.stats.damage)
					elif victim is BaseStructure: game.buildings.damage(victim,unit.stats.damage)
					else: hurt_player(unit.stats.damage)
			else: route(unit,victim.position,reach*0.85)
		elif unit.kind == "golem":
			if unit.position.distance_to(unit.home) > 0.4: route(unit,unit.home,0)
		else:
			if unit.position.distance_to(game.shrine.position) <= 3.4:
				unit.path.clear()
				if phase == "raid": channeling = true
			else: route(unit,game.shrine.position,3.2)
	if phase == "raid":
		capture_progress = capture_progress+delta if channeling else 0.0
		if capture_progress >= game.state.balance.defense.capture_channel_seconds: capture()
		elif hostiles().is_empty():
			phase = "peace"
			timer = game.state.balance.defense.minimum_repeat_raid_interval_seconds
			pending_reward += int(config.reward_meat)
			game.state.satisfaction = minf(game.state.cap(),game.state.satisfaction+config.reward_satisfaction)
			game.hud.notice.text = "Raid repelled. Collect supplies at the shrine."
			game.save_game(false)
	if phase == "occupied" and reclaiming:
		if hostiles().is_empty() and game.hero.position.distance_to(game.shrine.position) <= game.reach(game.shrine)+0.3:
			reclaim_progress += delta
			if reclaim_progress >= config.reclaim_seconds: reclaim()
		else: reclaim_progress = 0
	collect_reward()
	refresh()

func refresh() -> void:
	match phase:
		"peace": status.text = "Defenders %d / %d\nNext raid in %ds" % [defenders().size(),config.max_golems,ceili(timer)]
		"warning": status.text = "Scout sighted to the north\nRaid in %ds" % ceili(timer)
		"raid": status.text = "Raid %d · %d enemies\nCapture %.1f / %ds" % [wave,hostiles().size(),capture_progress,game.state.balance.defense.capture_channel_seconds]
		"occupied": status.text = "Shrine occupied · Raiders retreat in %ds\nReclaim %.1f / %ds" % [ceili(timer),reclaim_progress,config.reclaim_seconds]
	if pending_reward > 0: status.text += "\n%d raw meat waiting at shrine" % pending_reward
	reclaim_button.visible = phase == "occupied"
	reclaim_button.disabled = not hostiles().is_empty() or game.paused
	reclaim_button.tooltip_text = "Defeat the raiders or wait for their withdrawal. Feeding and healing remain available."

func serialize() -> Dictionary:
	var actors := []
	for unit in units: actors.append(unit.serialize())
	return {"phase":phase,"timer":timer,"wave":wave,"capture":capture_progress,"reward":pending_reward,"next_id":next_id,"immunity":immunity,"units":actors}

func fresh_data() -> Dictionary:
	return {"phase":"peace","timer":game.state.balance.defense.first_raid_min_time_seconds,"wave":0,"capture":0,"reward":0,"next_id":1,"immunity":0,"units":[]}

func restore(data: Dictionary) -> void:
	clear_orders()
	for unit in units:
		remove_child(unit)
		unit.queue_free()
	units.clear()
	phase = data.phase
	timer = data.timer
	wave = int(data.wave)
	capture_progress = data.capture
	pending_reward = int(data.reward)
	next_id = int(data.next_id)
	immunity = data.immunity
	player_cooldown = 0
	for entry in data.units: restore_unit(entry)
	set_occupied(phase == "occupied")
	refresh()

func validate_data(data: Variant, building_data: Dictionary) -> String:
	if not data is Dictionary: return "Invalid combat state."
	for key in ["phase","timer","wave","capture","reward","next_id","immunity","units"]:
		if not data.has(key): return "Incomplete combat state."
	if data.phase not in ["peace","warning","raid","occupied"]: return "Invalid raid phase."
	for key in ["wave","reward","next_id"]:
		if not GameState.whole_number(data[key]) or data[key] < 0 or data[key] > 1000000: return "Invalid combat count."
	if data.next_id < 1: return "Invalid actor sequence."
	for key in ["timer","capture","immunity"]:
		if not (data[key] is int or data[key] is float) or not is_finite(float(data[key])) or data[key] < 0: return "Invalid combat timer."
	if data.timer > game.state.balance.defense.first_raid_min_time_seconds or data.capture > game.state.balance.defense.capture_channel_seconds or data.immunity > config.rescue_immunity: return "Combat timer exceeds limit."
	if not data.units is Array or data.units.size() > config.max_golems+config.max_raiders+1: return "Invalid unit list."
	var ids := {}
	var golems := 0
	var enemies := 0
	var scouts := 0
	for entry in data.units:
		if not entry is Dictionary: return "Invalid unit."
		for key in ["id","kind","health","position","home","cooldown","scout"]:
			if not entry.has(key): return "Incomplete unit."
		if not GameState.whole_number(entry.id) or entry.id < 1 or entry.id >= data.next_id or ids.has(entry.id): return "Invalid actor ID."
		ids[entry.id] = true
		if entry.kind not in ["golem","raider"] or not entry.scout is bool: return "Invalid actor kind."
		if not SaveStore.valid_position(entry.position) or not SaveStore.valid_position(entry.home): return "Invalid actor position."
		for key in ["health","cooldown"]:
			if not (entry[key] is int or entry[key] is float) or not is_finite(float(entry[key])) or entry[key] < 0: return "Invalid actor value."
		var maximum: float = config.units[entry.kind].health+(minf(data.wave,config.max_wave_bonus)*config.health_per_wave if entry.kind == "raider" else 0)
		if entry.health <= 0 or entry.health > maximum or entry.cooldown > config.units[entry.kind].cooldown: return "Invalid actor health or cooldown."
		var at := Vector3(entry.position[0],0,entry.position[2])
		for node in game.targets:
			if node.kind != "hare" and at.distance_to(node.home) < node.radius+0.23: return "Actor overlaps an obstacle."
		for structure in building_data.structures:
			if at.distance_to(Vector3(structure.position[0],0,structure.position[2])) < game.buildings.config.types[structure.kind].radius+0.23: return "Actor overlaps a structure."
		if entry.kind == "golem":
			golems += 1
			if entry.scout or Vector3(entry.home[0],0,entry.home[2]).distance_to(game.shrine.position) > config.defense_radius+1: return "Invalid guard assignment."
		elif entry.scout: scouts += 1
		else: enemies += 1
	if golems > config.max_golems or enemies > config.max_raiders or scouts > 1: return "Actor limit exceeded."
	if (data.phase == "peace" and enemies+scouts > 0) or (data.phase == "warning" and enemies > 0) or (data.phase in ["raid","occupied"] and scouts > 0): return "Raid actors do not match phase."
	return ""
