extends Node2D

@export var starting_position = Vector2(2, 4)#Vector2(2, 1)

var new_game = true
var paused = false
@onready var pause_menu = $CanvasLayer/PauseMenu

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

var appleCount: int

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cam_size = get_node("Camera").get_viewport_rect().size
	player = get_node("Player")
	$Camera/UIContainer.visible = true
	
	setup_arrays()
	
	if new_game:
		get_node("Camera").fade("000000", 1, 0, 0.2, 2)
		checkpoint_room = starting_position
		checkpoint_pos = Vector2(cam_size.x/2, cam_size.y/2)
	else:
		load_data()
		$Camera/UIContainer/AppleCount.text = str(appleCount)
		if player.green_key_state == "collected":
			$Camera.set_keys("Green")
		if player.red_key_state == "collected":
			$Camera.set_keys("Red")
		
		get_node("Camera").flash(1, 0, 0.2, 0.3)
		await get_tree().create_timer(0.05).timeout
	
	player.position = checkpoint_pos
	
	room_coords = checkpoint_room#Vector2(8, 3)#(0, 1) #starting room
	var scene_instance = load("res://Rooms/room_" + str(room_coords.x) + str(room_coords.y) + ".tscn").instantiate() 
	add_child(scene_instance)
	
	$WorldMap.add_room(room_coords)
	
	$MusicPlayer.stream = load("res://Music/746887_BITTRIP-REMIX-02-CORE.mp3")
	$MusicPlayer.play()
	
func incrementAppleCount():
	appleCount += 1
	$Camera/UIContainer/AppleCount.text = str(appleCount)

func switch_music(new_song_path):
	previous_song = $MusicPlayer.stream.resource_path
	previous_song_pos = $MusicPlayer.get_playback_position()
	$MusicPlayer.stream = load(new_song_path)
	$MusicPlayer.play()

func resume_previous_music():
	var temp_path = $MusicPlayer.stream.resource_path
	var temp_pos = $MusicPlayer.get_playback_position()
	
	$MusicPlayer.stream = load(previous_song)
	$MusicPlayer.play(previous_song_pos)
	
	previous_song = temp_path
	previous_song_pos = temp_pos

func resume_respawn_music():
	$MusicPlayer.stream = load(respawn_song)
	$MusicPlayer.play(respawn_song_pos)

func setup_arrays():
	var map_width = 10
	var map_height = 8
	
	room_state.resize(map_width) #X-dimension
	for x in map_width: 
		room_state[x] = []
		room_state[x].resize(map_height) #Y-dimension
		for y in map_height:
			room_state[x][y] = []
	
	opened_doors.resize(100) #setup opened_doors array
	opened_doors.fill(false)

func _process(_delta):
	exit_room_check()
	
	if Input.is_action_just_pressed("Pause"):
		pauseMenu()
		
	#var window_size = DisplayServer.window_get_size()
	#var screen_factor : float
	#if(window_size.x <= window_size.y):
		#screen_factor = window_size.x/304.0
		#window_size.y = 192.0*screen_factor
	#elif(window_size.x > window_size.y):
		#screen_factor = window_size.y/192.0
		#window_size.x = 304.0*screen_factor
	##print((window_size.x/304.0 + window_size.y/192.0)/2)
	##print(get_viewport().get_visible_rect().size)
	#'if(player != null):
		#player.get_node("CanvasLayer/ColorRect").material.set_shader_parameter("pix_per_pix", (window_size.x/304.0 + window_size.y/192.0)/2)
	#$CanvasLayer/LightShader.material.set_shader_parameter("player_screen_pos", self.global_position)


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
	var new_room_path = "res://Rooms/room_" + str(new_coords.x) + str(new_coords.y) + ".tscn"
	var old_room = get_node_or_null("Room" + str(room_coords.x) + str(room_coords.y))
	room_coords = new_coords #updates room coords
	
	if old_room: #if the room was never loaded (because it did not exist)
		old_room.call_deferred("free")
	
	if ResourceLoader.exists(new_room_path): #if the entered room exists in files (safety precation for oob)
		var new_room = load(new_room_path).instantiate()
		call_deferred("add_child", new_room) #loads new room
		$WorldMap.add_room(room_coords) #adds room to map
	


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
		
	return(new_room_coords)

#saves permanent changes to a room such as collected items
func save_room_state(obj_state):
	room_state[room_coords.x][room_coords.y].append(obj_state)

#gets permanent changes to a room such as collected items
func get_room_state() -> Array:
	return room_state[room_coords.x][room_coords.y]

func save_game():
	respawn_song = $MusicPlayer.stream.resource_path
	respawn_song_pos = $MusicPlayer.get_playback_position()
	SaveManager.save_game(self)
func load_data():
	SaveManager.load_game(self)
	
