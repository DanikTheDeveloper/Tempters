class_name Sculpt
extends RefCounted
## Original mesh vocabulary. All mesh construction happens at scene creation.
static var materials: Dictionary = {}
static var grain: NoiseTexture2D

static func mat(hex: String, rough := 0.85, metal := 0.0, glow := 0.0) -> StandardMaterial3D:
	var key := hex + str(rough) + str(metal) + str(glow)
	if materials.has(key): return materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = rough
	m.metallic = metal
	m.vertex_color_use_as_albedo = true
	if grain == null:
		grain = NoiseTexture2D.new()
		grain.width = 128
		grain.height = 128
		grain.seamless = true
		var noise := FastNoiseLite.new()
		noise.seed = 283451
		noise.frequency = 0.12
		noise.fractal_octaves = 3
		grain.noise = noise
		var ramp := Gradient.new()
		ramp.set_color(0,Color(0.48,0.48,0.48))
		ramp.set_color(1,Color.WHITE)
		grain.color_ramp = ramp
	if glow == 0:
		m.albedo_texture = grain
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3.ONE * 0.9
	if glow > 0:
		m.emission_enabled = true
		m.emission = Color(hex)
		m.emission_energy_multiplier = glow
	materials[key] = m
	return m

static func mesh(parent: Node3D, shape: Mesh, material: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = shape
	node.material_override = material
	node.position = pos
	parent.add_child(node)
	return node

static func loft(parent: Node3D, points: Array[Vector3], widths: Array[float], depths: Array[float], material: Material, sides := 12) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(points.size()-1):
		for j in sides:
			for ij in [Vector2i(i,j),Vector2i(i,(j+1)%sides),Vector2i(i+1,j),Vector2i(i,(j+1)%sides),Vector2i(i+1,(j+1)%sides),Vector2i(i+1,j)]:
				var a: float = TAU * ij.y / sides
				var ripple := 1.0 + 0.045 * sin(ij.x * 2.3 + ij.y * 2.0)
				var v := points[ij.x] + Vector3(cos(a)*widths[ij.x],0,sin(a)*depths[ij.x]) * ripple
				var shade := 0.92 + 0.08 * sin(ij.x * 1.81 + ij.y * 0.9)
				st.set_color(Color(shade,shade,shade))
				st.add_vertex(v)
	st.generate_normals()
	return mesh(parent, st.commit(), material)

static func rock(parent: Node3D, pos: Vector3, size: Vector3, material: Material, seed_value := 1) -> MeshInstance3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var points: Array[Vector3] = []
	var widths: Array[float] = []
	var depths: Array[float] = []
	for i in 7:
		var t := float(i)/6
		points.append(Vector3(sin(t*5)*0.09, (t-0.5)*2, cos(t*7)*0.08))
		var r := maxf(0.015, sin(PI*t)) * rng.randf_range(0.86,1.1)
		widths.append(r)
		depths.append(r)
	var result := loft(parent,points,widths,depths,material,9)
	result.position = pos
	result.scale = size
	return result

static func limb(parent: Node3D, a: Vector3, b: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = radius * 0.65
	c.bottom_radius = radius
	c.height = a.distance_to(b)
	c.radial_segments = 7
	var result := mesh(parent,c,material,(a+b)*0.5)
	if absf((b-a).normalized().dot(Vector3.UP)) < 0.99:
		result.basis = Basis.looking_at((b-a).normalized(), Vector3.UP) * Basis(Vector3.RIGHT, PI/2)
	return result

static func label(parent: Node3D, text: String, pos: Vector3, size := 24) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.018
	l.position = pos
	l.modulate = Color("e7d9bf")
	l.outline_size = 5
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	parent.add_child(l)
	return l

static func torus(parent: Node3D, pos: Vector3, radius: float, thickness: float, material: Material) -> MeshInstance3D:
	var t := TorusMesh.new()
	t.inner_radius = radius-thickness
	t.outer_radius = radius+thickness
	t.rings = 40
	t.ring_segments = 8
	return mesh(parent,t,material,pos)

static func bake(root: Node3D, recursive := true) -> void:
	# Consolidate authored pieces by material once; foliage is not hundreds of draws.
	var groups: Dictionary = {}
	for child in root.find_children("*","MeshInstance3D",recursive,false):
		var m: Material = child.material_override
		if not groups.has(m):
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[m] = surface
		groups[m].append_from(child.mesh,0,root.global_transform.affine_inverse()*child.global_transform)
		child.queue_free()
	for material in groups:
		mesh(root,groups[material].commit(),material)




