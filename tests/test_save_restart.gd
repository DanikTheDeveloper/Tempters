extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	game.save_path = "user://w2_restart_test.json"
	game.persistence_enabled = true
	root.add_child(game)
	var valid := true
	if "--write" in OS.get_cmdline_user_args():
		game.state.inventory.ore = 2
		game.state.try_service("ingot_from_ore")
		game.targets[-1].harvest(game.state)
		game.save_game()
		valid = FileAccess.file_exists(game.save_path)
	else:
		valid = game.state.inventory.ingot == 1 and game.state.inventory.ore == 0 and game.state.inventory.raw_meat == 1 and game.targets[-1].depleted and game.targets[-1].remaining > 30
		DirAccess.remove_absolute(game.save_path)
	game.persistence_enabled = false
	game.queue_free()
	await process_frame
	print("CROSS-PROCESS SAVE: ","PASS" if valid else "FAIL")
	quit(0 if valid else 1)
