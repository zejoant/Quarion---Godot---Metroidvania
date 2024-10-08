extends StaticBody2D

func collect():
	get_node("/root/World").save_room_state(position/8)
	get_node("/root/World/WorldMap").remove_item()
	
	queue_free()
