extends Node

const settings_save_path := "user://saves/settings.save"
const save_path := "user://saves/save_file.save"

func save_settings():
	var file = FileAccess.open(settings_save_path, FileAccess.WRITE)
	file.store_var(OptionsMenu.sfx_slider_value)
	file.store_var(OptionsMenu.music_slider_value)
	file.store_var(OptionsMenu.fullscreen)
	file.store_var(OptionsMenu.borderless)
	#file.store_var(DisplayServer.window_get_size())

func load_settings():
	if FileAccess.file_exists(settings_save_path):
		var file = FileAccess.open(settings_save_path, FileAccess.READ)
		OptionsMenu.sfx_slider_value = file.get_var()
		OptionsMenu.music_slider_value = file.get_var()
		OptionsMenu.fullscreen = file.get_var()
		OptionsMenu.borderless = file.get_var()
		OptionsMenu.set_loaded_settings()
		#DisplayServer.window_set_size(file.get_var())

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
	file.store_var(world.opened_doors)
	file.store_var(world.appleCount)

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
		world.opened_doors = file.get_var()
		world.appleCount = file.get_var()
	#else:
		#world.cam_size = Vector2(304, 192)#get_node("Camera").get_viewport_rect().size
		#world.checkpoint_room = Vector2(0, 1)
		#world.checkpoint_pos = world.cam_size/2.0
		#world.player.has_dash = false
		#world.player.has_wallclimb = false
		#world.player.has_double_jump = false
		#world.player.has_freeze = false
		#world.player.has_blue_blocks = false
		#print("no data has been saved")
