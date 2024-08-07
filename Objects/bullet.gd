extends StaticBody2D

@export var speed : float
@export var direction : Vector2

func _ready():
	$Sprite2D.rotation = direction.angle() - PI/2

func _process(_delta):
	position += direction * speed
	
	if position.y > 30*8 or position.y < -6*8 or position.x > 44*8 or position.x < -6*8:
		queue_free()

func setup(s, d, p):
	speed = s
	direction = d
	position = p
	
