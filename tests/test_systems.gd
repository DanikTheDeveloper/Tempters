extends SceneTree

var failures := 0

func check(value: bool, description: String) -> void:
	if not value:
		push_error(description)
		failures += 1
	else: print("PASS: "+description)

func _initialize() -> void:
	var state := GameState.new()
	check(not state.feed(),"empty feeding rejected")
	check(state.collect({"raw_meat":1,"hide":1}),"hare loot accepted")
	state.satisfaction = 0
	check(state.feed() and state.satisfaction == 4 and state.inventory.raw_meat == 0,"dormancy revived atomically")
	check(not state.feed() and state.satisfaction == 4,"duplicate feed cannot create satisfaction")
	check(not state.collect({"ore":20}) and state.inventory.ore == 0,"overweight loot rejected atomically")
	state.collect({"raw_meat":1})
	state.satisfaction = 99
	state.feed()
	check(state.satisfaction == 100,"feeding clamps to cap")
	state.tick(40)
	check(is_equal_approx(state.satisfaction,99),"configured passive drain")
	state.inventory.wood = 15
	state.discard("wood")
	check(state.inventory.wood == 14,"discard frees capacity")
	check(state.slots({"wood":21}) == 2,"stack limits counted as inventory slots")
	check(not state.collect({"wood":-1}),"negative grant rejected")
	var nav := GridNavigation.new()
	nav.block(Vector3.ZERO,1.0)
	var route := nav.route(Vector3(-4,0,0),Vector3(4,0,0))
	check(route.size() > 3,"route around obstruction found")
	var clear := true
	for p in route:
		if Vector2(p.x,p.z).length() < 1.48: clear = false
	check(clear,"path respects inflated physical obstacle")
	check(not nav.route(Vector3(-4,0,0),Vector3.ZERO,2.4).is_empty(),"blocked target has reachable approach")
	print("SYSTEM TEST FAILURES: ",failures)
	quit(failures)

