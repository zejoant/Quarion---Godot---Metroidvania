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
	
	#play_song(load("res://Music/The Dream that Died in Bliss.ogg"))
	#AudioManager.play_song(load("res://Music/Quarion ot Nruter Reven.ogg"))
	$Camera.fade("000000", 1, 0, 0.5, 0.5)
	await get_tree().create_timer(0.5, false).timeout
	if good_ending:
		$AnimationPlayer.play("True Ending")
	else:
		$AnimationPlayer.play("Default")

func play_song(song_path: String):
	AudioManager.play_song(load(song_path))

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

func add_price_cup(category: String):
	var tween
	if category == "Deaths":
		if death_count == 0:
			$StatsComp/DeathsPrice.region_rect.position.x -= 32
		elif death_count <= 10:
			$StatsComp/DeathsPrice.region_rect.position.x -= 16
		if death_count <= 50:
			tween = self.create_tween()
			tween.set_ease(Tween.EASE_IN)
			tween.set_trans(Tween.TRANS_BACK)
			tween.parallel().tween_property($StatsComp/DeathsPrice, "modulate:a", 1, 0.2)
			await tween.parallel().tween_property($StatsComp/DeathsPrice, "scale", Vector2(1, 1), 0.3).finished
			AudioManager.play_audio(sfxs.get_sfx("cup"))
		
	elif category == "Jumps":
		if jump_count <= 800:
			$StatsComp/JumpsPrice.region_rect.position.x -= 32
		elif jump_count <= 1000:
			$StatsComp/JumpsPrice.region_rect.position.x -= 16
		if jump_count <= 2000:
			tween = self.create_tween()
			tween.set_ease(Tween.EASE_IN)
			tween.set_trans(Tween.TRANS_BACK)
			tween.parallel().tween_property($StatsComp/JumpsPrice, "modulate:a", 1, 0.2)
			await tween.parallel().tween_property($StatsComp/JumpsPrice, "scale", Vector2(1, 1), 0.3).finished
			AudioManager.play_audio(sfxs.get_sfx("cup"))
	
	elif category == "Time":
		if completion_time < 1200:
			$StatsComp/TimePrice.region_rect.position.x -= 32
		elif completion_time <= 1800:
			$StatsComp/TimePrice.region_rect.position.x -= 16
		if completion_time <= 2400:
			tween = self.create_tween()
			tween.set_ease(Tween.EASE_IN)
			tween.set_trans(Tween.TRANS_BACK)
			tween.parallel().tween_property($StatsComp/TimePrice, "modulate:a", 1, 0.2)
			await tween.parallel().tween_property($StatsComp/TimePrice, "scale", Vector2(1, 1), 0.3).finished
			AudioManager.play_audio(sfxs.get_sfx("cup"))
	
	#elif category == "Percent":
		#if death_count == 100:
			#$StatsComp/PercentPrice.region_rect.position.x -= 32
		#elif death_count <= 95:
			#$StatsComp/PercentPrice.region_rect.position.x -= 16
		#if death_count <= 80:
			#tween = self.create_tween()
			#tween.set_ease(Tween.EASE_IN)
			#tween.set_trans(Tween.TRANS_BACK)
			#tween.parallel().tween_property($StatsComp/PercentPrice, "modulate:a", 1, 0.2)
			#tween.parallel().tween_property($StatsComp/PercentPrice, "scale", Vector2(1, 1), 0.3)
	
	
