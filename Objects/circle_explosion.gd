extends StaticBody2D

@export var sfxs : AudioLibrary

func _ready():
	$AnimationPlayer.animation_finished.connect(delete)

func delete(_anim_name: String):
	call_deferred("queue_free")

func play_effect():
	AudioManager.play_audio(sfxs.get_sfx("explosion"))
	get_node("/root/World/Camera").shake(4, 0.03, 3)
