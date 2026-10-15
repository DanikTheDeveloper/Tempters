class_name GameState
extends RefCounted

signal changed
var balance: Dictionary
var inventory: Dictionary = {}
var satisfaction: float
var health: float
var offerings := 0
var level := 1
var equipment: Dictionary = {}
var services_locked := false

func _init() -> void:
	balance = JSON.parse_string(FileAccess.get_file_as_string("res://ECONOMY_BALANCE.json"))
	satisfaction = balance.temptress.initial_satisfaction
	health = balance.player.initial_health
	level = int(balance.temptress.initial_level)
	for item in balance.items:
		inventory[item] = 0

func weight(bag: Dictionary = inventory) -> float:
	var result := 0.0
	for item in bag:
		result += bag[item] * balance.items[item].weight
	return result

func slots(bag: Dictionary) -> int:
	var count := 0
	for item in bag:
		count += ceili(float(bag[item]) / balance.items[item].max_stack)
	return count

func collect(items: Dictionary) -> bool:
	var next := inventory.duplicate()
	for item in items:
		if not balance.items.has(item) or not whole_number(items[item]) or items[item] < 0:
			return false
		next[item] += items[item]
	if weight(next) > capacity() or slots(next) > slot_limit():
		return false
	inventory = next
	changed.emit()
	return true

func feed() -> bool:
	if inventory.raw_meat < 1:
		return false
	inventory.raw_meat -= 1
	satisfaction = minf(cap(), satisfaction + balance.temptress.feed_raw_meat_gain)
	offerings += 1
	changed.emit()
	return true

func discard(item: String) -> void:
	if inventory.get(item, 0) > 0:
		inventory[item] -= 1
		changed.emit()

func tick(delta: float) -> void:
	satisfaction = maxf(0.0, satisfaction - delta * drain())
	changed.emit()

func cap() -> float:
	return balance.temptress.max_satisfaction_per_level[level-1]

static func whole_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value))

func capacity(gear: Dictionary = equipment) -> float:
	var total: float = balance.player.base_weight_capacity
	for id in gear: total += balance.equipment[id].get("weight_bonus",0)
	return total

func slot_limit(gear: Dictionary = equipment) -> int:
	var total: int = balance.player.default_inventory_slots
	for id in gear: total += int(balance.equipment[id].get("slot_bonus",0))
	return total

func max_health(gear: Dictionary = equipment) -> float:
	var total: float = balance.player.max_health
	for id in gear: total += balance.equipment[id].get("health_bonus",0)
	return total

func bond_cap() -> float:
	return balance.expedition_bond.initial_max+(level-1)*balance.expedition_bond.max_bonus_per_core_level

func drain() -> float:
	return balance.temptress.passive_drain_per_second*balance.temptress.higher_tier_appetite_multiplier[level-1]

func action_duration(kind: String) -> float:
	var seconds: float = balance.runtime.action_seconds
	for id in equipment:
		var item: Dictionary = balance.equipment[id]
		if item.get("action_kind","") == kind or (kind in ["stone","ore"] and item.get("action_kind","") == "mineral"):
			seconds = minf(seconds,item.action_seconds)
	return seconds

func hunting_reach_bonus() -> float:
	return balance.equipment.spear.reach_bonus if equipment.has("spear") else 0.0

func service_ids() -> Array:
	return balance.progression.w2_recipes + ["stone_golem","heal","level_up"]

func specification(id: String) -> Dictionary:
	if id == "stone_golem":
		var spec: Dictionary = balance.recipes.stone_golem.duplicate(true)
		spec.merge({"name":"Stone golem","required_level":balance.defense.combat.golem_level,"output":{},"description":"Summon a defender. Click it to set a guard position. Maximum %d." % balance.defense.combat.max_golems},true)
		return spec
	if id == "heal":
		return {"name":"Restore Health","inputs":{},"output":{},"satisfaction":balance.services.heal_cost_satisfaction,"required_level":1,"description":"Restore up to %d Health." % balance.services.heal_amount}
	if id == "level_up":
		if level >= balance.temptress.max_satisfaction_per_level.size():
			return {"name":"Shrine level 5","inputs":{},"output":{},"satisfaction":0,"required_level":1,"description":"Maximum shrine level reached."}
		var spec: Dictionary = balance.progression.levels[level-1].duplicate(true)
		spec.merge({"name":"Shrine level %d" % (level+1),"output":{},"required_level":1,"description":"Satisfaction cap %d → %d. Bond cap +%d.\nAppetite ×%.2f. Unlocks new equipment." % [cap(),balance.temptress.max_satisfaction_per_level[level],balance.expedition_bond.max_bonus_per_core_level,balance.temptress.higher_tier_appetite_multiplier[level]]})
		return spec
	if id in balance.progression.w2_recipes: return balance.recipes[id].duplicate(true)
	return {}

