extends StaticBody2D

@export var sfxs : AudioLibrary

func _ready():
	for pos in get_node("/root/World").get_room_state():
		if Vector2i(position/8) == Vector2i(pos): #check if boss has been defeated
			queue_free()

func collect():
	AudioManager.play_audio(sfxs.get_sfx("collect"))
	get_node("/root/World").save_room_state(position/8)
	get_node("/root/World/Player").amulet_pieces += 1
	get_node("/root/World/Camera").collect_amulet_piece()
	queue_free()
