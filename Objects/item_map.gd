extends StaticBody2D

@export var sfxs : AudioLibrary
@onready var world = get_node("/root/World")

func _ready():
	for pos in get_node("/root/World").get_room_state():
		if Vector2i(position/8) == Vector2i(pos): #check if boss has been defeated
			queue_free()

func collect():
	AudioManager.play_audio(sfxs.get_sfx("collect"))
	world.completion_percentage += 1
	world.save_room_state(position/8)
	world.player.has_item_map = true
	world.get_node("WorldMap/MapComps/ItemMap").visible = true
	#world.completion_percentage += 1
	#world.get_node("Camera").collect_amulet_piece()
	queue_free()
