class_name GridNavigation
extends RefCounted

const STEP := 0.65
const HALF := 25
var grid := AStarGrid2D.new()
var external_route := Callable()
var obstacles: Array[Vector3] = []

func _init(region := Rect2i(-HALF,-HALF,HALF*2+1,HALF*2+1)) -> void:
	grid.region = region
	grid.cell_size = Vector2.ONE * STEP
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.update()

func block(pos: Vector3, radius: float) -> void:
	obstacles.append(Vector3(pos.x, radius, pos.z))
	for x in range(maxi(grid.region.position.x,floori((pos.x-radius-0.48)/STEP)),mini(grid.region.end.x,ceili((pos.x+radius+0.48)/STEP)+1)):
		for y in range(maxi(grid.region.position.y,floori((pos.z-radius-0.48)/STEP)),mini(grid.region.end.y,ceili((pos.z+radius+0.48)/STEP)+1)):
			if Vector2(x * STEP, y * STEP).distance_to(Vector2(pos.x, pos.z)) < radius + 0.48:
				grid.set_point_solid(Vector2i(x,y))

func cell(pos: Vector3) -> Vector2i:
	return Vector2i(clampi(roundi(pos.x / STEP),grid.region.position.x,grid.region.end.x-1), clampi(roundi(pos.z / STEP),grid.region.position.y,grid.region.end.y-1))

func point(id: Vector2i) -> Vector3:
	return Vector3(id.x * STEP, 0, id.y * STEP)

func nearest(pos: Vector3) -> Vector2i:
	var center := cell(pos)
	var best := center
	var distance := INF
	for x in range(-7,8):
		for y in range(-7,8):
			var candidate := center + Vector2i(x,y)
			if grid.is_in_boundsv(candidate) and not grid.is_point_solid(candidate):
				var d := point(candidate).distance_squared_to(pos)
				if d < distance:
					distance = d
					best = candidate
	return best

func route(from: Vector3, to: Vector3, reach := 0.0) -> PackedVector3Array:
	if external_route.is_valid() and (maxf(absf(from.x),absf(from.z))>16 or maxf(absf(to.x),absf(to.z))>16): return external_route.call(from,to,reach)
	var start := nearest(from)
	var finish := nearest(to)
	if reach > 0:
		var best := INF
		for x in range(-6,7):
			for y in range(-6,7):
				var candidate := cell(to) + Vector2i(x,y)
				if not grid.is_in_boundsv(candidate) or grid.is_point_solid(candidate): continue
				if point(candidate).distance_to(to) > reach: continue
				var score := point(candidate).distance_squared_to(from)
				if score < best and not grid.get_id_path(start, candidate).is_empty():
					best = score
					finish = candidate
	var result := PackedVector3Array()
	for id in grid.get_id_path(start, finish):
		result.append(point(id))
	return result

