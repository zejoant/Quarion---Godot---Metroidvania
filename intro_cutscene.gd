extends Node2D

@export var sfxs : AudioLibrary

var count = 0

func _on_animation_player_animation_finished(_anim_name):
	get_tree().change_scene_to_file("res://world.tscn")

func _physics_process(_delta):
	if count > 0:
		if Input.is_action_just_pressed("ui_accept"):
			if count == 1:
				count += 1
				var tween = self.create_tween()
				tween.tween_property($Camera/SkipText, "modulate:a", 1, 0.3)
				tween.tween_interval(4)
				tween.tween_property($Camera/SkipText, "modulate:a", 0, 0.3)
			else:
				$Camera.fade("000000", 1, 0.3, 0.2, 0)
				await get_tree().create_timer(0.5, false).timeout
				get_tree().change_scene_to_file("res://world.tscn")

func run_animation():
	$Camera/LensCircle2.visible = false
	$AnimationPlayer.play("Start")
	#$AnimationPlayer.speed_scale = 3

func play_sfx(sfx_name: String):
	AudioManager.play_audio(sfxs.get_sfx(sfx_name))

func play_song():
	AudioManager.play_song(load("res://Music/Fabbenraba.mp3"))
