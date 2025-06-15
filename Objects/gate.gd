#@tool
extends StaticBody2D

@export var length : int = 3
@export var audio : bool = false
@export_enum("up", "down", "left", "right") var direction = "up"
@export_enum("open", "closed") var initial_state = "open"

var dir
var anim_tween
var origin: Vector2

func _ready():
	#position = Vector2(0, 0)
	origin = position
	setup()

func open():
	anim_tween = self.create_tween()
	anim_tween.tween_method(move_gate, length*8, 0, 0.10)

func close(instant: bool = false):
	if !instant:
		anim_tween = self.create_tween()
		anim_tween.tween_method(move_gate, 0, length*8, 0.05)
		$AudioStreamPlayer2D.play()
	else:
		position += dir*length*8

func move_gate(distance):
	position.x = origin.x + distance*dir.x
	position.y = origin.y + distance*dir.y


func setup():
	$BaseSprite.scale.y = length-1
	$BaseSprite.position.y = 8 + (length-2)*4
	
	$GateColl.position.y = (length-1)*4
	$GateColl.scale.y = length
	
	if direction == "up":
		rotation_degrees = 0
		dir = Vector2(0, -1)
	if direction == "down":
		rotation_degrees = 180
		dir = Vector2(0, 1)
	if direction == "left":
		rotation_degrees = -90
		dir = Vector2(-1, 0)
	if direction == "right":
		rotation_degrees = 90
		dir = Vector2(1, 0)
	
	if initial_state == "closed":
		move_gate(length*8)
	
