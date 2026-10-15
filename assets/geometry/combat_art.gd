class_name CombatArt
extends RefCounted

static func unit(parent: Node3D, kind: String) -> Dictionary:
	var root := Node3D.new()
	parent.add_child(root)
	var stone := Sculpt.mat("718276")
	var dark := Sculpt.mat("343c35")
	var brass := Sculpt.mat("b59658",0.5,0.55)
	var cloth := Sculpt.mat("704b42")
	var limbs: Array[Node3D] = []
	var arms: Array[Node3D] = []
	if kind == "golem":
		Sculpt.rock(root,Vector3(0,1.08,0),Vector3(0.57,0.65,0.37),stone,33)
		Sculpt.rock(root,Vector3(0,1.91,0),Vector3(0.33,0.38,0.29),stone,52)
		Sculpt.rock(root,Vector3(0,1.1,0.35),Vector3(0.11,0.24,0.035),brass)
		for x in [-0.13,0.13]: Sculpt.rock(root,Vector3(x,1.97,0.27),Vector3(0.045,0.035,0.025),Sculpt.mat("b9c4a0",0.5,0,0.35))
		for i in 5: Sculpt.rock(root,Vector3(sin(i)*0.42,1.4+cos(i)*0.15,-0.1),Vector3(0.13,0.08,0.18),Sculpt.mat("50664a"),i)
	else:
		Sculpt.loft(root,[Vector3(0,0.3,0),Vector3(0,0.75,0),Vector3(0,1.2,0),Vector3(0,1.45,0)],[0.37,0.32,0.26,0.17],[0.28,0.24,0.2,0.12],cloth)
		Sculpt.rock(root,Vector3(0,1.64,-0.04),Vector3(0.32,0.39,0.29),dark,14)
		Sculpt.rock(root,Vector3(0,1.61,0.23),Vector3(0.19,0.24,0.06),brass,19)
		for x in [-0.07,0.07]: Sculpt.rock(root,Vector3(x,1.67,0.285),Vector3(0.035,0.025,0.018),dark)
		Sculpt.limb(root,Vector3(-0.3,1.12,0.2),Vector3(0.28,0.6,0.23),0.045,brass)
	for side in [-1.0,1.0]:
		var leg := Node3D.new()
		root.add_child(leg)
		leg.position = Vector3(side*(0.27 if kind == "golem" else 0.16),0.55,0)
		Sculpt.rock(leg,Vector3(0,-0.22,0),Vector3(0.19,0.32,0.2) if kind == "golem" else Vector3(0.09,0.3,0.12),stone if kind == "golem" else dark,int(side)+5)
		Sculpt.rock(leg,Vector3(0,-0.45,0.1),Vector3(0.22,0.13,0.3) if kind == "golem" else Vector3(0.11,0.1,0.21),dark)
		Sculpt.bake(leg)
		limbs.append(leg)
		var arm := Node3D.new()
		root.add_child(arm)
		arm.position = Vector3(side*(0.61 if kind == "golem" else 0.32),1.4 if kind == "golem" else 1.2,0)
		Sculpt.rock(arm,Vector3(0,-0.27,0),Vector3(0.22,0.4,0.24) if kind == "golem" else Vector3(0.1,0.29,0.12),stone if kind == "golem" else cloth,16)
		Sculpt.rock(arm,Vector3(0,-0.57,0.08),Vector3(0.27,0.24,0.27) if kind == "golem" else Vector3(0.1,0.11,0.09),stone if kind == "golem" else dark,11)
		if kind != "golem" and side > 0:
			Sculpt.limb(arm,Vector3(0,-1,0.08),Vector3(0,1.2,0.08),0.025,Sculpt.mat("695449"))
			Sculpt.rock(arm,Vector3(0,1.29,0.08),Vector3(0.075,0.23,0.05),brass)
		Sculpt.bake(arm)
		arms.append(arm)
	Sculpt.bake(root,false)
	return {"root":root,"legs":limbs,"arms":arms}

static func banner(parent: Node3D) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	Sculpt.limb(root,Vector3.ZERO,Vector3(0,2.2,0),0.045,Sculpt.mat("66503b"))
	Sculpt.limb(root,Vector3(-0.4,2,0),Vector3(0.4,2,0),0.035,Sculpt.mat("b59658",0.5,0.5))
	Sculpt.loft(root,[Vector3(0,1.1,0),Vector3(0.07,1.5,0),Vector3(0,2,0)],[0.17,0.36,0.37],[0.025,0.025,0.025],Sculpt.mat("9b4e40"),4)
	Sculpt.rock(root,Vector3(0,1.72,0.04),Vector3(0.09,0.16,0.03),Sculpt.mat("b59658"))
	Sculpt.bake(root)
	return root
