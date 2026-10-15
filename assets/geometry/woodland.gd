class_name Woodland
extends RefCounted

static func pine(parent: Node3D, variant: int) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	var bark := Sculpt.mat("645248")
	Sculpt.loft(root,[Vector3.ZERO,Vector3(0.06,0.4,0),Vector3(-0.12,2.1,0),Vector3(0.2,4.4,0),Vector3(0.1,5.4,0)],[0.46,0.31,0.24,0.1,0.01],[0.38,0.3,0.2,0.09,0.01],bark,9)
	for i in 6:
		var a := i*TAU/6
		Sculpt.limb(root,Vector3(cos(a)*0.9,0.04,sin(a)*0.9),Vector3(0,0.65,0),0.13,bark)
		var ridge: Array[Vector3] = [Vector3(cos(a)*0.38,0.12,sin(a)*0.32),Vector3(cos(a)*0.28,0.7,sin(a)*0.25),Vector3(-0.1+cos(a)*0.23,1.6,sin(a)*0.2),Vector3(cos(a)*0.16,2.6,sin(a)*0.14)]
		Sculpt.loft(root,ridge,[0.08,0.065,0.04,0.01],[0.07,0.05,0.035,0.01],Sculpt.mat("88765d"),6)
	var rng := RandomNumberGenerator.new()
	rng.seed = variant+72
	for tier in 6:
		var y := 1.9+tier*0.56
		var r := 2.15-tier*0.29
		for branch in 7:
			var a := branch*TAU/7+tier*0.83+variant*0.12
			var length := r*rng.randf_range(0.85,1.14)
			var p := Vector3(cos(a)*length,y-0.45,sin(a)*length)
			Sculpt.limb(root,Vector3(0,y,0),p,0.055,bark)
			needle_bough(root,Vector3(0,y,0),a,length,0.7*r,Sculpt.mat(["354b40","445c49","536854"][tier%3]))
	Sculpt.loft(root,[Vector3(0.1,4.7,0),Vector3(0.13,5.1,0),Vector3(0.03,5.55,0)],[0.32,0.18,0.005],[0.28,0.15,0.005],Sculpt.mat("536854"),9)
	Sculpt.bake(root)
	return root

