extends Control

var world = preload("res://world.tscn").instantiate()
static var settings_loaded = false

func _ready():
	if !settings_loaded:
		SaveManager.load_settings()
		settings_loaded = true

func _on_continue_button_pressed():
	if FileAccess.file_exists("user://saves/save_file.save"):
		disable_buttons()
		self.create_tween().tween_property($Menu, "offset:x", -150, 0.2)
		$Menu/VersionNumber.visible = false
		get_tree().create_tween().tween_property($FadeToBlack, "color", Color(0, 0, 0, 1), 0.5)
		await get_tree().create_timer(0.8, false).timeout
		
		world.new_game = false
		get_tree().root.add_child(world)
		get_tree().current_scene = world
		queue_free()
	else:
		_on_new_game_button_pressed()

func _on_new_game_button_pressed():
	#get_node("Menu").visible = false
	disable_buttons()
	$IntroObjects.count = 1
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	$Menu/VersionNumber.visible = false
	self.create_tween().tween_property($Menu, "offset:x", -150, 0.2)
	self.create_tween().tween_method(set_blur_power, 1.032, 0, 0.5); # args: (method / start value / end value / duration)
	get_node("IntroObjects/AnimationPlayer").play("Start")
	
func disable_buttons():
	$Menu/MarginContainer/VBoxContainer/VBoxContainer/NewGameButton.disabled = true
	$Menu/MarginContainer/VBoxContainer/VBoxContainer/ContinueButton.disabled = true
	$Menu/MarginContainer/VBoxContainer/VBoxContainer/QuitButton.disabled = true
	$Menu/MarginContainer/VBoxContainer/VBoxContainer/OptionsButton.disabled = true

func set_blur_power(power: float):
	get_node("BlurRect").material.set_shader_parameter("amount", power)

func _on_options_button_pressed():
	get_tree().change_scene_to_file("res://Menu/options_menu.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
