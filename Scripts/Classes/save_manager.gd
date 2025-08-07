extends Node

const settings_save_path := "user://settings.save"
const keymap_save_path := "user://keymaps.save"
const save_path := "user://save_file.save"

var keymaps: Dictionary

var input_actions = {
	"Left": "Move left",
	"Right": "Move right",
	"Jump": "Jump",
	"Drop": "Drop",
	"Dash": "Dash",
	"Map": "Open map",
	"Quick Respawn": "Respawn",
	"Interact": "Interact"
}

func _ready():
	load_settings()
	for action in input_actions:
		if InputMap.action_get_events(action).size() != 0:
			keymaps[action] = InputMap.action_get_events(action)[0]
	load_keymaps()

func save_keymaps():
	for action in input_actions:
		if InputMap.action_get_events(action).size() > 0:
			keymaps[action] = InputMap.action_get_events(action)
	var file = FileAccess.open(keymap_save_path, FileAccess.WRITE)
	file.store_var(keymaps, true)
	
	file.close()

func load_keymaps():
	if !FileAccess.file_exists(keymap_save_path):
		save_keymaps()
		return
	var file = FileAccess.open(keymap_save_path, FileAccess.READ)
	var temp = file.get_var(true) as Dictionary
	file.close()
	
	for action in keymaps.keys():
		if temp.has(action):
			keymaps[action] = temp[action]
			InputMap.action_erase_events(action)
			for a in keymaps[action]:
				InputMap.action_add_event(action, a)

func save_settings():
	var file = FileAccess.open(settings_save_path, FileAccess.WRITE)
	file.store_var(OptionsMenu.sfx_slider_value)
	file.store_var(OptionsMenu.music_slider_value)
	file.store_var(OptionsMenu.fullscreen)
	file.store_var(OptionsMenu.borderless)
	file.store_var(OptionsMenu.use_mouse_for_menus)
	file.store_var(OptionsMenu.speedrun_timer)
	
	file.close()

func load_settings():
	if FileAccess.file_exists(settings_save_path):
		var file = FileAccess.open(settings_save_path, FileAccess.READ)
		OptionsMenu.sfx_slider_value = file.get_var()
		OptionsMenu.music_slider_value = file.get_var()
		OptionsMenu.fullscreen = file.get_var()
		OptionsMenu.borderless = file.get_var()
		OptionsMenu.use_mouse_for_menus = file.get_var()
		OptionsMenu.speedrun_timer = file.get_var()
		OptionsMenu.set_loaded_settings()
		
		file.close()

func save_game(world: Node):
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(world.checkpoint_room)
	file.store_var(world.checkpoint_pos)
	file.store_var(world.room_state_saved)
	file.store_var(world.player.has_dash)
	file.store_var(world.player.has_wallclimb)
	file.store_var(world.player.has_double_jump)
	file.store_var(world.player.has_freeze)
	file.store_var(world.player.has_blue_blocks)
	file.store_var(world.get_node("WorldMap/MapComps/RoomMap").get_used_cells(0))
	file.store_var(world.player.green_key_state)
	file.store_var(world.player.red_key_state)
	file.store_var(world.opened_doors_saved)
	file.store_var(world.player.apple_count_saved)
	file.store_var(world.bought_shop_items)
	file.store_var(world.player.amulet_pieces)
	file.store_var(world.player.has_bubble)
	file.store_var(world.red_boss_beaten)
	file.store_var(world.secret_boss_beaten)
	
	#map stuff
	file.store_var(world.player.has_item_map)
	file.store_var(world.get_node("WorldMap/MapComps/ItemMap").get_used_cells(0))
	file.store_var(world.player.has_opened_map)
	
	#staff roll stats
	file.store_var(world.get_speedrun_time())
	file.store_var(world.player.death_count)
	file.store_var(world.player.jump_count)
	file.store_var(world.completion_percentage)
	
	file.close()

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
		#world.player.apple_count = file.get_var()
		world.player.update_apple_count(file.get_var(), true, true)
		world.bought_shop_items.assign(file.get_var())
		world.get_node("Camera").enable_amulet_pieces(file.get_var())
		world.player.bubble_action(file.get_var())
		world.red_boss_beaten = file.get_var()
		world.secret_boss_beaten = file.get_var()
		
		#map stuff
		world.player.has_item_map = file.get_var()
		for apple_pos in file.get_var():
			world.get_node("WorldMap").add_apple_from_pos(apple_pos)
		world.player.has_opened_map = file.get_var()
		
		#staff roll stats
		world.set_speedrun_time(file.get_var())
		world.player.death_count = file.get_var()
		world.player.jump_count = file.get_var()
		world.completion_percentage = file.get_var()
		
		file.close()

