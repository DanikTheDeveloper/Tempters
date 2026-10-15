class_name SaveStore
extends RefCounted

static func snapshot(game: Node) -> Dictionary:
	var world := []
	for node in game.targets:
		world.append({"id":node.persistent_id,"position":[node.position.x,0,node.position.z],"depleted":node.depleted,"remaining":maxf(0,node.remaining) if node.depleted else 0.0})
	return {"version":5,"territory":game.creatures.serialize(),"exploration":game.frontier.serialize(),"expedition":game.expedition.serialize(),"seed":game.state.balance.world.seed,"owned_shrines":[] if game.combat.phase == "occupied" else [game.shrine.persistent_id],"character":game.state.serialize(),"position":[game.hero.position.x,0,game.hero.position.z],"world":world,"buildings":game.buildings.serialize(),"combat":game.combat.serialize()}

static func valid_position(p: Variant) -> bool:
	if not p is Array or p.size() != 3: return false
	for n in p:
		if not (n is float or n is int) or not is_finite(float(n)): return false
	return p[1] == 0 and absf(p[0]) <= WorldLayout.LIMIT and absf(p[2]) <= WorldLayout.LIMIT

static func validate(data: Variant, game: Node) -> String:
	if not data is Dictionary: return "Invalid save file."
	if not GameState.whole_number(data.get("version")) or data.version < 1 or data.version > 5: return "Unsupported save version."
	if data.get("seed") != game.state.balance.world.seed: return "World seed mismatch."
	var occupied: bool = data.version >= 3 and data.get("combat") is Dictionary and data.combat.get("phase") == "occupied"
	if data.get("owned_shrines") != ([] if occupied else [game.shrine.persistent_id]): return "Invalid shrine ownership."
	var highest_level := 0
	if data.version >= 5:
		var registry_error: String = game.creatures.validate(data.get("territory"))
		if not registry_error.is_empty(): return registry_error
		for record in data.territory.records.values(): highest_level = maxi(highest_level,int(record.level))
	var error: String = game.state.validate_data(data.get("character"),highest_level)
	if not error.is_empty(): return error
	if not valid_position(data.get("position")): return "Invalid player position."
	var p := Vector3(data.position[0],0,data.position[2])
	if data.version<4 and maxf(absf(p.x),absf(p.z))>16.3: return "Invalid player position."
	for node in game.targets:
		if node.kind != "hare" and p.distance_to(node.home) < node.radius+0.23: return "Player position is obstructed."
	if data.version >= 4 and maxf(absf(p.x),absf(p.z))>20:
		var cell := WorldLayout.chunk(p)
		if cell != Vector2i.ZERO and game.frontier.layout.creature_site(cell).is_empty():
			for side in [-1,1]:
				if p.distance_to(game.frontier.layout.landmark(cell)+Vector3(side*1.6,0,0))<0.83: return "Player position is obstructed."
		var site: Dictionary = game.frontier.layout.creature_site(cell)
		if not site.is_empty() and p.distance_to(CreatureManager.point(site))<2.23: return "Player position is obstructed."
		for entry in game.frontier.layout.descriptors(cell):
			if entry.kind != "hare" and p.distance_to(entry.position)<(0.65 if entry.kind=="pine" else 0.85)+0.23: return "Player position is obstructed."
	if not data.get("world") is Array or data.world.size() != game.targets.size(): return "Incomplete world data."
	var seen := {}
	for entry in data.world:
		if not entry is Dictionary or not entry.get("id") is String: return "Invalid world entry."
		if seen.has(entry.id) or not valid_position(entry.get("position")) or not entry.get("depleted") is bool: return "Invalid world entry."
		seen[entry.id] = true
		var match_node: Node = null
		for node in game.targets:
			if node.persistent_id == entry.id: match_node = node
		if match_node == null: return "Unknown world entry."
		var position := Vector3(entry.position[0],0,entry.position[2])
		if position.distance_to(match_node.home) > (2.01 if match_node.kind == "hare" else 0.001): return "Invalid resource position."
		var timer: Variant = entry.get("remaining")
		var limit: float = game.state.balance.runtime.prey_renew_seconds if match_node.kind == "hare" else game.state.balance.runtime.resource_renew_seconds
		if not (timer is int or timer is float) or not is_finite(float(timer)) or timer < 0 or timer > limit: return "Invalid resource timer."
		if (entry.depleted and timer <= 0) or (not entry.depleted and timer != 0) or (match_node.kind == "shrine" and entry.depleted): return "Invalid resource state."
	if data.version >= 2:
		error = game.buildings.validate_data(data.get("buildings"),p,data.territory.records if data.version>=5 else {})
		if not error.is_empty(): return error
	if data.version >= 3:
		error = game.combat.validate_data(data.get("combat"),data.buildings,data.territory.records if data.version>=5 else {})
		if not error.is_empty(): return error
	if data.version >= 4:
		error = game.frontier.validate(data.get("exploration"))
		if not error.is_empty(): return error
		var maximum := 0.0
		if data.version>=5:
			for record in data.territory.records.values(): maximum = maxf(maximum,game.creatures.bond_capacity(record))
		return game.expedition.validate(data.get("expedition"),int(data.character.level),maximum)
	return ""

