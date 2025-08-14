extends StaticBody2D

var player
@onready var cam = get_node("/root/World/Camera")
@onready var world = get_node("/root/World")
@export var sfxs : AudioLibrary

var player_in_area: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_node("/root/World/Player")
	
	for pos in world.get_room_state():
		if Vector2i(position/8) == Vector2i(pos): #check if boss has been defeated
			$AnimationPlayer.play("Open Mouth Instant")
			await $AnimationPlayer.animation_finished
			$AnimationPlayer.play("Lamp Lit")


func _input(event):
	if event.is_action_pressed("Interact") and player.amulet_pieces == 5 and player_in_area:
		$InputIndicator.visible = false
		cam.remove_collected_item(cam.CollectedItem.AMULET)
		player.amulet_pieces = -1
		world.save_room_state(position/8, true)
		AudioManager.pause_song()
		$AnimationPlayer.play("Insert Amulet")
		await $AnimationPlayer.animation_finished
		AudioManager.play_audio(sfxs.get_sfx("Amulet Impact"))
		await get_tree().create_timer(1.2, false).timeout
		$AnimationPlayer.play("Open Mouth")
		await $AnimationPlayer.animation_finished
		await get_tree().create_timer(0.5, false).timeout
		$AnimationPlayer.play("Lamp Lit")
		AudioManager.resume_song()
		world.save_checkpoint_room(Vector2(12*8, 21*8))

func open_mouth_sfx():
	AudioManager.play_audio(sfxs.get_sfx("Open Mouth"))

func _on_insert_amulet_area_body_entered(body):
	if body is CharacterBody2D and player.amulet_pieces == 5:
		player_in_area = true
		$InputIndicator.visible = true

func _on_insert_amulet_area_body_exited(body):
	if body is CharacterBody2D:
		player_in_area = false
		$InputIndicator.visible = false
