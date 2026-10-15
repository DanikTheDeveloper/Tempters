class_name CameraOcclusion
extends Control

var game: Node
var pieces: Array[Dictionary] = []
var markers: Dictionary = {}
var sample_time := 0.0

func setup(owner_game: Node) -> void:
	game = owner_game
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func register(root: Node3D) -> void:
	root.add_to_group("camera_occluder")
	for mesh in root.find_children("*","MeshInstance3D",true,false):
		if mesh.is_queued_for_deletion(): continue
		var originals := []
		var faded := []
		for i in mesh.mesh.get_surface_count():
			originals.append(mesh.get_surface_override_material(i))
			var source: Material = mesh.get_active_material(i)
			if source is StandardMaterial3D:
				var material: StandardMaterial3D = source.duplicate()
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				faded.append(material)
			else: faded.append(null)
		pieces.append({"mesh":mesh,"original":mesh.material_override,"surfaces":originals,"faded":faded,"alpha":1.0,"hold":0.0,"applied":false})

func reset() -> void:
	markers.clear()
	for piece in pieces:
		if is_instance_valid(piece.mesh): restore_piece(piece)
		piece.alpha = 1.0
		piece.hold = 0.0
	queue_redraw()

func restore_piece(piece: Dictionary) -> void:
	piece.mesh.material_override = piece.original
	for i in piece.surfaces.size(): piece.mesh.set_surface_override_material(i,piece.surfaces[i])
	piece.applied = false

func obstructs(mesh: MeshInstance3D, at: Vector3) -> bool:
	if not mesh.is_visible_in_tree(): return false
	var point: Vector2 = game.camera.unproject_position(at)
	var origin: Vector3 = game.camera.project_ray_origin(point)
	var inverse := mesh.global_transform.affine_inverse()
	return mesh.get_aabb().intersects_segment(inverse*origin,inverse*at) != null

func sample() -> void:
	markers.clear()
	var subjects: Array = [game.hero]
	subjects.append_array(game.combat.units)
	var used: Array[Vector2] = []
	for subject in subjects:
		if game.camera.is_position_behind(subject.global_position): continue
		if subject.global_position.distance_to(game.hero.global_position) > 28: continue
		var at: Vector3 = subject.global_position+Vector3.UP*1.1
		var screen: Vector2 = game.camera.unproject_position(at)
		if not get_viewport_rect().has_point(screen): continue
		# Only nearby registered scenery permits an overlay. Other walls retain concealment.
		var origin: Vector3 = game.camera.project_ray_origin(screen)
		var query := PhysicsRayQueryParameters3D.create(origin,at,2)
		var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and not hit.collider.is_in_group("camera_occluder_body"): continue
		var hidden := false
		for piece in pieces:
			if is_instance_valid(piece.mesh) and obstructs(piece.mesh,at):
				piece.hold = 0.22
				hidden = true
		if hidden and subject is CombatUnit and subject.kind == "raider":
			var marker := screen
			for other in used:
				if marker.distance_to(other) < 28: marker.x = other.x+28
			used.append(marker)
			markers[subject] = {"point":marker,"anchor":screen}

func _process(delta: float) -> void:
	if game == null: return
	sample_time -= delta
	if sample_time <= 0:
		sample_time = 0.08
		pieces = pieces.filter(func(p): return is_instance_valid(p.mesh))
		sample()
	for piece in pieces:
		piece.hold = maxf(0,piece.hold-delta)
		piece.alpha = move_toward(piece.alpha,0.35 if piece.hold > 0 else 1.0,delta*3)
		if piece.alpha < 1:
			if not piece.applied:
				piece.mesh.material_override = null
				for i in piece.faded.size():
					if piece.faded[i] != null: piece.mesh.set_surface_override_material(i,piece.faded[i])
				piece.applied = true
			for material in piece.faded:
				if material != null: material.albedo_color.a = piece.alpha
		elif piece.applied: restore_piece(piece)
	queue_redraw()

func indicator_at(point: Vector2) -> CombatUnit:
	var nearest: CombatUnit
	var distance := 14.0
	for unit in markers:
		if not is_instance_valid(unit): continue
		var d: float = point.distance_to(markers[unit].point)
		if d < distance:
			nearest = unit
			distance = d
	return nearest

func _draw() -> void:
	if game == null: return
	for unit in markers:
		if not is_instance_valid(unit): continue
		var p: Vector2 = markers[unit].point
		draw_line(markers[unit].anchor,p,Color("b64f44"),1.5,true)
		draw_circle(p,11,Color(0.12,0.05,0.05,0.8))
		draw_arc(p,11,0,TAU,20,Color("e37a68"),2,true)
		draw_line(p-Vector2(4,4),p+Vector2(4,4),Color("e7d9bf"),2,true)
		draw_line(p+Vector2(-4,4),p+Vector2(4,-4),Color("e7d9bf"),2,true)
	var hotspot: Vector2 = game.camera.unproject_position(game.shrine.position+Vector3(0,0.35,2.3))
	if game.hero.position.distance_to(game.shrine.position) < 25:
		draw_arc(hotspot,15,0,TAU,24,Color("b59658"),1.5,true)
		draw_string(ThemeDB.fallback_font,hotspot+Vector2(-24,30),"Services",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("e7d9bf"))
