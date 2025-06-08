#@tool
extends StaticBody2D

@export var width : int = 1
@export var length : int = 2
@export var interval : float = 1
@export var offset : float = 0
@export var audio : bool = false
@export_enum("up", "down", "left", "right") var direction = "up"

var dir
var anim_tween
var animating = true
var origin: Vector2

func _ready():
	#position = Vector2(0, 0)
	origin = position
	setup()
	
	await self.create_tween().tween_interval(offset).finished
	animating = false
	
func _process(_delta):
	if !animating:
		animating = true
		anim_tween = self.create_tween()
		await anim_tween.tween_interval(interval).finished
		
		if audio:
			$AudioStreamPlayer2D.play()
			
		
		anim_tween = self.create_tween()
		#anim_tween.tween_interval(0.5)
		anim_tween.tween_method(extend_spike, 0, length*8, 0.05)
		anim_tween.tween_interval(interval)#1.2)
		await anim_tween.tween_method(extend_spike, length*8, 0, 0.10).finished
		
		animating = false

func extend_spike(distance):
	position.x = origin.x + distance*dir.x
	position.y = origin.y + distance*dir.y


func setup():
	$SpikeSprite.region_rect = Rect2(0, 0, width*8, 8)
	$BaseSprite.region_rect = Rect2(0, 8, width*8, 8)
	$BaseSprite.scale.y = length-1
	$BaseSprite.position.y = 8 + (length-2)*4
	
	$SpikeColl.position.y = 4*(length-1)
	$SpikeColl.scale.y = 0.125*(length*8-4)
	$SpikeColl.scale.x = 1 + (width-1)*2
	
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
	
