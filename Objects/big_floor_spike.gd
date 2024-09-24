#@tool
extends StaticBody2D

@export var sfxs: AudioLibrary
@export var spike_amount: int = 2

func _ready():
	setup()
	await get_tree().create_timer(1.2).timeout
	AudioManager.play_audio(sfxs.get_sfx("woosh"))

func _on_animation_player_animation_finished(_anim_name):
	queue_free()

func setup():
	$Sprite2D2.region_rect.size.x = spike_amount*16
	$"CollisionShape2D".shape.radius = 5 + 8*(spike_amount-1)

#poopy animationplayer cant manipulate position only of the region rect :/
func frame_advance(frame: int):
	$Sprite2D2.region_rect.position.y = 112*(frame-1)


func retract_spike():
	$AnimationPlayer.call_deferred("stop")
	$CollisionShape2D.set_deferred("disabled", true)
	for i in $Sprite2D2.region_rect.position.y / 112:
		$Sprite2D2.region_rect.position.y -= 112
		await get_tree().create_timer(0.05).timeout
	queue_free()
