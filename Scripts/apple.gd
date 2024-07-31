extends StaticBody2D

func collect():
	#get_parent().erased_cells.append(position/8)
	#get_node("/root/World").collected_items.append(position/8)
	get_node("/root/World").save_room_state(position/8)
	queue_free()
