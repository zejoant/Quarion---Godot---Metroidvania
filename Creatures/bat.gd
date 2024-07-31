extends CharacterBody2D

const speed = 90.0
var dir : Vector2#= Vector2(1, 0)

func _ready():
	pass
	
func _physics_process(_delta):
	
	#checks for floor and walls
	if $WallRay.is_colliding() or $VertRay.is_colliding():
		turn()
	
	velocity = speed * dir
	
	move_and_slide()

#turns the snake
func turn():
	if dir.x != 0:
		scale.x *= -1
	elif dir.y != 0:
		$VertRay.scale.y *= -1
	dir *= -1

func set_dir(dir_change):
	dir = dir_change
	$VertRay.scale.y *= -dir.y
	$WallRay.scale.x *= dir.x
	if dir.x != 0:
		$Sprite2D.scale.x *= dir.x
