extends Control
class_name OptionsMenu

var back_scene = "menu"
static var sfx_slider_value = 0
static var music_slider_value = 0
#static var window_mode = 0
static var fullscreen = false
static var borderless = false

static var use_mouse_for_menus = true

var previous_window_size = Vector2i(304, 192)

func _ready():
	$MarginContainer/VBoxContainer/AudioHBox/SfxVBox/SfxSlider.value = sfx_slider_value
	$MarginContainer/VBoxContainer/AudioHBox/MusicVbox/MusicSlider.value = music_slider_value
	#$MarginContainer/VBoxContainer/WindowMode.selected = window_mode
	#_on_window_mode_item_selected(window_mode)
	
	$MarginContainer/VBoxContainer/VideoVBox/FullscreenCheck.button_pressed = fullscreen
	$MarginContainer/VBoxContainer/VideoVBox/BorderlessCheck.button_pressed = borderless
	
	$MarginContainer/VBoxContainer/MouseHBox/MouseMenusCheck.button_pressed = use_mouse_for_menus
	
	#if Input.get_connected_joypads().size() > 0:
		#get_viewport().gui_release_focus()
		#$MarginContainer/VBoxContainer/AudioHBox/SfxVBox/SfxSlider.grab_focus()
		#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	_on_joy_connection_changed(0, Input.get_connected_joypads().size() > 0)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _on_joy_connection_changed(_device_id, connected):
	if use_mouse_for_menus:
		if !connected:
			get_viewport().gui_release_focus()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			get_viewport().gui_release_focus()
			$MarginContainer/VBoxContainer/AudioHBox/SfxVBox/SfxSlider.grab_focus()
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _input(event):
	if event.is_action_released("UI Back"):
		_on_back_button_pressed()
	
	#if !get_viewport().gui_get_focus_owner():
		#if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			#$MarginContainer/VBoxContainer/AudioHBox/SfxVBox/SfxSlider.grab_focus()

func _on_back_button_pressed():
	#Input.joy_connection_changed.disconnect(_on_joy_connection_changed)
	save_settings()
	if back_scene == "menu":
		get_node("/root/MainMenu/Menu").visible = true
		if Input.get_connected_joypads().size() > 0 or !OptionsMenu.use_mouse_for_menus:
			get_node("/root/MainMenu/Menu/MarginContainer/VBoxContainer/VBoxContainer/OptionsButton").grab_focus()
		queue_free()
		#get_tree().change_scene_to_file("res://Menu/main_menu.tscn")
	elif back_scene == "game":
		get_parent().get_node("PauseMenu").show()
		if Input.get_connected_joypads().size() > 0 or !OptionsMenu.use_mouse_for_menus:
			get_parent().get_node("PauseMenu/MarginContainer/VBoxContainer/ResumeButton").grab_focus()
		queue_free()

func save_settings():
	SaveManager.save_settings()


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
		previous_window_size = DisplayServer.window_get_size()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		fullscreen = true
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(previous_window_size)
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		fullscreen = false

func _on_mouse_menus_check_toggled(toggled_on):
	if toggled_on:
		use_mouse_for_menus = true
		if Input.get_connected_joypads().size() == 0:
			get_viewport().gui_release_focus()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.warp_mouse(Vector2(100, 100))
		use_mouse_for_menus = false
		get_viewport().gui_release_focus()
		$MarginContainer/VBoxContainer/MouseHBox/MouseMenusCheck.grab_focus()
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	#_on_joy_connection_changed(0, Input.get_connected_joypads().size() > 0)

static func set_loaded_settings():
	if sfx_slider_value == -25:
		AudioServer.set_bus_mute(2, true)
	else:
		AudioServer.set_bus_volume_db(2, sfx_slider_value)
	if music_slider_value == -25:
		AudioServer.set_bus_mute(1, true)
	else:
		AudioServer.set_bus_volume_db(1, music_slider_value)
	
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, borderless)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		


