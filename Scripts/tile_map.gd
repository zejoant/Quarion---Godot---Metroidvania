extends TileMap

@export var sfxs : AudioLibrary
@export var foreground: bool = false
var source_id
var atlas_coord
var tile_data: TileData
var custom_data
const layer = 0
var tile_size := tile_set.tile_size.x
var world
var fade_tween

var freeze_sfx_cooldown = 0
var rng = RandomNumberGenerator.new()
@onready var player = get_node_or_null("/root/World/Player")

var animated_tiles: PackedVector2Array = PackedVector2Array([
	Vector2i(2, 11), Vector2i(2, 12), Vector2i(2, 13), Vector2i(2, 14), Vector2i(2, 15), Vector2i(2, 16), Vector2i(2, 17), Vector2i(4, 17), Vector2i(6, 14), Vector2i(6, 15), Vector2i(6, 16), Vector2i(10, 11), Vector2i(10, 12), Vector2i(10, 14), Vector2i(10, 15), Vector2i(12, 14), Vector2i(12, 15), Vector2i(14, 11), Vector2i(28, 5), 
	Vector2i(16, 14), Vector2i(16, 15), Vector2i(16, 16), Vector2i(16, 17), Vector2i(18, 16), Vector2i(18, 17), Vector2i(19, 12), Vector2i(20, 15), Vector2i(20, 16), Vector2i(20, 17), Vector2i(22, 16), #crimson foliage
	Vector2i(34, 11), Vector2i(34, 13), Vector2i(34, 14), Vector2i(34, 15), Vector2i(39, 11), Vector2i(39, 13), Vector2i(39, 14), Vector2i(39, 15), Vector2i(44, 11), Vector2i(45, 11) #water
])

var freezable_tiles: PackedVector2Array = PackedVector2Array([Vector2i(34, 13),Vector2i(34, 14),Vector2i(34, 15),Vector2i(39, 13),Vector2i(39, 14),Vector2i(39, 15),Vector2i(44, 11),Vector2i(45, 11)])

static var blue_block := false

func _ready() -> void:
	world = get_node_or_null("/root/World") #or_null for purposes of testing scenes where world is not loaded
	if world and !foreground:
		check_for_collected_tiles()
		check_for_functional_tiles()
	
#deletes any tiles that have been collected so they dont show up again (apples)
func check_for_collected_tiles():
	for cell in world.get_room_state():
		custom_data = get_custom_data_with_coords(cell)
		if custom_data != "no tile data":
			erase_cell(layer, cell)

#looks through the tiles in layer 0 and if functional; replaces them with an object
func check_for_functional_tiles():
	for tile_pos in get_used_cells(layer): #loops through all tiles in the layer and gives each tiles pos
		custom_data = get_custom_data_with_coords(tile_pos)
		replace_tiles_with_object(tile_pos)


#replaces tile with the appropriate object
func replace_tiles_with_object(tile_pos):
	var scene_instance
	
	if custom_data == "Snake": #loads snake
		scene_instance = load("res://Creatures/snake.tscn").instantiate() 
	
	elif custom_data == "Lamp": #loads lamp
		scene_instance = load("res://Objects/lamp.tscn").instantiate() 
	
	elif custom_data == "Bat": #loads bat
		scene_instance = load("res://Creatures/bat.tscn").instantiate() 
		scene_instance.set_dir(get_tile_rotation(tile_pos)) 
	
	elif custom_data == "Collectable": #loads apples
		scene_instance = load("res://Objects/apple.tscn").instantiate()
	
	#adds the objects
	if scene_instance != null:
		erase_cell(0, tile_pos)#deletes placeholder tile
		scene_instance.position = Vector2(tile_pos.x*tile_size+tile_size/2.0, tile_pos.y*tile_size+tile_size/2.0)
		call_deferred("add_child", scene_instance)
	
	if custom_data == "Boundary":
		set_cell(layer, tile_pos, 1, Vector2i(1, 13), 0)
	
	elif player.has_blue_blocks and custom_data == "BlueBlock": #loads solid blue blocks
		set_cell(layer, tile_pos, 0, Vector2i(38, 2), 0)

