class_name Expedition
extends Node
var game: Node
var bond := 100.0
var grace := 10.0
var warned := false
func setup(owner_game: Node) -> void:
	game = owner_game
	bond = game.state.bond_cap()
	grace = game.state.balance.expedition_bond.empty_warning_seconds
func tick(delta: float) -> void:
	if game.paused: return
	var cfg: Dictionary = game.state.balance.expedition_bond
	var source: Dictionary = game.creatures.nearest(game.hero.position)
	if source.is_empty(): source = game.creatures.home_record()
	var distance: float = game.hero.position.distance_to(CreatureManager.point(source))
	var cap: float = game.creatures.bond_capacity(source)
	bond = minf(bond,cap)
	if distance <= cfg.core_aura_radius_world_units:
		if source.satisfaction>0 and source.owner=="player": bond = minf(cap,bond+delta*cfg.regen_per_second_near_satisfied_core)
		grace = cfg.empty_warning_seconds
		if game.hud.notice.text.begins_with("Bond depleted."): game.hud.notice.text = "Bond recovering." if game.state.satisfaction>0 and not game.state.services_locked else "Feed and reclaim the shrine to recharge Bond."
	else:
		var biome: String = game.frontier.layout.biome(game.hero.position)
		var rate: float = cfg.base_drain_per_second_outside_aura+maxf(0,distance-cfg.core_aura_radius_world_units)*cfg.extra_drain_per_second_per_world_unit_beyond_aura
		var previous := bond
		bond = maxf(0,bond-delta*rate*cfg.biome_multiplier[biome])
		if bond <= 0:
			var empty_time := delta if previous <= 0 else maxf(0,delta-previous/(rate*cfg.biome_multiplier[biome]))
			grace = maxf(0,grace-empty_time)
			game.hud.notice.text = "Bond depleted. Recall in %ds." % ceili(grace)
			if grace <= 0: recall()
	if bond > 0 and bond < cap*0.2 and not warned:
		warned = true
		game.hud.notice.text = "Bond low. Return to the shrine."
	if bond >= cap*0.25:
		warned = false
		if game.hud.notice.text in ["Bond low. Return to the shrine.","Bond recovering."]: game.hud.notice.text = ""
	game.hud.bond_text.text = "Expedition Bond %.0f / %d%s" % [bond,cap," · Recall %ds" % ceili(grace) if bond<=0 and distance>cfg.core_aura_radius_world_units else ""]
func recall() -> void:
	var source: Dictionary = game.creatures.nearest(game.hero.position)
	var arrival: Variant = game.creatures.safe_arrival(source) if not source.is_empty() else Vector3(0,0,5)
	if arrival == null:
		if game.creatures.recall_destination != source.id:
			game.creatures.recall_destination = source.id
			game.frontier.center = Vector2i(999,999)
			game.frontier.update_chunks()
		return
	game.creatures.recall_destination = ""
	game.cancel()
	if game.ritual != null and game.ritual.is_running(): game.ritual.kill()
	game.hero.model.root.scale = Vector3.ONE*1.15
	game.hero.position = arrival
	game.hero.velocity = Vector3.ZERO
	game.hero.set_physics_process(true)
	game.feed_lock = 0
	game.hud.busy = false
	game.hud.inventory_panel.hide()
	game.state.health = maxf(1,minf(game.state.health,25))
	for item in game.state.inventory: game.state.inventory[item] -= floori(game.state.inventory[item]*game.state.balance.expedition_bond.recall_loss_fraction_of_unbanked_inventory)
	bond = (game.creatures.bond_capacity(source) if not source.is_empty() else game.state.bond_cap())*0.25
	grace = game.state.balance.expedition_bond.empty_warning_seconds
	game.combat.immunity = game.state.balance.defense.combat.rescue_immunity
	game.occlusion.reset()
	game.frontier.update_chunks()
	game.state.changed.emit()
	game.hud.notice.text = "Recalled to the shrine. Some carried resources were lost."
	game.save_game(false)
func serialize() -> Dictionary: return {"bond":bond,"grace":grace}
func restore(data: Dictionary) -> void:
	bond = data.bond
	grace = data.grace
	warned = false
func validate(data: Variant, level: int, maximum := 0.0) -> String:
	if not data is Dictionary: return "Missing Expedition Bond."
	for key in ["bond","grace"]:
		if not (data.get(key) is int or data.get(key) is float) or not is_finite(float(data[key])) or data[key]<0: return "Invalid Expedition Bond."
	var cfg: Dictionary = game.state.balance.expedition_bond
	if data.bond > maxf(maximum,cfg.initial_max+(level-1)*cfg.max_bonus_per_core_level) or data.grace>cfg.empty_warning_seconds: return "Expedition Bond exceeds limits."
	return ""
