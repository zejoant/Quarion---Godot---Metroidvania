extends StaticBody2D

@export var sfxs : AudioLibrary

func collect():
	AudioManager.play_audio(sfxs.get_sfx("collect"))
	get_node("/root/World").save_room_state(position/8)
	get_node("/root/World/WorldMap").remove_item()
	get_node("/root/World/Player").update_apple_count(1)
	
	queue_free()
