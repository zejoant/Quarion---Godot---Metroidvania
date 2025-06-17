extends StaticBody2D

@export var sfxs : AudioLibrary

func _ready():
	get_node("/root/World/WorldMap").add_apple_from_room(position)

func collect():
	get_node("/root/World").completion_percentage += 1
	AudioManager.play_audio(sfxs.get_sfx("collect"))
	get_node("/root/World").save_room_state(position/8)
	#get_node("/root/World/WorldMap").remove_item()
	get_node("/root/World/WorldMap").remove_apple_from_map(position)
	get_node("/root/World/Player").update_apple_count(1)
	
	queue_free()
