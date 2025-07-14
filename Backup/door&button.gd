extends Node2D

@export var sfxs : AudioLibrary

# Called when the node enters the scene tree for the first time.
func _ready():
	var room_states = get_node("/root/World").get_room_state()
	for pos in room_states:
		if Vector2i($Button.position) == Vector2i(pos): #check if door has already been opened
			instant_open()


func _on_click_area_body_entered(_body):
	
	$AnimationPlayer.play("ButtonClick")
	AudioManager.play_audio(sfxs.get_sfx("click"))
	
	self.create_tween().tween_property($DoorR2, "position:x", $DoorR2.position.x+16, 1)
	self.create_tween().tween_property($DoorL2, "position:x", $DoorL2.position.x-16, 1)
	await self.create_tween().tween_property($DoorV3, "position:y", $DoorV3.position.y+24, 1).finished
	#await self.create_tween().tween_interval(1).finished
	
	$DoorR2.visible = false
	$DoorL2.visible = false
	$DoorV3.visible = false
	AudioManager.play_audio(sfxs.get_sfx("thump"))
	
	get_node("/root/World").save_room_state($Button.position)

func instant_open():
	$AnimationPlayer.play("ButtonPressed")
	$DoorR2.visible = false
	$DoorL2.visible = false
	$DoorV3.visible = false
	$DoorR2.position.x += 16
	$DoorL2.position.x -= 16
	$DoorV3.position.y += 24
