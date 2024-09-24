extends Control

var back_scene = "menu"
static var sfx_slider_value = 0
static var music_slider_value = 0
#static var window_mode = 0
static var fullscreen = false
static var borderless = false

func _ready():
	$MarginContainer/VBoxContainer/AudioHBox/SfxVBox/SfxSlider.value = sfx_slider_value
	$MarginContainer/VBoxContainer/AudioHBox/MusicVbox/MusicSlider.value = music_slider_value
	#$MarginContainer/VBoxContainer/WindowMode.selected = window_mode
	#_on_window_mode_item_selected(window_mode)
	
	$MarginContainer/VBoxContainer/VideoVBox/FullscreenCheck.button_pressed = fullscreen
	$MarginContainer/VBoxContainer/VideoVBox/BorderlessCheck.button_pressed = borderless


func _on_back_button_pressed():
	#save_settings()
	if back_scene == "menu":
		get_tree().change_scene_to_file("res://Menu/main_menu.tscn")
	elif back_scene == "game":
		get_parent().get_node("PauseMenu").show()
		queue_free()


#func _on_window_mode_item_selected(index):
	##window_mode = index
	#if index == 0:
		#DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		#DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	#elif index == 1:
		#DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		#DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	#elif index == 2:
		#DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		#DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func save_settings():
	pass


func _on_sfx_slider_value_changed(value):
	sfx_slider_value = value
	if value == -25:
		AudioServer.set_bus_mute(2, true)
	else:
		AudioServer.set_bus_mute(2, false)
		AudioServer.set_bus_volume_db(2, value)

func _on_music_slider_value_changed(value):
	music_slider_value = value
	if value == -25:
		AudioServer.set_bus_mute(1, true)
	else:
		AudioServer.set_bus_mute(1, false)
		AudioServer.set_bus_volume_db(1, value)


func _on_borderless_check_toggled(toggled_on):
	if toggled_on:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		borderless = true
	else:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		borderless = false


func _on_fullscreen_check_toggled(toggled_on):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		fullscreen = true
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		fullscreen = false
		
