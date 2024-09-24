extends Node

const save_path := "user://gamestate.save"

func save_game(world: Node):
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(world.checkpoint_room)
	file.store_var(world.checkpoint_pos)
	file.store_var(world.room_state)
	file.store_var(world.player.has_dash)
	file.store_var(world.player.has_wallclimb)
	file.store_var(world.player.has_double_jump)
	file.store_var(world.player.has_freeze)
	file.store_var(world.player.has_blue_blocks)
	file.store_var(world.get_node("WorldMap/MapComps/RoomMap").get_used_cells(0))
	file.store_var(world.player.green_key_state)
	file.store_var(world.player.red_key_state)

func load_game(world: Node):
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		world.checkpoint_room = file.get_var()
		world.checkpoint_pos = file.get_var()
		world.room_state = file.get_var()
		world.player.has_dash = file.get_var()
		world.player.has_wallclimb = file.get_var()
		world.player.has_double_jump = file.get_var()
		world.player.has_freeze = file.get_var()
		world.player.has_blue_blocks = file.get_var()
		for room in file.get_var():
			world.get_node("WorldMap").add_room(room)
		world.player.green_key_state = file.get_var()
		world.player.red_key_state = file.get_var()	
	else:
		world.cam_size = get_node("Camera").get_viewport_rect().size
		world.checkpoint_room = Vector2(0, 1)
		world.checkpoint_pos = world.cam_size/2.0
		world.player.has_dash = false
		world.player.has_wallclimb = false
		world.player.has_double_jump = false
		world.player.has_freeze = false
		world.player.has_blue_blocks = false
		print("no data has been saved")
