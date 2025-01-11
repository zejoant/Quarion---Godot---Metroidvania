extends Node2D

var player
@export_range(0, 5) var size: float = 1
@export var follow_player : bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	if follow_player:
		player = get_node_or_null("/root/World/Player")
	scale = Vector2(size, size)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if follow_player:
		position = player.position
