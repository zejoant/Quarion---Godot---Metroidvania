extends StaticBody2D

@export var sfxs : AudioLibrary
@onready var world = get_node("/root/World")

func _ready():
	for pos in get_node("/root/World").get_room_state():
		if Vector2i(position/8) == Vector2i(pos): #check if boss has been defeated
			queue_free()

func collect():
	AudioManager.play_audio(sfxs.get_sfx("collect"))
	world.save_room_state(position/8)
	world.player.amulet_pieces += 1
	world.completion_percentage += 1
	world.get_node("Camera").collect_amulet_piece()
	queue_free()
