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
var room_state_saved = []
var opened_doors_saved = []

var previous_song_pos: float
var previous_song: String

var respawn_song_pos: float
var respawn_song: String

var bought_shop_items: Array[bool] 
var other_ui_open: bool = false

var secret_boss_beaten: bool = false
var red_boss_beaten: bool = false
var red_as_companion

#for changing room
var new_room_path
var old_room

#var timer: float = 0.0
var completion_percentage: float = 0

@onready var red_boss_room = preload("res://Rooms/room_10.tscn")
@onready var hermit_boss_room = preload("res://Rooms/room_50.tscn")

var changed_room_frames: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	cam_size = get_node("Camera").get_viewport_rect().size
	player = get_node("Player")
	$Camera/UILayer.visible = true
	#$Camera.hide_ui(true)
	bought_shop_items.resize(3)
	bought_shop_items.fill(false)
	changed_room_frames = 5
	
	#get_tree().set_auto_accept_quit(false)
	
	setup_arrays()
	
	if new_game:
		get_node("Camera").fade("000000", 1, 0, 0.2, 3)
		checkpoint_room = starting_position
		checkpoint_pos = Vector2(11.5*8, 19*8)#Vector2(cam_size.x/2, cam_size.y/2)
	else:
		load_data()
		temporary_actions_to_permanent()
		if player.green_key_state == "collected":
			$Camera.set_keys("Green")
		if player.red_key_state == "collected":
			$Camera.set_keys("Red")
		if player.has_item_map:
			$WorldMap.enable_item_map()
		
		if red_boss_beaten and secret_boss_beaten:
			add_red_as_companion()
		
		get_node("Camera").flash(1, 0, 0.2, 0.3)
		#await get_tree().create_timer(0.05, false).timeout
	
	player.position = checkpoint_pos
	$Camera/LensCircle.change_lens(checkpoint_room, true)
	
	room_coords = checkpoint_room
	var scene_instance = load("res://Rooms/room_" + str(room_coords.x) + str(room_coords.y) + ".tscn").instantiate()
	add_child(scene_instance)
	if new_game:
		get_tilemap().reset_water_tiles()
	
	$WorldMap.add_room(room_coords)
	get_tilemap().resume_animated_tiles()
	
	AudioManager.play_song(load("res://Music/Drephen Steek.mp3"))
	#if player.has_opened_map:
		#AudioManager.play_song(load("res://Music/Must Move.mp3"))
	#else:
		#AudioManager.play_song(load("res://Music/Temp_Ambience.mp3"))
	AudioManager.save_respawn_song()

func _process(_delta):
	changed_room_frames -= 1
	exit_room_check()
	
	if Input.is_action_just_pressed("Pause") and !other_ui_open:
		$CanvasLayer/PauseMenu.pause_menu()

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
	
	room_state_saved = room_state.duplicate(true)
	opened_doors_saved = opened_doors.duplicate(true)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		await get_tree().create_timer(0.1).timeout
		get_tree().call_deferred("quit")
	
#checks if the player has exited the room. If so it chnages the room and player pos.
func exit_room_check():
	var new_room_coords = room_coords
	var exit_dir = "right"
	
	if player.position.x >= cam_size.x:
		player.position.x = 1
		exit_dir = "right"
		new_room_coords.x += 1
	elif player.position.x <= 0:
		player.position.x = cam_size.x-1
		exit_dir = "left"
		new_room_coords.x -= 1
	
	elif player.position.y <= 0:
		player.position.y = cam_size.y-1
		exit_dir = "up"
		new_room_coords.y -= 1
	elif player.position.y >= cam_size.y:
		player.position.y = 1
		exit_dir = "down"
		new_room_coords.y += 1
	else:
		return
	
	new_room_coords = room_wrap_check(new_room_coords, exit_dir)
	if room_coords != new_room_coords:
		change_room(new_room_coords)
	
#function for changing the current room
func change_room(new_coords):
	if $Camera.p_up_window_open:
		$Camera.close_p_up_window(true)
	
	player.reset_particles()
	changed_room_frames = 5
	
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
		elif new_room_path == "res://Rooms/room_50.tscn": #to avoid hermit boss lagspike
			call_deferred("add_child", hermit_boss_room.instantiate()) #loads new room
		else:
			call_deferred("add_child", load(new_room_path).instantiate()) #loads new room
		$WorldMap.add_room(room_coords) #adds room to map
	
	if new_coords == Vector2(4, 4) and !player.has_opened_map:
		#AudioManager.fade_out_song(0.5)
		if Input.get_connected_joypads().size() > 0:
			$Player/OpenMapIndicator/KeyboardInput.visible = false
			$Player/OpenMapIndicator/ControllerInput.visible = true
		player.has_opened_map = true
		
		await get_tree().create_timer(0.6, false).timeout
		#AudioManager.play_song(load("res://Music/Must Move.mp3"))
		#AudioManager.save_respawn_song()
		#AudioManager.fade_in_song(0)
		await get_tree().create_timer(1.4, false).timeout
		self.create_tween().tween_property($Player/OpenMapIndicator, "modulate:a", 1, 0.3)
		await get_tree().create_timer(10, false).timeout
		self.create_tween().tween_property($Player/OpenMapIndicator, "modulate:a", 0, 1)

