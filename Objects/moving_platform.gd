#@tool
extends StaticBody2D

var move_dir
@export_enum("up", "down", "left", "right") var direction = "up"
@export_enum("horizontal", "vertical") var type = "horizontal"
@export var width : int = 3

func _ready():
	setup()

func _process(_delta):
	position += move_dir
	if $WallRay.is_colliding():
		turn()

func turn():
	move_dir *= -1
	$WallRay.scale *= -1

func setup():
	$CollisionShape2D.scale.x = width
	$CenterSprite.scale.x = width-2
	$RightSprite.position.x = 8 + 4*(width-3)
	$LeftSprite.position.x = -8 - 4*(width-3)
	
	if direction == "up":
		$WallRay.scale.y = -1
		$WallRay.rotation_degrees = 0
		move_dir = Vector2(0, -1)
	elif direction == "down":
		$WallRay.scale.y = 1
		$WallRay.rotation_degrees = 0
		move_dir = Vector2(0, 1)
	elif direction == "left":
		$WallRay.rotation_degrees = 90
		$WallRay.scale.y = width
		move_dir = Vector2(-1, 0)
	elif direction == "right":
		$WallRay.rotation_degrees = -90
		$WallRay.scale.y = width
		move_dir = Vector2(1, 0)
	
	if type == "vertical":
		rotation_degrees = -90
		$WallRay.rotation_degrees += 90
		$WallRay.scale.x /= abs($WallRay.scale.x)
		$WallRay.scale.y /= abs($WallRay.scale.y)
		if direction == "up" or direction == "down":
			$WallRay.scale.y *= width
	elif type == "horizontal":
		rotation_degrees = 0
