extends Node2D

var player
@export_range(0, 5) var size: float = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_node("/root/World/Player")
	scale = Vector2(size, size)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	position = player.position
