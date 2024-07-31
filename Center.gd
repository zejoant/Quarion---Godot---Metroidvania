extends Sprite2D

@export var width : int = 3

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func setup():
	$CollisionShape2D.scale.x = width
	$CenterSprite.scale.x = width-2
	$RightSprite.position.x = 8 + 4*(width-3)
	$LeftSprite.position.x = -8 - 4*(width-3)
