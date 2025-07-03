extends Node2D

@export var starting_position = Vector2(2, 1)#Vector2(2, 1)

var new_game = true

var room_coords : Vector2
var player
var cam_size

var checkpoint_room : Vector2
var checkpoint_pos : Vector2

var room_state = []
var opened_doors = []

var previous_song_pos: float
var previous_song: String

var respawn_song_pos: float
var respawn_song: String

var bought_shop_items: Array[bool] 
var other_ui_open: bool = false

#for changing room
var new_room_path
var old_room

var timer: float = 0.0
var completion_percentage: float = 0

@onready var red_boss_room = preload("res://Rooms/room_10.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cam_size = get_node("Camera").get_viewport_rect().size
	player = get_node("Player")
	$Camera/UILayer/UIContainer.visible = true
	bought_shop_items.resize(3)
	bought_shop_items.fill(false)
	
	#get_tree().set_auto_accept_quit(false)
	
	setup_arrays()
	
	if new_game:
		get_node("Camera").fade("000000", 1, 0, 0.2, 3)
		checkpoint_room = starting_position
		checkpoint_pos = Vector2(11.5*8, 19*8)#Vector2(cam_size.x/2, cam_size.y/2)
	else:
		load_data()
		$Camera/UILayer/UIContainer/AppleCount.text = str(player.apple_count)
		if player.green_key_state == "collected":
			$Camera.set_keys("Green")
		if player.red_key_state == "collected":
			$Camera.set_keys("Red")
		if player.has_item_map:
			$WorldMap/MapComps/ItemMap.visible = true
		
		get_node("Camera").flash(1, 0, 0.2, 0.3)
		await get_tree().create_timer(0.05, false).timeout
	
	player.position = checkpoint_pos
	$Camera/LensCircle.change_lens(checkpoint_room, true)
	
	room_coords = checkpoint_room#Vector2(8, 3)#(0, 1) #starting room
	var scene_instance = load("res://Rooms/room_" + str(room_coords.x) + str(room_coords.y) + ".tscn").instantiate() 
	add_child(scene_instance)
	
	$WorldMap.add_room(room_coords)
	
	AudioManager.play_song(load("res://Music/746887_BITTRIP-REMIX-02-CORE.mp3"))
	AudioManager.save_respawn_song()
	#$MusicPlayer.stream = load("res://Music/746887_BITTRIP-REMIX-02-CORE.mp3")
	#$MusicPlayer.play()
	#respawn_song = $MusicPlayer.stream.resource_path

func _process(delta):
	exit_room_check()
	
	if Input.is_action_just_pressed("Pause") and !other_ui_open:
		$CanvasLayer/PauseMenu.pause_menu()
		#pauseMenu()
	
	timer += delta #time in seconds, with 3 decimal places
	#$Label.text = String.num(completion_percentage, 3) 

func setup_arrays():
	var map_width = 10
	var map_height = 9
	
	room_state.resize(map_width) #X-dimension
	for x in map_width: 
		room_state[x] = []
		room_state[x].resize(map_height) #Y-dimension
		for y in map_height:
			room_state[x][y] = []
	
	opened_doors.resize(100) #setup opened_doors array
	opened_doors.fill(false)

#func _notification(what):
	#if what == NOTIFICATION_WM_CLOSE_REQUEST:
		#save_game()
		#await get_tree().create_timer(0.1).timeout
		#get_tree().call_deferred("quit")
	
#checks if the player has exited the room. If so it chnages the room and player pos.
func exit_room_check():
	var new_room_coords = room_coords
	var exit_dir = "right"
	
	#var t0 = Time.get_ticks_msec()
	if player.position.x >= cam_size.x:
		player.position.x = 1
		exit_dir = "right"
		new_room_coords.x += 1# = Vector2(room_coords.x+1, room_coords.y)
	elif player.position.x <= 0:
		player.position.x = cam_size.x-1
		exit_dir = "left"
		new_room_coords.x -= 1# = Vector2(room_coords.x-1, room_coords.y)
	
	elif player.position.y <= 0:
		player.position.y = cam_size.y-1
		exit_dir = "up"
		new_room_coords.y -= 1# = Vector2(room_coords.x, room_coords.y-1)
	elif player.position.y >= cam_size.y:
		player.position.y = 1
		exit_dir = "down"
		new_room_coords.y += 1# = Vector2(room_coords.x, room_coords.y+1)
	else:
		return
	
	#if new_room_coords != room_coords:
	new_room_coords = room_wrap_check(new_room_coords, exit_dir)
	if room_coords != new_room_coords:
		change_room(new_room_coords)
	
	#print(Time.get_ticks_msec()-t0)
		
#function for changing the current room
func change_room(new_coords):
		
	if room_coords != new_coords:
		$Camera/LensCircle.change_lens(new_coords)
	new_room_path = "res://Rooms/room_" + str(new_coords.x) + str(new_coords.y) + ".tscn"
	old_room = get_node_or_null("Room" + str(room_coords.x) + str(room_coords.y))
	room_coords = new_coords #updates room coords
	
	if old_room: #if the room was never loaded (because it did not exist)
		old_room.call_deferred("free")
	old_room = null
	
	if ResourceLoader.exists(new_room_path): #if the entered room exists in files (safety precation for oob)
		if new_room_path == "res://Rooms/room_10.tscn": #to avoid red boss room lagspike
			call_deferred("add_child", red_boss_room.instantiate()) #loads new room
		else:
			call_deferred("add_child", load(new_room_path).instantiate()) #loads new room
		$WorldMap.add_room(room_coords) #adds room to map

#saves the respawn position when grabbing a checkpoint
func save_checkpoint_room(pos):
	checkpoint_room = room_coords
	checkpoint_pos = Vector2(pos.x, pos.y-8)

func return_to_checkpoint():
	#load_data()
	#if checkpoint_room != room_coords:
	change_room(checkpoint_room)
	player.position = Vector2(checkpoint_pos.x, checkpoint_pos.y)

func get_tilemap() -> TileMap:
	var room = get_node_or_null("Room" + str(room_coords.x) + str(room_coords.y))
	if room != null:
		return room.get_node("Tilemap")
	else:
		return null


func room_wrap_check(new_room_coords, exit_dir) -> Vector2:
	if room_coords == Vector2(5, 6) and exit_dir == "down":
		return Vector2(5, 5)
	elif room_coords == Vector2(5, 5) and exit_dir == "up":
		return Vector2(5, 6)
	elif room_coords == Vector2(2, 6) and exit_dir == "down":
		return Vector2(2, 5)
		
	elif room_coords == Vector2(6, 1) and exit_dir == "up":
		return Vector2(6, 7)
	elif room_coords == Vector2(6, 7) and exit_dir == "down":
		return Vector2(6, 1)
	
	elif room_coords == Vector2(7, 6) and (exit_dir == "down" or exit_dir == "up"):
		if 240.0 < player.position.x and player.position.x < 262.0:
			return Vector2(7, 6)
	
	elif room_coords == Vector2(1, 5) and exit_dir == "left": #should be changed after moving room
		return Vector2(9, 5)
	elif room_coords == Vector2(9, 5) and exit_dir == "right":
		return Vector2(1, 5)
	
	elif room_coords == Vector2(9, 0) and exit_dir == "right":
		return Vector2(8, 0)
	elif room_coords == Vector2(8, 0) and exit_dir == "left":
		return Vector2(9, 0)
	
	elif room_coords == Vector2(0, 1) and exit_dir == "up": #rick
		player.position.x += 12*8
		$WorldMap.in_subarea = true
		return Vector2(0, 8)
	elif room_coords == Vector2(0, 8) and exit_dir == "down": #rick
		player.position.x -= 12*8
		$WorldMap.in_subarea = false
		return Vector2(0, 1)
	
	elif room_coords == Vector2(4, 7) and (exit_dir == "down" or exit_dir == "up"):
			return Vector2(4, 7)
		
	return(new_room_coords)

#saves permanent changes to a room such as collected items
func save_room_state(obj_state):
	room_state[room_coords.x][room_coords.y].append(obj_state)

#gets permanent changes to a room such as collected items
func get_room_state() -> Array:
	return room_state[room_coords.x][room_coords.y]

func save_game():
	AudioManager.save_respawn_song()
	SaveManager.save_game(self)
	
func load_data():
	SaveManager.load_game(self)
	
	
func end_game():
	$Player.can_move = false
	$Camera.fade("000000", 1, 0.5, 1, 0.5)
	await get_tree().create_timer(0.7).timeout
	$Player.visible = false
