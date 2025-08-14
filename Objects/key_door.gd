#@tool
extends StaticBody2D

@export var sfxs : AudioLibrary
@export var length : int = 3
#@export var audio : bool = false
@export_enum("up", "down", "left", "right") var direction = "up"
@export_enum("open", "closed") var initial_state = "closed"
@export_enum("green", "red") var color = "green"
@export var glow_size = 5
@export var glow_time = 0.5

var dir
var anim_tween
var origin: Vector2
var player

func _ready():
	origin = position
	player = get_node("/root/World/Player")
	if color == "green" and player.green_key_state == "used":
		queue_free()
	elif color == "red" and player.red_key_state == "used":
		queue_free()
	else:
		setup()


func open():
	await self.create_tween().tween_property(self, "position", origin, 1).finished
	visible = false
	AudioManager.play_audio(sfxs.get_sfx("thump"))

func close():
	self.create_tween().tween_property(self, "position", origin + length*8*dir, 1)

func glow():
	AudioManager.play_audio(sfxs.get_sfx("glow"))
	$OpenGlow.visible = true
	self.create_tween().tween_property($OpenGlow, "modulate:a", 0, glow_time)
	self.create_tween().tween_property($OpenGlow, "scale", Vector2(glow_size, glow_size), glow_time)

func setup():
	$BottomSprite.position.y = (length-1)*8
	$BottomSprite.visible = true
	$ColorSprite.region_rect.size.y = (length-2)*8
	$ColorSprite.position.y = (length-1)*4
	$DoorColl.scale.y = length
	$DoorColl.position.y = (length-1)*4
	
	if length == 2:
		$BottomSprite.visible = false
		$ColorSprite.region_rect.size.y = 8
		$ColorSprite.position.y += 4
	
	if color == "red":
		$ColorSprite.region_rect.position.x = 32
		$OpenGlow.modulate = Color8(196, 76, 76, 189)
	else:
		$ColorSprite.region_rect.position.x = 24
		$OpenGlow.modulate = Color8(120, 180, 92, 189)
		
	
	if direction == "up":
		rotation = 0
		dir = Vector2(0, -1)
	elif direction == "down":
		rotation = PI
		dir = Vector2(0, 1)
	elif direction == "left":
		rotation_degrees = -90
		dir = Vector2(-1, 0)
	elif direction == "right":
		rotation_degrees = 90
		dir = Vector2(1, 0)
	
	if initial_state == "closed":
		position = origin + length*8*dir
	else:
		position = Vector2(0, 0)
