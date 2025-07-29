extends StaticBody2D

@export var sfxs : AudioLibrary

func _ready():
	for pos in get_node("/root/World").get_room_state():
		if Vector2i(position/8) == Vector2i(pos): #check if boss has been defeated
			queue_free()
	get_node("/root/World/WorldMap").add_apple_from_room(position)

func collect():
	get_node("/root/World").add_to_completion_percentage("Apple")
	AudioManager.play_audio(sfxs.get_sfx("collect"))
	get_node("/root/World").save_room_state(position/8)
	#get_node("/root/World/WorldMap").remove_item()
	get_node("/root/World/WorldMap").remove_apple_from_map(position)
	get_node("/root/World/Player").update_apple_count(1)
	
	queue_free()
