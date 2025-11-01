extends StaticBody2D

@export var sfxs : AudioLibrary
@onready var world = get_node("/root/World")
@onready var player = get_node("/root/World/Player")

func _ready():
	for pos in world.get_room_state():
		if Vector2i(position/8) == Vector2i(pos): #check if boss has been defeated
			queue_free()

func collect():
	if world.player.amulet_pieces < 6:
		world.save_room_state(position/8, true)
		world.temporary_actions_to_permanent()
		AudioManager.play_audio(sfxs.get_sfx("collect"))
		
		AudioManager.pause_song()
		player.disable_movement()
		player.velocity = Vector2(0, 0)
		player.position.y = position.y-4
		player.update_animations = false
		player.get_node("AnimationPlayer").play("hold_up_item")
		z_index = 0
		position = Vector2(player.position.x, position.y - 16)
		await get_tree().create_timer(1.3, false).timeout
		
		player.update_animations = true
		visible = false
		
		await get_tree().create_timer(0.2, false).timeout
		
		world.player.amulet_pieces += 1
		world.add_to_completion_percentage("AmuletPiece")
		world.get_node("Camera").collect_amulet_piece()
		queue_free()
