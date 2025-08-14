extends StaticBody2D

@export_enum("green", "red") var type = "green" 
@export var sfxs : AudioLibrary
@onready var player = get_node("/root/World/Player")
@onready var cam = get_node("/root/World/Camera")

func _ready():
	for pos in get_node("/root/World").get_room_state():
		if Vector2i(position/8) == Vector2i(pos): #check if boss has been defeated
			queue_free()
	if type == "red":
		$KeySprite.region_rect.position.x -= 16

func collect():
	get_node("/root/World").save_room_state(position/8, true)
	AudioManager.play_audio(sfxs.get_sfx("collect"))
	
	AudioManager.pause_song()
	player.disable_movement()
	player.update_animations = false
	player.get_node("AnimationPlayer").play("hold_up_item")
	z_index = 0
	position = Vector2(player.position.x, position.y - 16)
	await get_tree().create_timer(1.3, false).timeout
	
	player.disable_movement(false)
	player.update_animations = true
	AudioManager.resume_song()
	
	
	if type == "green":
		player.green_key_state = "collected"
		#get_node("/root/World/Camera/UIContainer/GreenKeySprite").visible = true
		cam.add_collected_item(cam.CollectedItem.GREEN_KEY)
		#cam.set_keys("Green")
	elif type == "red":
		player.red_key_state = "collected"
		#get_node("/root/World/Camera/UIContainer/RedKeySprite").visible = true
		cam.add_collected_item(cam.CollectedItem.RED_KEY)
		#cam.set_keys("Red")
	
	queue_free()
