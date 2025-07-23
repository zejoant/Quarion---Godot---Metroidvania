extends Control

@export var sfxs : AudioLibrary
var world = preload("res://world.tscn").instantiate()
static var settings_loaded = false

func _ready():
	if !settings_loaded:
		SaveManager.load_settings()
		settings_loaded = true
	
	#if SaveManager.save_file_exists():
	#	$Menu/MarginContainer/VBoxContainer/VBoxContainer/ContinueButton.disabled = true
	
	_on_joy_connection_changed(0, Input.get_connected_joypads().size() > 0)
		
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _on_joy_connection_changed(_device_id, connected):
	if !connected and OptionsMenu.use_mouse_for_menus:
		get_viewport().gui_release_focus()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		get_viewport().gui_release_focus()
		$Menu/MarginContainer/VBoxContainer/VBoxContainer/ContinueButton.grab_focus()
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		
#func _input(event):
	#if !get_viewport().gui_get_focus_owner():
		#if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			#$Menu/MarginContainer/VBoxContainer/VBoxContainer/ContinueButton.grab_focus()

func _on_continue_button_pressed():
	#Input.joy_connection_changed.disconnect(_on_joy_connection_changed)
	AudioManager.play_audio(sfxs.get_sfx("click"))
	if FileAccess.file_exists("user://save_file.save"):
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
	AudioManager.play_audio(sfxs.get_sfx("click"))
	#get_node("Menu").visible = false
	#Input.joy_connection_changed.disconnect(_on_joy_connection_changed)
	disable_buttons()
	$IntroObjects.count = 1
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	$Menu/VersionNumber.visible = false
	self.create_tween().tween_property($Menu, "offset:x", -150, 0.2)
	self.create_tween().tween_method(set_blur_power, 1.032, 0, 0.5); # args: (method / start value / end value / duration)
	$IntroObjects.run_animation()
	#get_node("IntroObjects/AnimationPlayer").play("Start")
	
func disable_buttons():
	$Menu/MarginContainer/VBoxContainer/VBoxContainer/NewGameButton.disabled = true
	$Menu/MarginContainer/VBoxContainer/VBoxContainer/ContinueButton.disabled = true
	$Menu/MarginContainer/VBoxContainer/VBoxContainer/QuitButton.disabled = true
	$Menu/MarginContainer/VBoxContainer/VBoxContainer/OptionsButton.disabled = true

func set_blur_power(power: float):
	get_node("BlurRect").material.set_shader_parameter("amount", power)

func _on_options_button_pressed():
	AudioManager.play_audio(sfxs.get_sfx("click"))
	#Input.joy_connection_changed.disconnect(_on_joy_connection_changed)
	$Menu.visible = false
	var options = load("res://Menu/options_menu.tscn").instantiate()
	$OptionsLayer.add_child(options)
	#get_tree().change_scene_to_file("res://Menu/options_menu.tscn")

func _on_quit_button_pressed():
	AudioManager.play_audio(sfxs.get_sfx("click"))
	get_tree().quit()
