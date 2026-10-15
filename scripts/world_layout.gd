class_name WorldLayout
extends RefCounted
const CHUNK := 64.0
const LIMIT := 4096.0
var seed_value: int
var climate := FastNoiseLite.new()
var relief := FastNoiseLite.new()
func _init(world_seed: int) -> void:
	seed_value = world_seed
	climate.seed = world_seed
	climate.frequency = 0.008
	relief.seed = world_seed+91
	relief.frequency = 0.13
static func chunk(at: Vector3) -> Vector2i:
	return Vector2i(floori((at.x+32)/CHUNK),floori((at.z+32)/CHUNK))
static func key(cell: Vector2i) -> String: return "%d:%d" % [cell.x,cell.y]
func temperature(at: Vector3) -> float:
	return at.x/95.0+climate.get_noise_2d(at.x,at.z)*0.55
func biome(at: Vector3) -> String:
	var t := temperature(at)
	return "desert" if t > 0.65 else "snow" if t < -0.65 else "forest"
func color(at: Vector3) -> Color:
	var t := temperature(at)
	var base := Color("53634b")
	if t > 0.3: base = base.lerp(Color("938168"),smoothstep(0.3,0.9,t))
	if t < -0.3: base = base.lerp(Color("8b9ca8"),smoothstep(0.3,0.9,-t))
	var n := relief.get_noise_2d(at.x,at.z)
	var path_distance := absf(at.z-sin(at.x*0.035)*5)
	base = base.lerp(Color("756353") if absf(t)<0.5 else Color("c7b895") if t>0 else Color("8eabb9"), (1.0-smoothstep(1.0,3.0,path_distance))*0.4)
	return base.lightened(n*0.3)
func height(at: Vector3) -> float:
	var blend := smoothstep(18,25,maxf(absf(at.x),absf(at.z)))
	return lerpf(-0.3,-0.17+relief.get_noise_2d(at.x,at.z)*0.15,blend)
func descriptors(cell: Vector2i) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%d" % [seed_value,cell.x,cell.y])
	var result: Array[Dictionary] = []
	var columns := 6 if biome(Vector3(cell.x*64,0,cell.y*64))=="desert" else 8
	var spacing := 60.0/columns
	for i in columns*columns:
		var at := Vector3(cell.x*CHUNK-30+spacing*0.5+(i%columns)*spacing+rng.randf_range(-1.4,1.4),0,cell.y*CHUNK-30+spacing*0.5+floori(float(i)/columns)*spacing+rng.randf_range(-1.4,1.4))
		if absf(at.x)>LIMIT or absf(at.z)>LIMIT or (absf(at.x)<23 and absf(at.z)<22): continue
		if cell != Vector2i.ZERO and at.distance_to(landmark(cell))<6: continue
		var kind: String = ["pine","pine","hare","ore","stone","pine","hare","ore"][i%8]
		if biome(at)=="forest": kind = ["pine","pine","hare","pine","stone","pine","ore","pine"][i%8]
		result.append({"id":"c:%d:%d:%d" % [cell.x,cell.y,i],"kind":kind,"position":at,"biome":biome(at),"variant":i})
	return result
func landmark(cell: Vector2i) -> Vector3:
	return Vector3(cell.x*CHUNK+6,0,cell.y*CHUNK+6)

# One candidate per broad sector. Existing W4 resource coordinates never change:
# creatures occupy the six-metre clearings already reserved for landmarks.
func creature_site(cell: Vector2i) -> Dictionary:
	var sector := Vector2i(floori(float(cell.x)/8),floori(float(cell.y)/8))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("creature:1:%d:%d:%d" % [seed_value,sector.x,sector.y])
	var chosen := sector*8+Vector2i(rng.randi_range(2,5),rng.randi_range(2,5))
	# The first eastern and western expeditions have a reachable opportunity.
	if sector == Vector2i.ZERO: chosen = Vector2i(4,0)
	if sector == Vector2i(-1,0): chosen = Vector2i(-4,0)
	if cell != chosen: return {}
	var at := landmark(cell)
	if maxf(absf(at.x),absf(at.z))>LIMIT-32 or at.length()<220: return {}
	return {"id":"shrine:%d:%d" % [cell.x,cell.y],"position":[at.x,0,at.z],"biome":biome(at)}
