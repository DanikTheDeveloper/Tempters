class_name Fortifications
extends RefCounted

static func build(parent: Node3D, kind: String, tier := 1) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	var timber := Sculpt.mat("66503b")
	var cut := Sculpt.mat("a28b63")
	var iron := Sculpt.mat("71817b",0.6,0.45)
	var bone := Sculpt.mat("d8c6a4")
	var cord := Sculpt.mat("393f31")
	if kind == "palisade":
		for i in 5:
			var x := (i-2)*0.29
			var h := 1.25+float(i%3)*0.14
			Sculpt.loft(root,[Vector3(x,0,0),Vector3(x+0.03,h*0.55,0.02),Vector3(x-0.02,h-0.18,0),Vector3(x+0.02,h,0.03)],[0.13,0.12,0.11,0.008],[0.12,0.13,0.11,0.008],timber,7)
			for y in [0.4,0.85]:
				Sculpt.torus(root,Vector3(x,y,0),0.135,0.018,iron if tier == 2 else cord)
			Sculpt.rock(root,Vector3(x,0.1,0.12),Vector3(0.17,0.12,0.19),Sculpt.mat("5f6658"),i)
		for y in [0.4,0.85]: Sculpt.limb(root,Vector3(-0.73,y,-0.15),Vector3(0.73,y+0.07,-0.15),0.065,cut)
		if tier == 2:
			Sculpt.limb(root,Vector3(-0.67,0.25,0.16),Vector3(0.67,1.05,0.16),0.045,iron)
	else:
		for i in 5:
			var a := TAU*i/5
			Sculpt.rock(root,Vector3(cos(a)*0.3,0.12,sin(a)*0.3),Vector3(0.25,0.18,0.23),Sculpt.mat("657263"),i+40)
		Sculpt.loft(root,[Vector3.ZERO,Vector3(-0.06,0.55,0),Vector3(0.04,1.2,0),Vector3(0,1.65,0)],[0.2,0.15,0.13,0.1],[0.17,0.12,0.12,0.08],timber,9)
		Sculpt.limb(root,Vector3(-0.48,1.37,0),Vector3(0.48,1.42,0),0.055,cut)
		for x in [-0.39,0.39]:
			Sculpt.limb(root,Vector3(x,1.4,0),Vector3(x,1.04,0),0.012,cord)
			Sculpt.rock(root,Vector3(x,1.02,0),Vector3(0.07,0.16,0.055),bone)
		Sculpt.rock(root,Vector3(0,1.66,0),Vector3(0.22,0.27,0.16),bone,51)
		for x in [-0.08,0.08]: Sculpt.rock(root,Vector3(x,1.7,0.15),Vector3(0.035,0.055,0.025),cord)
		for y in [0.7,1.2]: Sculpt.torus(root,Vector3(0,y,0),0.18,0.025,iron)
		if tier == 2:
			for x in [-0.18,0.18]: Sculpt.limb(root,Vector3(x,1.78,0),Vector3(x*1.7,2.0,-0.04),0.035,iron)
	Sculpt.bake(root)
	return root
