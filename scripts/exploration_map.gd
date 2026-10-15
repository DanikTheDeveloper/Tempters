class_name ExplorationMap
extends Control
var game: Node
var expanded := false
var clock := 0.0
func setup(owner_game: Node) -> void:
	game = owner_game
	position = Vector2(24,155)
	size = Vector2(180,180)
	mouse_filter = Control.MOUSE_FILTER_STOP
func toggle() -> void:
	expanded = not expanded
	position = Vector2(370,150) if expanded else Vector2(24,155)
	size = Vector2(500,440) if expanded else Vector2(180,180)
	queue_redraw()
func _process(delta: float) -> void:
	clock += delta
	visible = not game.hud.inventory_panel.visible
	if clock >= 0.2:
		clock = 0
		queue_redraw()
func _draw() -> void:
	if game == null: return
	draw_rect(Rect2(Vector2.ZERO,size),Color("202e2b"))
	draw_rect(Rect2(Vector2.ZERO,size),Color("887950"),false,1)
	var scale_factor := 1.5 if expanded else 1.0
	var center := Vector2(game.hero.position.x,game.hero.position.z)
	var origin := size*0.5
	var first := Vector2i(floori((center.x-origin.x/scale_factor)/4),floori((center.y-origin.y/scale_factor)/4))
	var last := Vector2i(ceili((center.x+origin.x/scale_factor)/4),ceili((center.y+origin.y/scale_factor)/4))
	# Work is bounded by visible map cells, not the length of the expedition history.
	for x in range(first.x,last.x+1):
		for z in range(first.y,last.y+1):
			if not game.frontier.explored.has(WorldLayout.key(Vector2i(x,z))): continue
			var at := Vector2(x*4,z*4)
			var point := origin+(at-center)*scale_factor
			if point.x<4 or point.y<24 or point.x>size.x-8 or point.y>size.y-8: continue
			draw_rect(Rect2(point,Vector2.ONE*4*scale_factor),game.frontier.layout.color(Vector3(at.x,0,at.y)))
	var home := origin+(Vector2(0,-2)-center)*scale_factor
	if Rect2(Vector2(8,24),size-Vector2(16,32)).has_point(home): draw_circle(home,4,Color("e5c27d"))
	for key in game.frontier.landmarks:
		var pair: PackedStringArray = key.split(":")
		var at: Vector3 = game.frontier.layout.landmark(Vector2i(int(pair[0]),int(pair[1])))
		var point := origin+(Vector2(at.x,at.z)-center)*scale_factor
		if Rect2(Vector2(8,24),size-Vector2(16,32)).has_point(point): draw_rect(Rect2(point-Vector2(3,3),Vector2(6,6)),Color("8cacbf"))
	for record in game.creatures.records.values():
		if not record.discovered: continue
		var point := origin+(Vector2(record.position[0],record.position[2])-center)*scale_factor
		if Rect2(Vector2(8,24),size-Vector2(16,32)).has_point(point):
			draw_circle(point,5,Color("e5c27d") if record.owner=="player" else Color("c56f61") if record.owner in ["npc","contested"] else Color("cabed2"))
	draw_circle(origin,3,Color("e7d9bf"))
	draw_string(ThemeDB.fallback_font,Vector2(8,17),game.frontier.layout.biome(game.hero.position).capitalize()+" · Map [M]",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("e7d9bf"))
