extends StaticBody2D

var world
var sfx = preload("res://Sfx/checkpoint2.wav")
var cooldown : bool = false
# Called when the node enters the scene tree for the first time.
func _ready():
	world = get_node("/root/World")
	
	if world.room_coords == world.checkpoint_room and Vector2(position.x, position.y-8) == world.checkpoint_pos:
		$AnimationPlayer.play("Active")

func activate():
	if !cooldown:
		AudioManager.play_audio(sfx)
		$CPUParticles2D.emitting = false
		$CPUParticles2D.restart()  
		$CPUParticles2D.emitting = true
		$AnimationPlayer.play("Active")
		world.save_checkpoint_room(position)
		cooldown = true
		await get_tree().create_timer(2, false).timeout
		cooldown = false