#returns custom data based on rid
func get_custom_data_with_rid(rid: RID) -> String:
	return get_custom_data_with_coords(get_coords_for_body_rid(rid))

#returns custom data based on position
func get_custom_data_with_coords(tile_coords: Vector2) -> String:
	var tile_info = get_cell_tile_data(layer, tile_coords)
	if tile_info is TileData:
		return tile_info.get_custom_data("Functional Tiles")
	return "no tile data"

func is_tile_one_way(rid: RID) -> bool:
	var pos = get_coords_for_body_rid(rid)
	var cell_info = get_cell_tile_data(get_layer_for_body_rid(rid), pos)
	if cell_info != null and cell_info.get_collision_polygons_count(0):
		return cell_info.is_collision_polygon_one_way(0, 0)
	return false

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
		world.get_node("Camera/LensCircle").change_lens(world.room_coords, false, 1)
		fade_tween.tween_method(func(a): set_layer_modulate(4, a), Color(1, 1, 1, 1), Color(1,1,1,0),0.1)
		await fade_tween.finished
		set_layer_enabled(4, false)
	else:
		world.get_node("Camera/LensCircle").change_lens(world.room_coords, false, 2)
		set_layer_enabled(4, true)
		fade_tween.tween_method(func(a): set_layer_modulate(4, a), Color(1, 1, 1, 0), Color(1,1,1,1),0.1)
		
func change_water_tiles():
	for atlas_coords in freezable_tiles:
		tile_data = tile_set.get_source(0).get_tile_data(atlas_coords, 0)
		if tile_data:
			tile_data.add_collision_polygon(0)
			tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-4, -4), Vector2(4, -4), Vector2(4, 4), Vector2(-4, 4)]))

func reset_water_tiles():
	for atlas_coords in freezable_tiles:
		tile_data = tile_set.get_source(0).get_tile_data(atlas_coords, 0)
		if tile_data:
			tile_data.set_collision_polygons_count(0, 0)

func pause_animated_tiles(): #dum ass animatedtexture resource not pausing when process is paused
	var source = tile_set.get_source(0) as TileSetAtlasSource
	for atlas_coords in animated_tiles:
		source.set_tile_animation_speed(atlas_coords, 0.0001)

func resume_animated_tiles(): #dum ass animatedtexture resource not pausing when process is paused
	var source = tile_set.get_source(0) as TileSetAtlasSource
	for atlas_coords in animated_tiles:
		source.set_tile_animation_speed(atlas_coords, 1)

func freeze_water_tile(body_rid):
	var tile_coords = get_coords_for_body_rid(body_rid)
	var tile_info = get_cell_tile_data(0, tile_coords)
	if !tile_info:
		return
	var c_data = tile_info.get_custom_data("Functional Tiles")
	if c_data == "Water" or c_data == "WaterFall":
		freeze_sfx_cooldown -= 1
		if freeze_sfx_cooldown <= 0:
			AudioManager.play_audio(sfxs.get_sfx("freeze"), rng.randf_range(1, 2), rng.randf_range(0.9, 1))
			freeze_sfx_cooldown = 2
		erase_cell(0, tile_coords)
		set_cell(1, tile_coords, 0, Vector2i(43, 4), 0)
		
		#ice breaks after a short time, not sure if ill keep it in
		#await self.create_tween().tween_interval(0.2).finished
		#set_cell(1, tile_coords, 0, Vector2i(43, 5), 0)
		#await self.create_tween().tween_interval(0.2).finished
		#set_cell(1, tile_coords, 0, Vector2i(42, 5), 0)
		#await self.create_tween().tween_interval(0.2).finished
		#erase_cell(1, tile_coords)
