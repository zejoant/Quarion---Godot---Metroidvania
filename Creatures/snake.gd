extends CharacterBody2D

const x_speed = 90.0
var dir = 1

func _ready():
	pass
	
func _physics_process(_delta):
	
	#checks for floor and walls
	if $WallRay.is_colliding() or !$FloorRay.is_colliding():
		turn()
	
	velocity.x = x_speed * dir
	move_and_slide()

#turns the snake
func turn():
	dir *= -1
	scale.x *= -1
