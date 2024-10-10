extends Node2D

var player
var world
var open

var item_positions: Array
var item_atlas_coords: Array

func _ready():
	world = get_node("/root/World")
	player = get_node("/root/World/Player")
	$BGOverLay.modulate = Color(1, 1, 1, 0)
	%RoomMap.modulate.a = 0
	%ItemMap.modulate.a = 0
	open = false
	
	for pos in %ItemMap.get_used_cells(0): #clears ItemMap and save each items position and type
		item_positions.append(pos*4)
		item_atlas_coords.append(%ItemMap.get_cell_atlas_coords(0, pos, false))
		%ItemMap.erase_cell(0, pos)
	
func _process(_delta):
	if open:
		if player.velocity.x != 0:
			update_player_icon()

func update_player_icon():
	%RoomMap/PlayerIcon.position = Vector2(world.room_coords.x*38, world.room_coords.y*24) + player.position/8
	%RoomMap/PlayerIcon.position.y -= 3

func open_or_close():
	if !open:
		$BGOverLay.modulate = Color(0, 0, 0, 0.8)
		%RoomMap.modulate.a = 1
		%ItemMap.modulate.a = 1
		open = true
		update_player_icon()
		update_items()
		player.x_speed = 55.0
	elif open:
		$BGOverLay.modulate = Color(1, 1, 1, 0)
		%RoomMap.modulate.a = 0
		%ItemMap.modulate.a = 0
		open = false
		player.x_speed = 110.0
	
func add_room(room_coords: Vector2):
	%RoomMap.set_cell(0, room_coords, 0, room_coords, 0)
	update_items()

func update_items():
	for pos in item_positions:
		var room_pos = Vector2(int(pos.x/38), int(pos.y/24))
		if %RoomMap.get_used_cells(0).has(Vector2i(room_pos)):
			%ItemMap.set_cell(0, pos/4, 1, item_atlas_coords[item_positions.find(pos, 0)], 0)
		elif item_atlas_coords[item_positions.find(pos, 0)] == Vector2i(2, 0):
			%ItemMap.set_cell(0, pos/4, 1, item_atlas_coords[item_positions.find(pos, 0)], 0)

func remove_item():
	var min_dist = 999999
	var dist
	var selected_item: Vector2i #collected item to be removed
	
	update_player_icon()
	for item_pos in %ItemMap.get_used_cells(0): #find item
		dist = Vector2(item_pos).distance_to(%ItemMap.local_to_map(%PlayerIcon.position))
		if dist < min_dist:
			min_dist = dist
			selected_item = item_pos
	
	#remove item
	var index = item_positions.find(selected_item*4, 0)
	item_positions.remove_at(index)
	item_atlas_coords.remove_at(index)
	%ItemMap.erase_cell(0, selected_item)
	#if open:
	#	update_items()
