extends Node2D

@export var sfxs : AudioLibrary

var jump_count: int = 0
var death_count: int = 0
var completion_time: float = 0
var completion_percentage: float = 0

var good_ending: bool = false
var player_palette: int = 0

@export var can_exit: bool = false

func _ready():
	$TrueEndingPhoto.material.set_shader_parameter("palette_choice", player_palette)
	$StatsComp/DeathsValue.text = str(death_count)
	$StatsComp/JumpsValue.text = str(jump_count)
	$StatsComp/TimeValue.text = time_convert(completion_time)
	$StatsComp/PercentValue.text = str(int(completion_percentage), "%")
	
	#$CreditsComp/JumpCount.text = str(jump_count)
	#$CreditsComp/DeathCount.text = str(death_count)
	#$CreditsComp/CompletionTime.text = time_convert(completion_time)
	#$CreditsComp/CompletionPercentage.text = str(int(completion_percentage), "%")
	
	$Camera.fade("000000", 1, 0, 0.5, 0.5)
	await get_tree().create_timer(0.5, false).timeout
	if good_ending:
		$AnimationPlayer.play("True Ending")
	else:
		$AnimationPlayer.play("Default")

func time_convert(time):
	var hours = time/3600
	var minutes = fmod(time/60, 60)
	var seconds = fmod(time, 60)
	var milli = fmod(time, 1) * 1000
	
	#returns a string with the format "HH:MM:SS:MS"
	return "%02d:%02d:%02d.%03d" % [hours, minutes, seconds, milli]

func _input(event):
	if can_exit:
		if event.is_action_released("ui_accept"):
			can_exit = false
			return_after_end()

func return_after_end():
	if !OptionsMenu.no_death_mode_unlocked:
		OptionsMenu.no_death_mode_unlocked = true
		var tween = self.create_tween()
		tween.tween_property($BlackCover, "modulate:a", 1, 0.5)
		tween.tween_property($NoDeathUnlocked, "modulate:a", 1, 0.5)
		tween.tween_interval(2)
		await tween.tween_property($NoDeathUnlocked, "modulate:a", 0, 0.5).finished
	SaveManager.save_settings()
	$Camera.fade("000000", 1, 0.5, 0.3, 0)
	await get_tree().create_timer(0.7, false).timeout
	get_tree().change_scene_to_file("res://Menu/main_menu.tscn")

func play_sfx(sfx_name: String):
	AudioManager.play_audio(sfxs.get_sfx(sfx_name))
