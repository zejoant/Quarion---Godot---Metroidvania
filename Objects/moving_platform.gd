#@tool
extends AnimatableBody2D

var move_dir
@export var speed: float = 1
@export_enum("up", "down", "left", "right") var direction = "up"
@export_enum("horizontal", "vertical") var type = "horizontal"
@export var width : int = 3

@onready var ray2 = $Rays/WallRay2

var first_frame = true

func _ready():
	$CollisionShape2D.scale.x = width
	$CenterSprite.scale.x = width-2
	$RightSprite.position.x = 8 + 4*(width-3)
	$LeftSprite.position.x = -8 - 4*(width-3)
	
	if direction == "up":
		$Rays.scale.y = -1
		$Rays.rotation_degrees = 0
		move_dir = Vector2(0, -1)
	elif direction == "down":
		$Rays.scale.y = 1
		$Rays.rotation_degrees = 0
		move_dir = Vector2(0, 1)
	elif direction == "left":
		$Rays.rotation_degrees = 90
		$Rays.scale.y = width
		move_dir = Vector2(-1, 0)
	elif direction == "right":
		$Rays.rotation_degrees = -90
		$Rays.scale.y = width
		move_dir = Vector2(1, 0)
	
	if type == "vertical":
		rotation_degrees = -90
		$Rays.rotation_degrees += 90
		$Rays.scale.x /= abs($Rays.scale.x)
		$Rays.scale.y /= abs($Rays.scale.y)
		if direction == "up" or direction == "down":
			$Rays.scale.y *= width
	elif type == "horizontal":
		rotation_degrees = 0

func _physics_process(_delta):
	if first_frame:
		first_frame = false
		return
	
	if !visible:
		visible = true
	
	position += move_dir * speed
	if $Rays/WallRay.is_colliding():
		turn()
	elif ray2.is_colliding() and ray2.get_collider() is TileMap:
		if ray2.get_collider().get_custom_data_with_rid(ray2.get_collider_rid()) == "Boundary":
			turn()

func turn():
	move_dir *= -1
	$Rays.scale *= -1

