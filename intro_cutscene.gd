extends Node2D

@export var sfxs : AudioLibrary

var count = 0
var no_death_mode: bool = false

func _on_animation_player_animation_finished(_anim_name):
	var world = load("res://world.tscn").instantiate()
	world.no_death_mode = no_death_mode
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	get_parent().queue_free()
	#get_tree().change_scene_to_file("res://world.tscn")

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
				_on_animation_player_animation_finished("boot")
				#get_tree().change_scene_to_file("res://world.tscn")

func run_animation():
	$Camera/LensCircle2.visible = false
	$AnimationPlayer.play("Start")
	AudioManager.stop_song(1)

func play_sfx(sfx_name: String):
	AudioManager.play_audio(sfxs.get_sfx(sfx_name))

func play_song(song_name: String):
	AudioManager.play_song(load(song_name))
	#AudioManager.play_song(load("res://Music/Welcome to Noirauq.ogg"), start)
