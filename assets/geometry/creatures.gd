class_name Creatures
extends RefCounted

static func shrine(parent: Node3D) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	var plum := Sculpt.mat("563b4c",0.6)
	var rose := Sculpt.mat("aa6b7d",0.48)
	var inner := Sculpt.mat("cc8d9c",0.4)
	var bone := Sculpt.mat("c9b891",0.7)
	var brass := Sculpt.mat("96784b",0.42,0.55)
	Sculpt.rock(root,Vector3(0,0.45,0),Vector3(2.65,0.75,1.9),Sculpt.mat("49473c"),8)
	# Lean the sculpture toward the elevated camera: the cleft remains visible.
	var flesh := Node3D.new()
	flesh.name = "BreathingFolds"
	flesh.rotation.x = deg_to_rad(-22)
	root.add_child(flesh)
	Sculpt.rock(flesh,Vector3(0,3.1,-0.3),Vector3(1.75,3.25,0.65),plum,4)
	Sculpt.rock(flesh,Vector3(0,3.35,0.36),Vector3(0.29,2.35,0.16),Sculpt.mat("271f2a",0.8),7)
	for side in [-1.0,1.0]:
		for layer in 2:
			var points: Array[Vector3] = []
			var widths: Array[float] = []
			var depths: Array[float] = []
			for i in 33:
				var t := float(i)/32
				var bow := pow(sin(PI*t),0.8)
				var x: float = (0.12 + bow * (1.22 if layer == 0 else 0.42)) * side
				x += sin(t*11+side)*0.08*bow
				points.append(Vector3(x,0.55+t*(5.9 if side < 0 else 5.65),0.45+bow*(0.31 if layer == 0 else 0.62)))
				widths.append(0.018 + bow*(0.48 if layer == 0 else 0.19)*(1+0.12*sin(t*19)))
				depths.append(0.025 + bow*(0.53 if layer == 0 else 0.22))
			Sculpt.loft(flesh,points,widths,depths,rose if layer == 0 else inner,16)
		# Fine longitudinal ridge on the moist inner edge; not a solid glowing stripe.
		var ridge: Array[Vector3] = []
		var radii: Array[float] = []
		for i in 25:
			var t := float(i)/24
			ridge.append(Vector3(side*(0.08+sin(PI*t)*0.14),1.25+t*4.25,0.68+sin(PI*t)*0.48))
			radii.append(0.009+sin(PI*t)*0.035)
		Sculpt.loft(flesh,ridge,radii,radii,Sculpt.mat("e1a6ad",0.35,0,0.18),8)
	Sculpt.rock(flesh,Vector3(-0.08,6.28,0.48),Vector3(0.48,0.34,0.47),plum,32)
	Sculpt.rock(flesh,Vector3(0.01,6.1,0.85),Vector3(0.17,0.17,0.16),inner,12)
	# Root buttresses with bent, diminishing profiles tie the organism into the soil.
	for i in 11:
		var a := TAU*i/11.0
		var points: Array[Vector3] = []
		var widths: Array[float] = []
		var depths: Array[float] = []
		for j in 10:
			var t := float(j)/9
			var radius := 1.1+t*2.7
			points.append(Vector3(cos(a)*radius,0.1+pow(1-t,2)*1.65,sin(a)*radius*0.7))
			widths.append(0.025+(1-t)*0.25)
			depths.append(0.025+(1-t)*0.24)
		Sculpt.loft(root,points,widths,depths,plum,9)
	for i in 18:
		var a := TAU*i/18.0
		if i % 5 == 0: continue
		var p := Vector3(cos(a)*3.3,0.12,sin(a)*2.7)
		var slab := Sculpt.rock(root,p,Vector3(0.4,0.18,0.23),bone,i+50)
		slab.rotation.y = -a
	for x in [-2.3,2.3]:
		Sculpt.limb(root,Vector3(x,0,1.4),Vector3(x,0.65,1.4),0.12,brass)
		Sculpt.torus(root,Vector3(x,0.65,1.4),0.27,0.07,brass)
		Sculpt.rock(root,Vector3(x,0.72,1.4),Vector3(0.14,0.09,0.14),Sculpt.mat("e2ad72",0.6,0,0.6))
	Sculpt.bake(flesh)
	Sculpt.bake(root,false)
	return flesh

