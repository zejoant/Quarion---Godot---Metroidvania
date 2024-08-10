extends StaticBody2D

var world
var sfx = preload("res://Sfx/checkpoint2.wav")

# Called when the node enters the scene tree for the first time.
func _ready():
	world = get_node("/root/World")
	
	if world.room_coords == world.checkpoint_room and Vector2(position.x, position.y-8) == world.checkpoint_pos:
		$AnimationPlayer.play("Active")

func activate():
	#world.play_sfx(sfx, "Checkpoint")
	AudioManager.play_audio(sfx)
	$CPUParticles2D.emitting = true
	$AnimationPlayer.play("Active")
	world.save_checkpoint_room(position)
