extends StaticBody2D

@export var dir: Vector2 = Vector2(-1, 0)
@export var speed: float = 4.0

func _ready():
	rotation = dir.angle()

func _physics_process(_delta):
	position += dir*speed
	
	if position.y > 30*8 or position.y < -6*8 or position.x > 44*8 or position.x < -6*8:
			queue_free()

func setup(pos: Vector2, d: Vector2, s: float):
	position = pos
	dir = d
	speed = s
	
