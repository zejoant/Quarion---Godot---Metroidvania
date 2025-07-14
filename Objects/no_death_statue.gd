extends Node2D

func _ready():
	if get_node("/root/World/Player").death_count == 0:
		visible = true
