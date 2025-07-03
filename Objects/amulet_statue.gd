extends StaticBody2D

var player
@onready var world = get_node("/root/World")
@export var sfxs : AudioLibrary

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_node("/root/World/Player")
	
	for pos in world.get_room_state():
		if Vector2i(position/8) == Vector2i(pos): #check if boss has been defeated
			$AnimationPlayer.play("Open Mouth Instant")
			await $AnimationPlayer.animation_finished
			$AnimationPlayer.play("Lamp Lit")


func _input(event):
	if player.get_node("Area2D").has_overlapping_bodies() and player.get_node("Area2D").get_overlapping_bodies().has($InsertAmuletArea):
		if event.is_action_pressed("UI Up") and player.amulet_pieces == 5:
			player.amulet_pieces = -1
			world.save_room_state(position/8)
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

func open_mouth_sfx():
	AudioManager.play_audio(sfxs.get_sfx("Open Mouth"))