#saves the respawn position when grabbing a checkpoint
func save_checkpoint_room(pos):
	checkpoint_room = room_coords
	checkpoint_pos = Vector2(pos.x, pos.y-8)

func return_to_checkpoint():
	#load_data()
	#if checkpoint_room != room_coords:
	#player.position = Vector2(-100, -100)
	change_room(checkpoint_room)
	player.position = Vector2(checkpoint_pos.x, checkpoint_pos.y)

func temporary_actions_to_permanent(): #saves stuff like clicking on buttons and opening doors to be permanent
	opened_doors_saved = opened_doors.duplicate(true)
	room_state_saved = room_state.duplicate(true)
	player.apple_count_saved = player.apple_count

func revert_temporary_actions(): #revers actions like pressing buttons and openings doors if they have not been made permanent
	opened_doors = opened_doors_saved.duplicate(true)
	room_state = room_state_saved.duplicate(true)
	get_node("/root/World").completion_percentage -= 0.4*(player.apple_count-player.apple_count_saved)
	player.update_apple_count(player.apple_count_saved, true)

func get_tilemap() -> TileMap:
	var room = get_room()
	if room != null:
		return room.get_node("Tilemap")
	else:
		return null

func get_room() -> Node2D:
	var room = get_node_or_null("Room" + str(room_coords.x) + str(room_coords.y))
	if room:
		return room
	return self
	#return get_node_or_null("Room" + str(room_coords.x) + str(room_coords.y))

func room_wrap_check(new_room_coords, exit_dir) -> Vector2:
	$WorldMap.in_subarea = false
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
	
	elif room_coords == Vector2(0, 5) and exit_dir == "left":
		return Vector2(9, 5)
	elif room_coords == Vector2(9, 5) and exit_dir == "right":
		return Vector2(0, 5)
	
	elif room_coords == Vector2(9, 0) and exit_dir == "right":
		return Vector2(8, 0)
	
	elif room_coords == Vector2(0, 1) and exit_dir == "up": #apaolo
		player.position.x += 12*8
		$WorldMap.in_subarea = true
		return Vector2(0, 8)
	elif room_coords == Vector2(0, 8) and exit_dir == "down": #apaolo
		player.position.x -= 12*8
		return Vector2(0, 1)
	
	elif room_coords == Vector2(4, 7) and (exit_dir == "down" or exit_dir == "up"):
			return Vector2(4, 7)
		
	return(new_room_coords)

#saves permanent changes to a room such as collected items
func save_room_state(obj_state, permanent: bool = false):
	room_state[room_coords.x][room_coords.y].append(obj_state)
	if permanent:
		room_state_saved = room_state.duplicate(true)

#gets permanent changes to a room such as collected items
func get_room_state() -> Array:
	return room_state[room_coords.x][room_coords.y]

func get_speedrun_timer() -> Node:
	return get_node("Camera/UILayer/SpeedrunTimer")

func get_speedrun_time() -> float:
	return get_node("Camera/UILayer/SpeedrunTimer").timer

func set_speedrun_time(t: float):
	get_node("Camera/UILayer/SpeedrunTimer").timer = t

func add_red_as_companion():
	red_as_companion = load("res://Creatures/companion.tscn").instantiate()
	add_child(red_as_companion)

func reset_room_objects(group: String = "Resetable"):
	var room = get_room()
	if room:
		for node in room.get_children():
			if node.is_in_group(group):
				node.reset_to_default()

func add_to_completion_percentage(type: String):
	if type == "Apple": #50x
		completion_percentage += 0.4
	elif type == "Room": #78x
		completion_percentage += 2.0/13.0#0.15
	elif type == "PowerUp": #3x
		completion_percentage += 14
	elif type == "DoubleJump": #1x
		completion_percentage += 12
	elif type == "Freeze": #1x
		completion_percentage += 2
	elif type == "Shop": #2x
		completion_percentage += 2
	elif type == "AmuletPiece": #5x
		completion_percentage += 1
	elif type == "ItemMap": #1x
		completion_percentage += 1
	elif type == "Hermit": #1x
		completion_percentage += 2

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
