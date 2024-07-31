extends TileMap

var source_id
var atlas_coord
var tile_data: TileData
var custom_data
const layer = 0
var tile_size := tile_set.tile_size.x
var world
var fade_tween

#static var erased_cells:= PackedVector2Array()
#static var erased_cells: Array[Vector4i]
static var blue_block := false

func _ready() -> void:
	#erased_cells = get_node("/root/World").collected_items
	world = get_tree().root.get_child(0)
	check_for_collected_tiles()
	check_for_functional_tiles()
	
	
#deletes any tiles that have been collected so they dont show up again (apples)
func check_for_collected_tiles():
	
	for cell in world.get_room_state():
		tile_data = get_cell_tile_data(0, cell)
		if tile_data is TileData:
			custom_data = tile_data.get_custom_data("Functional Tiles")
			if custom_data == "Collectable" or custom_data == "PBlueBlocks" or custom_data == "PWallClimb" or custom_data == "PDash" or custom_data == "PDoubleJump":
				erase_cell(layer, cell)


#looks through the tiles in layer 0 and if functional; replaces them with an object
func check_for_functional_tiles():
	for tile_pos in get_used_cells(layer): #loops through all tiles in the layer and gives each tiles pos
		tile_data = get_cell_tile_data(layer, tile_pos)
		custom_data = tile_data.get_custom_data("Functional Tiles")
		replace_tiles_with_object(tile_pos)


#replaces tile with the appropriate object
func replace_tiles_with_object(tile_pos):
	var scene_instance
	
	if custom_data == "Snake": #loads snake
		scene_instance = load("res://Creatures/snake.tscn").instantiate() 
	
	elif custom_data == "Lamp": #loads lamp
		scene_instance = load("res://lamp.tscn").instantiate() 
	
	elif custom_data == "Bat": #loads bat
		scene_instance = load("res://Creatures/bat.tscn").instantiate() 
		scene_instance.set_dir(get_tile_rotation(tile_pos))
	
	elif custom_data == "Collectable": #loads apples
		scene_instance = load("res://apple.tscn").instantiate() 
	
	#elif custom_data == "HPlatform": #loads horizontal platform
	#	scene_instance = load("res://Objects/h_platform.tscn").instantiate() 
	#	scene_instance.set_dir(get_tile_rotation(tile_pos))
	
	#elif custom_data == "CrumbleM" or custom_data == "CrumbleL" or custom_data == "CrumbleR": #loads crumbling platform
	#	scene_instance = load("res://Objects/crumble_platform.tscn").instantiate() 
	#	scene_instance.set_type(custom_data)
	
	#elif custom_data == "SpikeTrap":
		#scene_instance = load("res://Objects/spike_trap.tscn").instantiate() 
		#scene_instance.set_dir(get_tile_rotation(tile_pos))
	
	
	#adds the objects
	if scene_instance != null:
		erase_cell(0, tile_pos)#deletes placeholder tile
		scene_instance.position = Vector2(tile_pos.x*tile_size+tile_size/2.0, tile_pos.y*tile_size+tile_size/2.0)
		call_deferred("add_child", scene_instance)
	
	if custom_data == "Boundary":
		set_cell(layer, tile_pos, 1, Vector2i(1, 13), 0)
	
	elif world.get_node("Player").has_blue_blocks and custom_data == "BlueBlock": #loads solid blue blocks
		set_cell(layer, tile_pos, 0, Vector2i(38, 2), 0)


#reutrns a tiles rotation
func get_tile_rotation(p) -> Vector2:
	var tile_rotation = get_cell_alternative_tile(0, p)#rotation values
	if tile_rotation == 24576: #left
		return Vector2(-1, 0)
	elif tile_rotation == 12288: #down
		return Vector2(0, 1)
	elif tile_rotation == 20480: #right
		return Vector2(1, 0)
	return Vector2(0, -1) #up
	
func fade_foreground(fade_out):
	if fade_tween != null:
		fade_tween.stop()
	fade_tween = self.create_tween()
	
	if fade_out:
		fade_tween.tween_method(func(a): set_layer_modulate(4, a), Color(1, 1, 1, 1), Color(1,1,1,0),0.1)
		await fade_tween.finished
		set_layer_enabled(4, false)
	else:
		set_layer_enabled(4, true)
		fade_tween.tween_method(func(a): set_layer_modulate(4, a), Color(1, 1, 1, 0), Color(1,1,1,1),0.1)
