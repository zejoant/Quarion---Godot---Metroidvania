extends StaticBody2D

@export var sfxs : AudioLibrary
@onready var world = get_node("/root/World")
@onready var player = get_node("/root/World/Player")

func _ready():
	for pos in get_node("/root/World").get_room_state():
		if Vector2i(position/8) == Vector2i(pos): #check if boss has been defeated
			queue_free()

func collect():
	AudioManager.play_audio(sfxs.get_sfx("collect"))
	
	AudioManager.pause_song()
	player.disable_movement()
	player.update_animations = false
	player.get_node("AnimationPlayer").play("hold_up_item")
	z_index = 0
	position = Vector2(player.position.x, player.position.y - 16)
	await get_tree().create_timer(1.3, false).timeout
	
	player.disable_movement(false)
	player.update_animations = true
	AudioManager.resume_song()
	
	world.completion_percentage += 1
	world.save_room_state(position/8)
	world.player.has_item_map = true
	world.get_node("WorldMap/MapComps/ItemMap").visible = true
	visible = false
	await get_tree().create_timer(0.2, false).timeout
	
	world.get_node("Camera").open_p_up_window("TreasureMap")
	queue_free()
