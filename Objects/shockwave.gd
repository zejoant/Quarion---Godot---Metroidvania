extends StaticBody2D

@export var dir: int = -1
@export var speed: float = 2.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _physics_process(_delta):
	position.x += dir*speed
	
	if position.x > 44*8 or position.x < -6*8:
			call_deferred("queue_free")

func setup(d: int, s: float, pos: Vector2):
	speed = s
	dir = d
	scale.x = -dir
	position = pos
	