static func needle_bough(parent: Node3D, origin: Vector3, angle: float, length: float, width: float, material: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for layer in 2:
		for row in 12:
			for column in 6:
				var indices := [Vector2i(row,column),Vector2i(row+1,column),Vector2i(row,column+1),Vector2i(row+1,column),Vector2i(row+1,column+1),Vector2i(row,column+1)]
				if layer == 1: indices.reverse()
				for ij in indices:
					var t: float = ij.x/12.0
					var across: float = ij.y/3.0-1.0
					var serration := 1.0 if ij.x%2 == 0 else 0.68
					var spread := pow(sin(PI*t),0.65)*width*serration
					var height := -0.45*t + sin(PI*t)*0.32 - absf(across)*0.18
					if layer == 1: height -= 0.13*sin(PI*t)
					var local := Vector3(t*length,height,across*spread*0.5)
					var shade := 0.75+0.25*(1.0-absf(across))
					if layer == 1: shade *= 0.7
					st.set_color(Color(shade,shade,shade))
					st.add_vertex(origin+Basis(Vector3.UP,-angle)*local)
	st.generate_normals()
	Sculpt.mesh(parent,st.commit(),material)

static func ore(parent: Node3D, variant: int, is_ore: bool) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	for i in 5:
		var a := i*2.4
		Sculpt.rock(root,Vector3(cos(a)*0.48,0.3+float(i%2)*0.24,sin(a)*0.43),Vector3(0.65,0.54+float(i%2)*0.28,0.55),Sculpt.mat(["677474","515e61","87938b"][i%3]),variant+i)
		if is_ore:
			Sculpt.limb(root,Vector3(cos(a)*0.6,0.6,sin(a)*0.5),Vector3(cos(a)*0.35,1.08,sin(a)*0.3),0.075,Sculpt.mat("bb9364",0.32,0.7))
	Sculpt.bake(root)
	return root

static func terrain(parent: Node3D, seed_value: int) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.22
	for x in range(-19,19):
		for z in range(-18,18):
			for p in [Vector2(x,z),Vector2(x+1,z),Vector2(x,z+1),Vector2(x+1,z),Vector2(x+1,z+1),Vector2(x,z+1)]:
				var n := noise.get_noise_2d(p.x,p.y)
				var path_x := sin(p.y*0.38)*0.9
				var path: bool = absf(p.x-path_x) < 1.5 and p.y > -1
				var ritual := Vector2(p.x/1.1,p.y+2).length() < 4.2
				var color := Color("756353") if path or ritual else Color("455747").lerp(Color("677054"),n*0.5+0.5)
				st.set_color(color.lightened(n*0.13).srgb_to_linear())
				st.add_vertex(Vector3(p.x,-0.08+n*0.12,p.y))
	st.generate_normals()
	Sculpt.mesh(parent,st.commit(),Sculpt.mat("ffffff"))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	# One MultiMesh for grass: sparse clumps, excluded from the approach path.
	var blade := SurfaceTool.new()
	blade.begin(Mesh.PRIMITIVE_TRIANGLES)
	for a in [0.0,2.1,4.2]:
		var side := Vector3(cos(a),0,sin(a))*0.12
		for p in [-side,side,Vector3(0.07,0.35,0.03)]: blade.add_vertex(p)
	blade.generate_normals()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = blade.commit()
	mm.instance_count = 520
	for i in mm.instance_count:
		var p := Vector3(rng.randf_range(-17,17),0,rng.randf_range(-15,15))
		if absf(p.x) < 2.2 or Vector2(p.x,p.z+2).length() < 4.3: p.x += 5.0
		var basis := Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*rng.randf_range(0.6,1.5))
		mm.set_instance_transform(i,Transform3D(basis,p))
	var grass := MultiMeshInstance3D.new()
	grass.multimesh = mm
	var grass_mat := Sculpt.mat("6b7954")
	grass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	grass.material_override = grass_mat
	parent.add_child(grass)
	for i in 65:
		var p := Vector3(rng.randf_range(-16,16),0.02,rng.randf_range(-14,14))
		Sculpt.rock(parent,p,Vector3(0.12,0.08,0.18)*rng.randf_range(0.6,1.8),Sculpt.mat("8a8971"),i)
	# Moss beds grow in coherent islands rather than evenly spaced decoration.
	for center in [Vector3(-6,0,1),Vector3(7,0,-2),Vector3(-9,0,-7),Vector3(9,0,9)]:
		for i in 12:
			var p: Vector3 = center+Vector3(rng.randf_range(-1.8,1.8),0.02,rng.randf_range(-1.2,1.2))
			Sculpt.rock(parent,p,Vector3(rng.randf_range(0.2,0.6),0.055,rng.randf_range(0.2,0.5)),Sculpt.mat("657451"),i)
	# Fallen trunks, exposed broken heartwood, and bone-like twigs.
	for p in [Vector3(-8,0.2,4),Vector3(7,0.2,-8)]:
		Sculpt.limb(parent,p,p+Vector3(2,0.1,0.7),0.24,Sculpt.mat("514a3d"))
		Sculpt.limb(parent,p+Vector3(1,0.1,0.35),p+Vector3(1.1,0.7,0.8),0.09,Sculpt.mat("786953"))
		Sculpt.rock(parent,p+Vector3(2,0.1,0.7),Vector3(0.13,0.14,0.13),Sculpt.mat("b69e76"),33)
	# Low geological cut edge gives the clearing a miniature's physical thickness.
	for i in 44:
		var a := TAU*i/44.0
		Sculpt.rock(parent,Vector3(cos(a)*18,-0.5,sin(a)*17),Vector3(1.7,0.8,1.3),Sculpt.mat("39443e"),i)




