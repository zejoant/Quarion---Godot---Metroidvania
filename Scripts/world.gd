extends Node2D

var new_game = true
var paused = false
@onready var pause_menu = $CanvasLayer/PauseMenu

var room_coords : Vector2
var player
var cam_size

var checkpoint_room : Vector2
var checkpoint_pos : Vector2

#var sfx_array : Array
#var tag_array : Array

const save_path := "user://gamestate.save"
var room_state = []

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	room_state.resize(9) #X-dimension
	for x in 9: 
		room_state[x] = []
		room_state[x].resize(8) #Y-dimension
		for y in 8:
			room_state[x][y] = []
	
	
	cam_size = get_node("Camera").get_viewport_rect().size
	player = get_node("Player")
	
	if new_game:
		checkpoint_room = Vector2(5, 3)
		checkpoint_pos = Vector2(cam_size.x/2, cam_size.y/2)
	else:
		load_data()
	
	player.position = checkpoint_pos
	
	room_coords = checkpoint_room#Vector2(8, 3)#(0, 1) #starting room
	var scene_instance = load("res://Rooms/room_" + str(room_coords.x) + str(room_coords.y) + ".tscn").instantiate() 
	add_child(scene_instance)
	
	$WorldMap.add_room(room_coords)

func _process(_delta):
	exit_room_check()
	
	if Input.is_action_just_pressed("Pause"):
		pauseMenu()


func pauseMenu():
	if paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		pause_menu.hide()
		get_tree().paused = false
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().paused = true
		pause_menu.show()
	
	paused = !paused
	if $WorldMap.open:
		$WorldMap.open_or_close()
	
#checks if the player has exited the room. If so it chnages the room and player pos.
func exit_room_check():
	var new_room_coords = room_coords
	var exit_dir = "right"
	
	if player.position.x >= cam_size.x:
		player.position.x = 1
		exit_dir = "right"
		new_room_coords = Vector2(room_coords.x+1, room_coords.y)
	elif player.position.x <= 0:
		player.position.x = cam_size.x-1
		exit_dir = "left"
		new_room_coords = Vector2(room_coords.x-1, room_coords.y)
	
	elif player.position.y <= 0:
		player.position.y = cam_size.y-1
		exit_dir = "up"
		new_room_coords = Vector2(room_coords.x, room_coords.y-1)
	elif player.position.y >= cam_size.y:
		player.position.y = 1
		exit_dir = "down"
		new_room_coords = Vector2(room_coords.x, room_coords.y+1)
	
	if new_room_coords != room_coords:
		new_room_coords = room_wrap_check(new_room_coords, exit_dir)
		change_room(new_room_coords)
		
#function for changing the current room
func change_room(new_coords):
	var old_room = get_node("Room" + str(room_coords.x) + str(room_coords.y))
	old_room.call_deferred("free")
	
	room_coords = new_coords #updates room coords
	var new_room = load("res://Rooms/room_" + str(new_coords.x) + str(new_coords.y) + ".tscn").instantiate()
	call_deferred("add_child", new_room) #loads new room
	#add_child(new_room)
	
	#adds room to map
	$WorldMap.add_room(room_coords)


#saves the respawn position when grabbing a checkpoint
func save_checkpoint_room(pos):
	checkpoint_room = room_coords
	checkpoint_pos = Vector2(pos.x, pos.y-8)
	
	
#respawns the player duh
func respawn_player():
	#player.is_dead = true
	#player.modulate.g = 0.4
	#if checkpoint_room != room_coords:
	#	change_room(checkpoint_room)
	#player.position = Vector2(checkpoint_pos.x, checkpoint_pos.y)
	pass

func return_to_checkpoint():
	if checkpoint_room != room_coords:
		change_room(checkpoint_room)
	player.position = Vector2(checkpoint_pos.x, checkpoint_pos.y)

func get_tilemap() -> TileMap:
	var room = get_node_or_null("Room" + str(room_coords.x) + str(room_coords.y))
	if room != null:
		return room.get_node("Tilemap")
	else:
		return null


