class_name GameHUD
extends CanvasLayer

signal feed_requested
signal discard_requested(item: String)
signal service_requested(id: String)
signal save_requested
signal load_requested
signal previous_requested
signal close_requested
var services: OptionButton
var details: Label
var service_status: Label
var service_button: Button
var gear_text: Label
var drain_text: Label
var bond_text: Label
var busy := false
var state: GameState
var sat: ProgressBar
var stats: Label
var mood: Label
var hint: Label
var notice: Label
var bag: VBoxContainer
var menu: PanelContainer
var inventory_panel: PanelContainer
var feed_button: Button
var bag_rows: Dictionary = {}
var inventory_summary: Label
var hp: ProgressBar
var discard_buttons: Dictionary = {}

func panel(at: Vector2, size: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	p.position = at
	p.custom_minimum_size = size
	var style := StyleBoxFlat.new()
	style.bg_color = Color("202e2b",0.96)
	style.border_color = Color("887950")
	style.set_border_width_all(1)
	style.set_content_margin_all(14)
	style.corner_radius_top_left = 4
	style.corner_radius_bottom_right = 4
	p.add_theme_stylebox_override("panel",style)
	add_child(p)
	return p

func text(parent: Node, content: String, size := 16, color := Color("e7d9bf")) -> Label:
	var label := Label.new()
	label.text = content
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	parent.add_child(label)
	return label

func button(parent: Node, content: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = content
	b.custom_minimum_size.y = 35
	b.add_theme_font_size_override("font_size",15)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func setup(model: GameState) -> void:
	state = model
	var heading := panel(Vector2(24,22),Vector2(300,100))
	var v := VBoxContainer.new()
	heading.add_child(v)
	text(v,"T E M P T E R S",27)
	stats = text(v,"",14)
	hp = ProgressBar.new()
	hp.custom_minimum_size = Vector2(270,6)
	hp.show_percentage = false
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color("8caa8c")
	hp.add_theme_stylebox_override("fill",hp_fill)
	v.add_child(hp)
	bond_text = text(v,"",10,Color("baa473"))
	var hunger := panel(Vector2(876,22),Vector2(380,100))
	v = VBoxContainer.new()
	hunger.add_child(v)
	mood = text(v,"",13)
	sat = ProgressBar.new()
	sat.custom_minimum_size = Vector2(350,14)
	sat.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("bc8493")
	sat.add_theme_stylebox_override("fill",fill)
	v.add_child(sat)
	drain_text = text(v,"",12,Color("c3b79e"))
	var bottom := panel(Vector2(24,624),Vector2(1232,73))
	v = VBoxContainer.new()
	bottom.add_child(v)
	hint = text(v,"Click a hare → hunt → return to the Widow → offer meat.",16)
	text(v,"CLICK  walk / work    RIGHT CLICK  cancel    I  inventory    F5  save    F9  load    WHEEL  zoom    ESC  pause    F2  scale",12,Color("baa473"))
	notice = text(self,"",18)
	notice.position = Vector2(350,594)
	notice.size = Vector2(580,30)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice.add_theme_color_override("font_outline_color",Color("192923"))
	notice.add_theme_constant_override("outline_size",4)
	inventory_panel = panel(Vector2(24,150),Vector2(265,0))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(265,420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inventory_panel.add_child(scroll)
	bag = VBoxContainer.new()
	bag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(bag)
	text(bag,"Inventory",16)
	inventory_summary = text(bag,"",13)
	for item in state.inventory:
		var row := HBoxContainer.new()
		bag.add_child(row)
		var l := text(row,"",14)
		l.custom_minimum_size.x = 165
		bag_rows[item] = l
		discard_buttons[item] = button(row,"−1",func(): discard_requested.emit(item))
	text(bag,"−1 discards one item to free space.",11)
	gear_text = text(bag,"",12)
	gear_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gear_text.custom_minimum_size.x = 230
	var saves := HBoxContainer.new()
	bag.add_child(saves)
	button(saves,"Save [F5]",func(): save_requested.emit())
	button(saves,"Load [F9]",func(): load_requested.emit())
	button(bag,"Load previous save [F8]",func(): previous_requested.emit())
	button(bag,"Close inventory [I]",func(): inventory_panel.hide())
	inventory_panel.hide()
	menu = panel(Vector2(876,150),Vector2(380,0))
	v = VBoxContainer.new()
	menu.add_child(v)
	text(v,"THE WIDOW OF ROOTS",20)
	feed_button = button(v,"Feed 1 raw meat / +%d Satisfaction" % state.balance.temptress.feed_raw_meat_gain,func(): feed_requested.emit())
	services = OptionButton.new()
	services.custom_minimum_size.y = 36
	v.add_child(services)
	for id in state.service_ids(): services.add_item(state.specification(id).name)
	services.item_selected.connect(func(_index): refresh())
	details = text(v,"",14)
	details.custom_minimum_size = Vector2(345,115)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	service_status = text(v,"",13,Color("d6b18a"))
	service_status.custom_minimum_size = Vector2(345,40)
	service_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	service_button = button(v,"Craft",func(): service_requested.emit(state.service_ids()[services.selected]))
	button(v,"Close",func(): close_requested.emit())
	menu.hide()
	state.changed.connect(refresh)
	refresh()

func refresh() -> void:
	stats.text = "Health %d / %d   ·   Weight %.0f / %.0f" % [state.health,state.max_health(),state.weight(),state.capacity()]
	hp.max_value = state.max_health()
	hp.value = state.health
	mood.text = "Home Satisfaction %.1f / %d   ·   Level %d\n%s" % [state.satisfaction,state.cap(),state.level,state.mood()]
	bond_text.text = "Expedition Bond cap %d / Within shrine aura" % state.bond_cap()
	drain_text.text = "Drain: %.3f / sec   ·   Raw meat: +%d" % [state.drain(),state.balance.temptress.feed_raw_meat_gain]
	sat.max_value = state.cap()
	sat.value = state.satisfaction
	inventory_summary.text = "Weight %.0f / %d   ·   Stacks %d / %d" % [state.weight(),state.capacity(),state.slots(state.inventory),state.slot_limit()]
	for item in bag_rows:
		bag_rows[item].text = "%s  × %d" % [item.replace("_"," ").capitalize(),state.inventory[item]]
		discard_buttons[item].disabled = busy or state.inventory[item] <= 0
	feed_button.disabled = state.inventory.raw_meat < 1 or busy
	feed_button.tooltip_text = "Raw meat required. Hunt a hare." if feed_button.disabled else "Feeding remains available at zero Satisfaction."
	var names := PackedStringArray()
	for id in state.equipment: names.append(state.balance.equipment[id].name)
	gear_text.text = "Equipped: " + (", ".join(names) if not names.is_empty() else "None")
	var id: String = state.service_ids()[services.selected]
	var quote := state.quote(id)
	var spec: Dictionary = quote.spec
	services.set_item_text(services.item_count-1,state.specification("level_up").name)
	var costs := PackedStringArray()
	for item in spec.inputs: costs.append("%d %s" % [spec.inputs[item],item.replace("_"," ")])
	costs.append("%d Satisfaction" % spec.satisfaction)
	details.text = "%s\n\nCost: %s\nRequires shrine level %d" % [spec.description,", ".join(costs),spec.required_level]
	service_status.text = "Service in progress." if busy else quote.message
	service_button.text = "Restore Health" if id == "heal" else "Upgrade shrine" if id == "level_up" else "Summon" if id == "stone_golem" else "Smelt" if id == "ingot_from_ore" else "Craft & equip"
	service_button.disabled = busy or not quote.ok


