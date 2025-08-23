extends Node2D

var player
@export_range(0, 20) var size: float = 1
@export var follow_player : bool = true
@export var non_follow_pos: Vector2 = Vector2(0, 0)

var tween
const default_size = Vector2(10, 10)
var action: String = "to_light"

# Called when the node enters the scene tree for the first time.
func _ready():
	if follow_player:
		player = get_node_or_null("/root/World/Player")
		if !player:
			follow_player = false
	#scale = Vector2(size, size)

func _physics_process(_delta):
	if follow_player:
		global_position = Vector2i(player.position)
		#position = player.position
	#else:
	#	position = non_follow_pos
		#position = Vector2(152, 96)

func change_lens(room_coords, instant: bool = false, behind_foreground: int = 0):
	follow_player = true
	if tween:
		if tween.is_running() and action == "to_light" and !behind_foreground:
			scale = default_size
		if tween.is_running() and action == "to_dark" and !behind_foreground:
			scale = Vector2(0.1, 0.1)
		tween.kill()
	
	var lens_size: float = 0
	#if behind_foreground == 1:
		#lens_size = 2
	
	#rooms under wrecked ship
	if room_coords == Vector2i(0, 1):
		lens_size = 2
	elif room_coords == Vector2i(1, 1):
		lens_size = 1.3
	
	#shop room
	elif room_coords == Vector2i(5, 4):
		lens_size = 1.3
	
	#rolling boulder rooms
	elif room_coords == Vector2i(1, 6):
		lens_size = 2
	elif room_coords == Vector2i(2, 6):
		lens_size = 2
	
	#apaolo room
	elif room_coords == Vector2i(10, 0):
		lens_size = 3
	
	#behind blue key door rooms
	elif room_coords == Vector2i(0, 5):
		lens_size = 3
	elif room_coords == Vector2i(9, 5):
		lens_size = 3
	elif room_coords == Vector2i(8, 5):
		lens_size = 2.5
		
	#delapitated lab section
	elif room_coords == Vector2i(0, 6):
		lens_size = 4.2
	elif room_coords.y == 7 and room_coords.x <= 2:
		lens_size = 4.2
	elif room_coords.y == 8 and room_coords.x <= 5:
		lens_size = 4.2
		if room_coords.x == 4:
			follow_player = false
			position = Vector2(0, 0)
			lens_size = 3.5
	
	# after double jump, room wrap
	elif room_coords == Vector2i(8, 8):
		follow_player = false
		position = Vector2(0, 0)
		instant = true
	
	#bottom left corner amulet piece room
	elif room_coords == Vector2i(9, 8):
		lens_size = 2.5
	
	#the 2 fall rooms
	elif room_coords == Vector2i(5, 6) or room_coords == Vector2i(5, 7):
		follow_player = false
		position = Vector2(0, 0)
		instant = true
	
	elif room_coords.x == 10 and room_coords.y > 0: #road to phantom flame
		follow_player = false
		position = Vector2(0, 0)
	
	if behind_foreground == 1:
		lens_size = 2
		follow_player = true
		instant = false
	
	if !instant:
		tween = self.create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		
		if lens_size != 0:
			action = "to_dark"
			if !behind_foreground:
				$CoverRect.modulate.a = 1
				if scale == default_size:
					scale = Vector2(0.1, 0.1)
			tween.parallel().tween_property($CoverRect, "modulate:a", 0, 2)
			tween.parallel().tween_property(self, "scale", Vector2(lens_size, lens_size), 1.5)
		else:
			$CoverRect.modulate.a = 0
			action = "to_light"
			tween.parallel().tween_property(self, "scale", default_size, 2.5)
	else:
		if lens_size != 0:
			scale = Vector2(lens_size, lens_size)
		else:
			scale = default_size
