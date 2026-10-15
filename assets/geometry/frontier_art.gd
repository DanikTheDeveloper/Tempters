class_name FrontierArt
extends RefCounted
static var ground_material: StandardMaterial3D
static var terrain_cache: Dictionary = {}
static var blade_mesh: Mesh
static var pebble_mesh: Mesh
static func terrain(parent: Node3D, layout: WorldLayout, cell: Vector2i, first_row: int, rows: int) -> void:
	if ground_material == null:
		ground_material = Sculpt.mat("ffffff").duplicate()
		var texture := NoiseTexture2D.new()
		texture.width = 128
		texture.height = 128
		texture.seamless = true
		var noise := FastNoiseLite.new()
		noise.seed = 4519
		noise.frequency = 0.15
		texture.noise = noise
		var gradient := Gradient.new()
		gradient.set_color(0,Color(0.82,0.82,0.82))
		gradient.set_color(1,Color.WHITE)
		texture.color_ramp = gradient
		ground_material.albedo_texture = texture
		ground_material.uv1_scale = Vector3.ONE*0.18
		ground_material.roughness = 0.95
	var cache_key := "%d:%s:%d" % [layout.seed_value,WorldLayout.key(cell),first_row]
	if terrain_cache.has(cache_key):
		Sculpt.mesh(parent,terrain_cache[cache_key],ground_material)
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(first_row,mini(32,first_row+rows)):
		for z in 32:
			for uv in [Vector2(x,z),Vector2(x+1,z),Vector2(x,z+1),Vector2(x+1,z),Vector2(x+1,z+1),Vector2(x,z+1)]:
				var at := Vector3(cell.x*64-32+uv.x*2,0,cell.y*64-32+uv.y*2)
				st.set_color(layout.color(at).srgb_to_linear())
				at.y = layout.height(at)
				st.add_vertex(at)
	st.generate_normals()
	var mesh := st.commit()
	if terrain_cache.size()>=96: terrain_cache.erase(terrain_cache.keys()[0])
	terrain_cache[cache_key] = mesh
	Sculpt.mesh(parent,mesh,ground_material)

static func dry_tree(parent: Node3D) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	var bark := Sculpt.mat("86735d")
	Sculpt.loft(root,[Vector3.ZERO,Vector3(0.1,0.5,0),Vector3(-0.2,1.8,0),Vector3(0.4,3.5,0)],[0.5,0.26,0.18,0.03],[0.4,0.25,0.14,0.02],bark,8)
	for i in 7:
		var a := i*2.4
		var p := Vector3(0,0.8+i*0.3,0)
		var end := p+Vector3(cos(a)*1.4,0.5,sin(a)*1.1)
		Sculpt.limb(root,p,end,0.08,bark)
		Sculpt.limb(root,end,end+Vector3(0.1,0.65,-0.1),0.04,bark)
	for i in 5:
		Sculpt.limb(root,Vector3.ZERO,Vector3(cos(i)*0.9,0.02,sin(i)*0.9),0.12,bark)
	return root

static func landmark(parent: Node3D, at: Vector3, biome: String) -> void:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = at
	var mat := Sculpt.mat("9e8a69" if biome == "desert" else "9cbbc5" if biome == "snow" else "707a67")
	for side in [-1,1]:
		Sculpt.loft(root,[Vector3(side*1.6,0,0),Vector3(side*1.7,0.6,0),Vector3(side*1.45,2.4,0),Vector3(side*1.5,3.5,0)],[0.65,0.5,0.4,0.25],[0.6,0.5,0.45,0.3],mat,7)
	Sculpt.limb(root,Vector3(-1.5,3,0),Vector3(0.4,3.3,0),0.28,mat)
	for i in 5: Sculpt.rock(root,Vector3(cos(i)*2,0.12,sin(i)*1.4),Vector3(0.5,0.25,0.4),mat,i)

static func dressing(parent: Node3D, layout: WorldLayout, cell: Vector2i) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("dressing:"+WorldLayout.key(cell)+str(layout.seed_value))
	if blade_mesh == null:
		var blades := SurfaceTool.new()
		blades.begin(Mesh.PRIMITIVE_TRIANGLES)
		for angle in [0.0,2.1,4.2]:
			var side := Vector3(cos(angle),0,sin(angle))*0.16
			for v in [-side,side,Vector3(0.09,0.48,0.04)]: blades.add_vertex(v)
		blades.generate_normals()
		blade_mesh = blades.commit()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = blade_mesh
	mm.instance_count = 480
	for i in mm.instance_count:
		var at := Vector3(cell.x*64+rng.randf_range(-31,31),0,cell.y*64+rng.randf_range(-31,31))
		var visible_scale := 0.0 if absf(at.x)<23 and absf(at.z)<22 else rng.randf_range(0.6,1.6)
		mm.set_instance_transform(i,Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*visible_scale),at))
		var biome := layout.biome(at)
		mm.set_instance_color(i,Color("6b7954") if biome == "forest" else Color("87795e") if biome == "desert" else Color("91a8ac"))
	var grass := MultiMeshInstance3D.new()
	grass.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	grass.material_override = mat
	parent.add_child(grass)
	var stones := MultiMesh.new()
	stones.transform_format = MultiMesh.TRANSFORM_3D
	stones.use_colors = true
	stones.mesh = pebble_mesh
	stones.instance_count = 90
	for i in stones.instance_count:
		var at := Vector3(cell.x*64+rng.randf_range(-31,31),0,cell.y*64+rng.randf_range(-31,31))
		var scale_value := 0.0 if absf(at.x)<23 and absf(at.z)<22 else rng.randf_range(0.2,0.7)
		stones.set_instance_transform(i,Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3(scale_value,0.16*scale_value,scale_value)),at))
		stones.set_instance_color(i,layout.color(at).lightened(0.12))
	var pebbles := MultiMeshInstance3D.new()
	pebbles.multimesh = stones
	pebbles.material_override = mat
	parent.add_child(pebbles)
