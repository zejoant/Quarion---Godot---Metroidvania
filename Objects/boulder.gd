#@tool
extends CharacterBody2D

@export var dir = 1
@export_enum("red", "purple", "brown") var color = "red"
@export_enum("single direction roll", "wall bounce roll", "static direction") var mode = "single direction roll"

# Called when the node enters the scene tree for the first time.
func _ready():
	if color == "purple":
		$BoulderSprite.region_rect.position.x = 24
	elif color == "brown":
		$BoulderSprite.region_rect.position.x = 24*2
	else:
		$BoulderSprite.region_rect.position.x = 0
	
	$RayCast1.scale.x = dir

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	$BoulderSprite.rotation += PI / 60
	if mode == "single direction roll":
		if !$RayCast1.is_colliding() and abs(velocity.x) < 50:
			velocity.x += dir
		elif $RayCast1.is_colliding():
			velocity.x = 0
		
		if !$RayCast2.is_colliding() and abs(velocity.y) < 100:
			velocity.y += 2
		elif $RayCast2.is_colliding() and velocity.y >= 0:
			velocity.y = -velocity.y / 4.0
	
	if position.y > 30*8 or position.y < -6*8 or position.x > 44*8 or position.x < -6*8:
		queue_free()
	
	move_and_slide()
