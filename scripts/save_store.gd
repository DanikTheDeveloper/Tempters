class_name SaveStore
extends RefCounted

static func snapshot(game: Node) -> Dictionary:
	var world := []
	for node in game.targets:
		world.append({"id":node.persistent_id,"position":[node.position.x,0,node.position.z],"depleted":node.depleted,"remaining":maxf(0,node.remaining) if node.depleted else 0.0})
	return {"version":1,"seed":game.state.balance.world.seed,"owned_shrines":[game.shrine.persistent_id],"character":game.state.serialize(),"position":[game.hero.position.x,0,game.hero.position.z],"world":world}

static func valid_position(p: Variant) -> bool:
	if not p is Array or p.size() != 3: return false
	for n in p:
		if not (n is float or n is int) or not is_finite(float(n)): return false
	return p[1] == 0 and absf(p[0]) <= 16.3 and absf(p[2]) <= 16.3

static func validate(data: Variant, game: Node) -> String:
	if not data is Dictionary: return "Invalid save file."
	if data.get("version") != 1: return "Unsupported save version."
	if data.get("seed") != game.state.balance.world.seed: return "World seed mismatch."
	if data.get("owned_shrines") != [game.shrine.persistent_id]: return "Invalid shrine ownership."
	var error: String = game.state.validate_data(data.get("character"))
	if not error.is_empty(): return error
	if not valid_position(data.get("position")): return "Invalid player position."
	var p := Vector3(data.position[0],0,data.position[2])
	for node in game.targets:
		if node.kind != "hare" and p.distance_to(node.home) < node.radius+0.23: return "Player position is obstructed."
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
	if DirAccess.rename_absolute(path+".tmp",path) != OK: return "Could not replace save file."
	return ""

static func read(path: String, game: Node) -> Dictionary:
	if not FileAccess.file_exists(path): return {"error":"No saved game."}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return {"error":"Malformed save file."}
	var data: Variant = parser.data
	var error := validate(data,game)
	return {"error":error,"data":data}
