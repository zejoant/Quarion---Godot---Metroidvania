extends StaticBody2D

var world
var sfx = preload("res://Sfx/checkpoint2.wav")
var cooldown : bool = false
# Called when the node enters the scene tree for the first time.
func _ready():
	world = get_node("/root/World")
	if world.no_death_mode:
		queue_free()
		return
	
	if world.room_coords == world.checkpoint_room and Vector2(position.x, position.y-8) == world.checkpoint_pos:
		$AnimationPlayer.play("Active")

func activate():
	if !cooldown:
		AudioManager.play_audio(sfx, 1, 1.2)
		$CPUParticles2D.emitting = false
		$CPUParticles2D.restart()  
		$CPUParticles2D.emitting = true
		$AnimationPlayer.play("Active")
		if world.changed_room_frames <= 3:
			if abs(abs(rotation_degrees) - 180) < 0.1:
				world.save_checkpoint_room(Vector2(position.x, position.y + 16))
			else:
				world.save_checkpoint_room(position)
			world.reset_room_objects("Crumble")
			world.temporary_actions_to_permanent()
			world.save_game()
		cooldown = true
		await get_tree().create_timer(2, false).timeout
		cooldown = false
