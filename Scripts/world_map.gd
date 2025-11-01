extends Node2D

@export var sfxs : AudioLibrary

var player
var world
var open

var latest_added_room: Vector2i

var in_subarea: bool = false

var map_debug_mode = false

var visited_rooms: int = 0
#var temp_apple_removal: Array[Vector2i]

func _ready():
	world = get_node("/root/World")
	player = get_node("/root/World/Player")
	$BGOverLay.modulate = Color(1, 1, 1, 0)
	$MapComps.modulate.a = 0
	open = false
	add_room(Vector2i(0, 0))
	add_room(Vector2i(1, 0))
	add_room(Vector2i(2, 0))
	
func _process(_delta):
	if open:
		#if player.velocity.x != 0:
		update_player_icon()

func update_player_icon():
	if !in_subarea:
		%PlayerIcon.position = Vector2(world.room_coords.x*38, world.room_coords.y*24-3) + player.position/8
		%PlayerIcon.scale.x = player.get_node("Sprite2D").scale.x
		#%RoomMap/PlayerIcon.position.y -= 3

func open_or_close():
	AudioManager.play_audio(sfxs.get_sfx("open"))
	if !open:
		world.prompts_to_show["MapPrompt"] = false
		if map_debug_mode:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		$BGOverLay.modulate = Color(0, 0, 0, 0.8)
		$MapComps.modulate.a = 1
		open = true
		update_player_icon()
		$MapComps/CompletionText.text = str(floor(world.completion_percentage), "%")
		player.x_speed = 55.0
	elif open:
		if map_debug_mode:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		$BGOverLay.modulate = Color(1, 1, 1, 0)
		$MapComps.modulate.a = 0
		open = false
		player.x_speed = 110.0
	
func add_room(room_coords: Vector2i):
	latest_added_room = Vector2i(-1, -1)
	if %RoomMap.get_cell_source_id(0, room_coords) == -1 and room_coords.x < 10:
		latest_added_room = room_coords
		%RoomMap.set_cell(0, room_coords, 0, room_coords, 0)
		visited_rooms += 1
		#if room_coords != Vector2i(0, 0) and room_coords != Vector2i(1, 0):
		world.add_to_completion_percentage("Room")
	
	if visited_rooms == 90:
		SteamManager.get_achivement("FullMap")

func add_apple_from_room(pos: Vector2):
	#if world.room_coords == latest_added_room:
		var item_map_pos = Vector2(38.0 * world.room_coords.x + pos.x/8.0, 24.0 * world.room_coords.y + pos.y/8.0 - 4) / 4.0
		%ItemMap.set_cell(0, Vector2i(item_map_pos.round()), 1, Vector2i(0, 0), 0)

func add_apple_from_pos(pos: Vector2i):
	%ItemMap.set_cell(0, pos, 1, Vector2i(0, 0), 0)

func remove_apple_from_map(pos: Vector2):
	var item_map_pos = (Vector2(38.0 * world.room_coords.x + pos.x/8.0, 24.0 * world.room_coords.y + pos.y/8.0 - 4) / 4.0).round()
	#temp_apple_removal.append(Vector2i(item_map_pos))
	#%ItemMap.erase_cell(0, Vector2i(item_map_pos))
	%ItemMap.set_cell(0, item_map_pos, 1, Vector2i(2, 1), 0)

func replace_invis_with_apple():
	for cell_coords in %ItemMap.get_used_cells(0):
		if %ItemMap.get_cell_atlas_coords(0, cell_coords) == Vector2i(2, 1):
			%ItemMap.set_cell(0, cell_coords, 1, Vector2i(0, 0), 0)

func delete_invis_apples():
	for cell_coords in %ItemMap.get_used_cells(0):
		if %ItemMap.get_cell_atlas_coords(0, cell_coords) == Vector2i(2, 1):
			%ItemMap.erase_cell(0, cell_coords)

#func return_apples_on_death():
	#for apple_pos in temp_apple_removal:
		##if %ItemMap.get_cell_source_id(0, apple_pos) == -1:
		#%ItemMap.set_cell(0, apple_pos, 1, Vector2i(0, 0), 0)
	#temp_apple_removal.clear()
#
#func clear_temp_apple_array():
	#temp_apple_removal.clear()

func enable_item_map():
	%ItemMap.visible = true
	$MapComps/CompletionText.visible = true

func debug_all_rooms():
	map_debug_mode = true
	for x in range(0, 10):
		for y in range(0, 9):
			add_room(Vector2(x, y))

func _input(event):
	if event is InputEventMouseButton and event.pressed and map_debug_mode and open:
		var mouse_pos = %ItemMap.get_local_mouse_position()
		var room = Vector2i(int(mouse_pos.x/38.0), int(mouse_pos.y/24.0))
		var room_pos = Vector2(fmod(mouse_pos.x, 38), fmod(mouse_pos.y, 24))
		player.position = room_pos*8
		world.change_room(room)
