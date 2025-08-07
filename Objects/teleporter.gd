extends Area2D

@export var sfxs : AudioLibrary ## Tagged audio files to play from this scene
@export var destination_room : Vector2 = Vector2(0, 1)
@export var destination_position : Vector2 = Vector2(19, 12)

var player_in_area: bool = false

func _on_body_entered(body):
	if body is CharacterBody2D:
		player_in_area = true
		$InputIndicator.visible = true
	
func _on_body_exited(body):
	if body is CharacterBody2D:
		player_in_area = false
		$InputIndicator.visible = false

func _input(event):
	if player_in_area and event.is_action_pressed("Interact"):
		AudioManager.play_audio(sfxs.get_sfx("teleport"))
		get_node("/root/World").change_room(destination_room)
		get_node("/root/World/Player").velocity = Vector2(0, 0)
		get_node("/root/World/Player").position = destination_position*8
		get_node("/root/World/Camera").flash(1, 0, 1, 1)