static func write(path: String, game: Node) -> String:
	var data := snapshot(game)
	var error := validate(data,game)
	if not error.is_empty(): return error
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null: return "Could not open save file."
	file.store_string(JSON.stringify(data))
	file.flush()
	var status := file.get_error()
	file.close()
	if status != OK: return "Could not write save file."
	if FileAccess.file_exists(path):
		var previous := JSON.new()
		var valid := previous.parse(FileAccess.get_file_as_string(path)) == OK
		if valid: valid = validate(previous.data,game).is_empty()
		if valid:
			if DirAccess.copy_absolute(path,path+".previous.tmp") != OK or DirAccess.rename_absolute(path+".previous.tmp",path+".previous") != OK: return "Could not preserve previous save."
		else:
			var backup := preserve(path,"rejected")
			if not backup.error.is_empty(): return backup.error
	if DirAccess.rename_absolute(path+".tmp",path) != OK: return "Could not replace save file."
	return ""

static func preserve(path: String, reason: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"error":"","path":""}
	var backup := path+"."+reason+"-"+str(int(Time.get_unix_time_from_system()))+"-"+str(Time.get_ticks_usec())+".json"
	if DirAccess.copy_absolute(path,backup) != OK: return {"error":"Could not back up the existing save.","path":""}
	return {"error":"","path":backup}

static func read(path: String, game: Node) -> Dictionary:
	if not FileAccess.file_exists(path): return {"error":"No saved game."}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return {"error":"Malformed save file."}
	var data: Variant = parser.data
	var error := validate(data,game)
	var repaired := false
	if error in ["Invalid player position.","Player position is obstructed.","Player overlaps a structure.","Structures block resource access."]:
		# The southern approach is protected from construction. Relocate only the
		# player; never discard inventory, structures or progression to repair a spawn.
		var candidate: Dictionary = data.duplicate(true)
		candidate.position = [0,0,5]
		if validate(candidate,game).is_empty():
			data = candidate
			error = ""
			repaired = true
	if error.is_empty() and data.version == 1:
		data.version = 2
		data.buildings = {"next_id":1,"structures":[]}
	if error.is_empty() and data.version == 2:
		data.version = 3
		data.combat = game.combat.fresh_data()
	if error.is_empty() and data.version == 3:
		data.version = 4
		data.exploration = {"generator":1,"changes":{},"explored":[],"landmarks":[]}
		var cfg: Dictionary = game.state.balance.expedition_bond
		data.expedition = {"bond":cfg.initial_max+(data.character.level-1)*cfg.max_bonus_per_core_level,"grace":cfg.empty_warning_seconds}
	if error.is_empty() and data.version == 4:
		data.version = 5
		data.territory = {"records":{}}
	return {"error":error,"data":data,"repaired":repaired}