static func wretch(parent: Node3D) -> Dictionary:
	var root := Node3D.new()
	parent.add_child(root)
	var cloak := Sculpt.mat("526569")
	var dark := Sculpt.mat("27383b")
	var bone := Sculpt.mat("ded2b2",0.65)
	var leather := Sculpt.mat("725347")
	Sculpt.loft(root,[Vector3(0,0.34,0),Vector3(0,0.55,0),Vector3(0,0.96,0),Vector3(0,1.19,0)],[0.45,0.4,0.31,0.17],[0.27,0.27,0.23,0.13],cloak)
	Sculpt.rock(root,Vector3(0,1.39,0),Vector3(0.39,0.4,0.33),dark,19)
	Sculpt.rock(root,Vector3(0,1.37,0.27),Vector3(0.24,0.25,0.08),bone,20)
	for x in [-0.085,0.085]:
		Sculpt.rock(root,Vector3(x,1.41,0.348),Vector3(0.032,0.055,0.018),Sculpt.mat("192923"))
	Sculpt.rock(root,Vector3(-0.12,0.84,-0.32),Vector3(0.36,0.4,0.22),leather,31)
	Sculpt.limb(root,Vector3(-0.42,0.55,-0.32),Vector3(-0.42,1.3,-0.32),0.04,Sculpt.mat("b59658",0.4,0.5))
	Sculpt.rock(root,Vector3(0,0.85,0.27),Vector3(0.085,0.12,0.07),Sculpt.mat("efba6d",0.5,0,0.5))
	var limbs: Array[Node3D] = []
	for side in [-1.0,1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(side*0.17,0.48,0)
		root.add_child(leg)
		Sculpt.limb(leg,Vector3.ZERO,Vector3(0,-0.34,0),0.085,dark)
		Sculpt.rock(leg,Vector3(0,-0.36,0.07),Vector3(0.12,0.11,0.19),leather)
		limbs.append(leg)
		Sculpt.bake(leg)
	var arm := Node3D.new()
	arm.position = Vector3(0.33,1.03,0)
	root.add_child(arm)
	Sculpt.limb(arm,Vector3.ZERO,Vector3(0.13,-0.37,0.12),0.08,cloak)
	Sculpt.rock(arm,Vector3(0.13,-0.37,0.12),Vector3(0.09,0.1,0.09),leather)
	Sculpt.limb(arm,Vector3(0.13,-0.48,0.12),Vector3(0.13,0.13,0.12),0.035,leather)
	Sculpt.rock(arm,Vector3(0.22,0.09,0.12),Vector3(0.16,0.1,0.045),Sculpt.mat("a8b4ae",0.4,0.65))
	Sculpt.limb(root,Vector3(-0.3,1,0),Vector3(-0.43,0.66,0.14),0.09,cloak)
	Sculpt.rock(root,Vector3(-0.43,0.66,0.14),Vector3(0.09,0.11,0.09),leather)
	Sculpt.bake(arm)
	Sculpt.bake(root,false)
	return {"root":root,"legs":limbs,"arm":arm}

static func hare(parent: Node3D) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	var fur := Sculpt.mat("a8a08b")
	var pale := Sculpt.mat("d4c9ae")
	Sculpt.rock(root,Vector3(0,0.33,0),Vector3(0.27,0.31,0.43),fur,81)
	Sculpt.rock(root,Vector3(0,0.53,0.32),Vector3(0.22,0.23,0.24),pale,19)
	for side in [-1.0,1.0]:
		var ear := Sculpt.rock(root,Vector3(side*0.13,0.91,0.28),Vector3(0.075,0.38,0.075),fur,43)
		ear.rotation.z = side*-0.16
		Sculpt.rock(root,Vector3(side*0.13,0.92,0.34),Vector3(0.035,0.25,0.022),Sculpt.mat("9c7474"))
		Sculpt.rock(root,Vector3(side*0.18,0.6,0.47),Vector3(0.035,0.04,0.023),Sculpt.mat("212821"))
		Sculpt.rock(root,Vector3(side*0.21,0.12,-0.18),Vector3(0.13,0.13,0.2),fur)
		Sculpt.limb(root,Vector3(side*0.12,0.31,0.23),Vector3(side*0.12,0.07,0.38),0.065,pale)
	Sculpt.rock(root,Vector3(0,0.37,-0.41),Vector3(0.13,0.13,0.12),pale)
	Sculpt.bake(root)
	return root



