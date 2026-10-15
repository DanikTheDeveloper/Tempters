class_name InteractionResolver
extends RefCounted

var game: Node

func _init(owner_game: Node) -> void: game = owner_game

func ground(mouse: Vector2) -> Dictionary:
	var at: Variant = Plane(Vector3.UP,0).intersects_ray(game.camera.project_ray_origin(mouse),game.camera.project_ray_normal(mouse))
	return {"position":at} if at != null else {}

func resolve(mouse: Vector2) -> Dictionary:
	var indicator: CombatUnit = game.occlusion.indicator_at(mouse)
	if is_instance_valid(indicator): return {"collider":indicator,"position":indicator.position}
	var origin: Vector3 = game.camera.project_ray_origin(mouse)
	var query := PhysicsRayQueryParameters3D.create(origin,origin+game.camera.project_ray_normal(mouse)*150,26)
	query.collide_with_areas = true
	# The shrine's collision is for navigation/combat, never the interaction hit area.
	query.exclude = [game.shrine.get_rid()]
	var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		if hit.collider is Area3D: hit.collider = hit.collider.get_parent()
		return hit
	var hotspot: Vector2 = game.camera.unproject_position(game.shrine.position+Vector3(0,0.35,2.3))
	if mouse.distance_to(hotspot) <= 22: return {"collider":game.shrine,"position":game.shrine.position}
	return ground(mouse)
