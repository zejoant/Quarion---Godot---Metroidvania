extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	$Particles.finished.connect(delete_itself)

func delete_itself():
	queue_free()
