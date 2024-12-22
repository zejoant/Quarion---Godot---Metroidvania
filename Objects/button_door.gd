#@tool
extends StaticBody2D

@export var length : int = 3
@export var id : int
@export_enum("up", "down", "left", "right") var direction = "up"
@export_enum("open", "closed") var initial_state = "closed"
@export var sfxs : AudioLibrary

var opened_doors
var dir
var origin: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	origin = position
	setup()
	opened_doors = get_node("/root/World").opened_doors
	
	if opened_doors[id]:
		position = origin - length*8*dir
		visible = false

func open():
	await self.create_tween().tween_property(self, "position", origin - length*8*dir, 1).finished
	visible = false
	AudioManager.play_audio(sfxs.get_sfx("thump"))

func setup():
	$BottomSprite.position.y = 16 + (length-3)*4
	$BottomSprite.scale.y = length-2
	$BottomSprite.visible = true
	
	$DoorColl.scale.y = length
	$DoorColl.position.y = (length-1)*4
	
	if length == 2:
		$BottomSprite.visible = false
	
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
		
	#if initial_state == "closed":
	#	position = origin + length*8*dir
	#else:
	#	position = Vector2(0, 0)
