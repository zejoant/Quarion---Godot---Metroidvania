extends Area2D

@export var sfxs : AudioLibrary ## Tagged audio files to play from this scene
@export var destination_room : Vector2 = Vector2(0, 1)
@export var destination_position : Vector2 = Vector2(19, 12)

func _on_body_entered(_body):
	AudioManager.play_audio(sfxs.get_sfx("teleport"))
	get_node("/root/World").change_room(destination_room)
	get_node("/root/World/Player").position = destination_position*8
	get_node("/root/World/Camera").flash(1, 0, 1, 1)

#func _physics_process(_delta):
	#$Sprite2D.rotation_degrees += 1
	#$Sprite2D2.rotation_degrees -= 2