func room_wrap_check(new_room_coords, exit_dir) -> Vector2:
	if room_coords == Vector2(4, 6) and exit_dir == "down":
		return Vector2(4, 5)
	elif room_coords == Vector2(4, 5) and exit_dir == "up":
		return Vector2(4, 6)
	elif room_coords == Vector2(1, 6) and exit_dir == "down":
		return Vector2(1, 5)
		
	elif room_coords == Vector2(5, 1) and exit_dir == "up":
		return Vector2(5, 7)
	elif room_coords == Vector2(5, 7) and exit_dir == "down":
		return Vector2(5, 1)
	
	elif room_coords == Vector2(6, 6) and (exit_dir == "down" or exit_dir == "up"):
		if 240.0 < player.position.x and player.position.x < 262.0:
			return Vector2(6, 6)
	
	elif room_coords == Vector2(0, 5) and exit_dir == "left":
		return Vector2(8, 5)
	elif room_coords == Vector2(8, 5) and exit_dir == "right":
		return Vector2(0, 5)
	
	elif room_coords == Vector2(8, 0) and exit_dir == "right":
		return Vector2(7, 0)
		
	return(new_room_coords)

#saves permanent changes to a room such as collected items
func save_room_state(obj_state):
	room_state[room_coords.x][room_coords.y].append(obj_state)

#gets permanent changes to a room such as collected items
func get_room_state() -> Array:
	return room_state[room_coords.x][room_coords.y]

func save_game():
	SaveManager.save_game(self)
	#SaveData.checkpoint_room = checkpoint_room
	#SaveData.checkpoint_pos = checkpoint_pos
	#SaveData.room_state = room_state
	#SaveData.has_dash = player.has_dash
	#SaveData.has_wall_climb = player.has_wallclimb
	#SaveData.has_double_jump = player.has_double_jump
	#SaveData.has_freeze = player.has_freeze
	#SaveData.has_blue_blocks = player.has_blue_blocks
	#SaveData.map_rooms = $WorldMap/MapComps/RoomMap.get_used_cells(0)
	#SaveData.green_key_state = player.green_key_state
	#SaveData.red_key_state = player.red_key_state
	
	#var file = FileAccess.open(save_path, FileAccess.WRITE)
	#file.store_var(checkpoint_room)
	#file.store_var(checkpoint_pos)
	#file.store_var(room_state)
	#file.store_var(player.has_dash)
	#file.store_var(player.has_wallclimb)
	#file.store_var(player.has_double_jump)
	#file.store_var(player.has_freeze)
	#file.store_var(player.has_blue_blocks)
	#file.store_var($WorldMap/MapComps/RoomMap.get_used_cells(0))
	#file.store_var(player.green_key_state)
	#file.store_var(player.red_key_state)
	

func load_data():
	SaveManager.load_game(self)
	#if FileAccess.file_exists(save_path):
		#var file = FileAccess.open(save_path, FileAccess.READ)
		#checkpoint_room = file.get_var()
		#checkpoint_pos = file.get_var()
		#room_state = file.get_var()
		#player.has_dash = file.get_var()
		#player.has_wallclimb = file.get_var()
		#player.has_double_jump = file.get_var()
		#player.has_freeze = file.get_var()
		#player.has_blue_blocks = file.get_var()
		#for room in file.get_var():
			#$WorldMap.add_room(room)
		#player.green_key_state = file.get_var()
		#player.red_key_state = file.get_var()	
	#else:
		#cam_size = get_node("Camera").get_viewport_rect().size
		#checkpoint_room = Vector2(0, 1)
		#checkpoint_pos = Vector2(cam_size.x/2, cam_size.y/2)
		#player.has_dash = false
		#player.has_wallclimb = false
		#player.has_double_jump = false
		#player.has_freeze = false
		#player.has_blue_blocks = false
		#print("no data has been saved")
