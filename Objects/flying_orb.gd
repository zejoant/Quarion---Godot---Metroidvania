extends StaticBody2D

@export var speed : Vector2
@export var acceleration : Vector2
@export var friction_x : bool
@export var friction_y : bool

var last_speed: Vector2

func _ready():
	pass

func _physics_process(_delta):
	$Sprite2D.rotation += PI/4
	position += speed
	speed += acceleration
	
	if friction_x and last_speed.x*speed.x < 0:
		speed.x = 0
		acceleration.x = 0
	if friction_y and last_speed.y*speed.y < 0:
		speed.y = 0
		acceleration.y = 0
	
	last_speed = speed
	
	if position.y > 30*8 or position.y < -6*8 or position.x > 44*8 or position.x < -6*8:
		queue_free()

#func setup(s, d, p):
#	speed = s
#	direction = d
#	position = p
	
