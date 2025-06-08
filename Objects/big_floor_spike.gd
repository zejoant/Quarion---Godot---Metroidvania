#@tool
extends StaticBody2D

@export var sfxs: AudioLibrary
@export var spike_amount: int = 2
@export_enum("Delay", "Instant") var mode = "Delay"
@export_range(0, 10) var speed: float = 1
@export var sound: bool = true

func _ready():
	setup()
	if mode == "Delay":
		$AnimationPlayer.play("Extend")
		await get_tree().create_timer(1.2/speed, false).timeout
	elif mode == "Instant":
		$AnimationPlayer.play("Instant Extend")
	if sound:
		AudioManager.play_audio(sfxs.get_sfx("woosh"))

func _on_animation_player_animation_finished(_anim_name):
	queue_free()

func setup():
	$AnimationPlayer.speed_scale = speed
	$Sprite2D2.region_rect.size.x = spike_amount*16
	$"CollisionShape2D".shape.radius = 5 + 8*(spike_amount-1)

#animationplayer cant manipulate only the position of the region rect. method call needed
func frame_advance(frame: int):
	$Sprite2D2.region_rect.position.y = 112*(frame-1)


func retract_spike():
	$AnimationPlayer.call_deferred("stop")
	$CollisionShape2D.set_deferred("disabled", true)
	for i in $Sprite2D2.region_rect.position.y / 112:
		$Sprite2D2.region_rect.position.y -= 112
		await get_tree().create_timer(0.05, false).timeout
	queue_free()