func quote(id: String) -> Dictionary:
	var spec := specification(id)
	if spec.is_empty(): return {"ok":false,"message":"Unknown service."}
	var result := {"ok":false,"message":"","spec":spec}
	if services_locked and id != "heal":
		result.message = "Shrine occupied. Reclaim it to restore crafting."
		return result
	if id == "level_up" and level >= 5:
		result.message = "Maximum level reached."
	elif id == "heal" and health >= max_health():
		result.message = "Health is full."
	elif level < spec.required_level:
		result.message = "Requires shrine level %d." % spec.required_level
	elif spec.has("requires_equipment") and not equipment.has(spec.requires_equipment):
		result.message = "Requires %s." % balance.equipment[spec.requires_equipment].name
	for item in spec.output:
		if equipment.has(item): result.message = "Already equipped."
	if not result.message.is_empty(): return result
	if satisfaction <= 0:
		result.message = "Dormant. Feed raw meat first."
		return result
	var shortages := PackedStringArray()
	for item in spec.inputs:
		var missing: int = int(spec.inputs[item])-int(inventory.get(item,0))
		if missing > 0: shortages.append("%d %s" % [missing,item.replace("_"," ")])
	if satisfaction < spec.satisfaction: shortages.append("%.1f Satisfaction" % (spec.satisfaction-satisfaction))
	if not shortages.is_empty():
		result.message = "Need " + ", ".join(shortages) + "."
		return result
	var next := inventory.duplicate()
	var gear := equipment.duplicate()
	for item in spec.inputs: next[item] -= spec.inputs[item]
	for item in spec.output:
		if balance.equipment.has(item): gear[item] = true
		else: next[item] += spec.output[item]
	if weight(next) > capacity(gear) or slots(next) > slot_limit(gear):
		result.message = "Inventory full. Free space before crafting."
		return result
	result.merge({"ok":true,"message":"Ready","inventory":next,"equipment":gear},true)
	return result

func try_service(id: String) -> Dictionary:
	# Quote against current state, then commit the entire result without yielding.
	var result := quote(id)
	if not result.ok: return result
	inventory = result.inventory
	equipment = result.equipment
	satisfaction -= result.spec.satisfaction
	if id == "heal": health = minf(max_health(),health+balance.services.heal_amount)
	if id == "level_up": level += 1
	changed.emit()
	return result

func serialize() -> Dictionary:
	return {"inventory":inventory.duplicate(),"equipment":equipment.duplicate(),"level":level,"health":health,"satisfaction":satisfaction,"offerings":offerings}

func validate_data(data: Variant) -> String:
	if not data is Dictionary: return "Invalid character data."
	for key in ["inventory","equipment","level","health","satisfaction","offerings"]:
		if not data.has(key): return "Missing character data."
	if not whole_number(data.level) or data.level < 1 or data.level > 5: return "Invalid shrine level."
	if not whole_number(data.offerings) or data.offerings < 0: return "Invalid offering count."
	if not data.inventory is Dictionary or not data.equipment is Dictionary: return "Invalid inventory."
	if data.inventory.size() != balance.items.size(): return "Incomplete inventory."
	for item in data.inventory:
		if not balance.items.has(item) or not whole_number(data.inventory[item]) or data.inventory[item] < 0: return "Invalid item count."
	for id in data.equipment:
		if not balance.equipment.has(id) or not data.equipment[id] is bool or data.equipment[id] != true: return "Invalid equipment."
		for recipe_id in balance.progression.w2_recipes:
			var recipe: Dictionary = balance.recipes[recipe_id]
			if recipe.output.has(id):
				if data.level < recipe.required_level: return "Equipment level mismatch."
				if recipe.has("requires_equipment") and not data.equipment.has(recipe.requires_equipment): return "Missing equipment prerequisite."
	for key in ["health","satisfaction"]:
		if not (data[key] is int or data[key] is float) or not is_finite(float(data[key])) or data[key] < 0: return "Invalid character value."
	if data.health > max_health(data.equipment) or data.satisfaction > balance.temptress.max_satisfaction_per_level[int(data.level)-1]: return "Character value exceeds capacity."
	if weight(data.inventory) > capacity(data.equipment) or slots(data.inventory) > slot_limit(data.equipment): return "Inventory exceeds capacity."
	return ""

func restore(data: Dictionary) -> void:
	inventory = data.inventory.duplicate()
	equipment = data.equipment.duplicate()
	level = int(data.level)
	health = float(data.health)
	satisfaction = float(data.satisfaction)
	offerings = int(data.offerings)
	changed.emit()

func mood() -> String:
	if satisfaction <= 0: return "DORMANT"
	if satisfaction < 30: return "FURIOUS"
	if satisfaction < 70: return "IMPATIENT"
	return "CONTENT"

