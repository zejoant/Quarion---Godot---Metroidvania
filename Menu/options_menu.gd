extends Control
class_name OptionsMenu

@export var sfxs : AudioLibrary
var back_scene = "menu"
static var sfx_slider_value = 0.5
static var music_slider_value = 0.5
static var fullscreen = false
static var borderless = false

static var use_mouse_for_menus = true
static var speedrun_timer = false

static var no_death_mode_unlocked = false
static var reduced_effects = false

var previous_window_mode = DisplayServer.WINDOW_MODE_WINDOWED

var sound_cooldown = false

func _ready():
	
	if back_scene == "game":
		get_node("/root/World/Camera/UILayer").visible = false
	
	$MarginContainer/VBoxContainer/AudioHBox/SfxVBox/SfxSlider.value = sfx_slider_value
	$MarginContainer/VBoxContainer/AudioHBox/MusicVbox/MusicSlider.value = music_slider_value
	AudioServer.set_bus_volume_db(2, linear_to_db(sfx_slider_value))
	AudioServer.set_bus_volume_db(1, linear_to_db(music_slider_value))
	
	$MarginContainer/VBoxContainer/AudioHBox/SfxVBox/SfxSlider.value_changed.connect(_on_sfx_slider_value_changed)
	$MarginContainer/VBoxContainer/AudioHBox/MusicVbox/MusicSlider.value_changed.connect(_on_music_slider_value_changed)
	
	$MarginContainer/VBoxContainer/VideoVBox/FullscreenCheck.button_pressed = fullscreen
	$MarginContainer/VBoxContainer/VideoVBox/BorderlessCheck.button_pressed = borderless
	
	$MarginContainer/VBoxContainer/MouseHBox/MouseMenusCheck.button_pressed = use_mouse_for_menus
	$MarginContainer/VBoxContainer/MouseHBox/TimerCheck.button_pressed = speedrun_timer
	$MarginContainer/VBoxContainer/MouseHBox/EffectsCheck.button_pressed = reduced_effects
	
	_on_joy_connection_changed(0, Input.get_connected_joypads().size() > 0)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _on_joy_connection_changed(_device_id, connected):
	if !connected and use_mouse_for_menus:
		get_viewport().gui_release_focus()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		$CanvasLayer/StopMouse.mouse_filter = MOUSE_FILTER_IGNORE
	else:
		get_viewport().gui_release_focus()
		$MarginContainer/VBoxContainer/BackHBox/BackButton.grab_focus()
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		$CanvasLayer/StopMouse.mouse_filter = MOUSE_FILTER_STOP
	
	if !connected:
		$MarginContainer/VBoxContainer/MouseHBox/MouseMenusCheck.visible = true
		#$MarginContainer/VBoxContainer/VideoVBox/BorderlessCheck.focus_neighbor_bottom = "../../MouseHBox/MouseMenusCheck"
		#$MarginContainer/VBoxContainer/BackHBox/BackButton.focus_neighbor_top = "../../MouseHBox/MouseMenusCheck"
	else:
		$MarginContainer/VBoxContainer/MouseHBox/MouseMenusCheck.visible = false
		#$MarginContainer/VBoxContainer/VideoVBox/BorderlessCheck.focus_neighbor_bottom = "../../MouseHBox/TimerCheck"#"../../BackHBox/BackButton"
		#$MarginContainer/VBoxContainer/BackHBox/BackButton.focus_neighbor_top = "../../MouseHBox/TimerCheck"#"../../VideoVBox/BorderlessCheck"

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
		accept_event()

func _on_back_button_pressed():
	AudioManager.play_audio(sfxs.get_sfx("click"),1, 1.4)
	save_settings()
	if back_scene == "menu":
		get_node("/root/MainMenu/Menu").visible = true
		get_node("/root/MainMenu")._on_joy_connection_changed(0, Input.get_connected_joypads().size() > 0)
	elif back_scene == "game":
		get_parent().get_node("PauseMenu").show()
		get_node("/root/World/Camera/UILayer").visible = true
		get_parent().get_node("PauseMenu")._on_joy_connection_changed(0, Input.get_connected_joypads().size() > 0)
	queue_free()

func save_settings():
	SaveManager.save_settings()


func _on_sfx_slider_value_changed(value):
	sfx_slider_value = value
	#if value == 0:
		#AudioServer.set_bus_mute(2, true)
	#else:
	#AudioServer.set_bus_mute(2, false)
	AudioServer.set_bus_volume_db(2, linear_to_db(value))
	
	if Input.is_key_pressed(KEY_SHIFT):
		$MarginContainer/VBoxContainer/AudioHBox/MusicVbox/MusicSlider.value = value
	
	if value:
		if !sound_cooldown:
			sound_cooldown = true
			AudioManager.play_audio(sfxs.get_sfx("slider"), value)
			await get_tree().create_timer(0.05).timeout
			sound_cooldown = false

func _on_music_slider_value_changed(value):
	music_slider_value = value
	#if value == 0:
	#	AudioServer.set_bus_mute(1, true)
	#else:
	#AudioServer.set_bus_mute(1, false)
	AudioServer.set_bus_volume_db(1, linear_to_db(value))
	
	if Input.is_key_pressed(KEY_SHIFT):
		$MarginContainer/VBoxContainer/AudioHBox/SfxVBox/SfxSlider.value = value

	if value:
		if !sound_cooldown:
			sound_cooldown = true
			AudioManager.play_audio(sfxs.get_sfx("slider"), value)
			await get_tree().create_timer(0.05).timeout
			sound_cooldown = false

func _on_borderless_check_toggled(toggled_on):
	AudioManager.play_audio(sfxs.get_sfx("click"),1, 1.4)
	if toggled_on:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		borderless = true
	else:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		borderless = false


func _on_fullscreen_check_toggled(toggled_on):
	AudioManager.play_audio(sfxs.get_sfx("click"),1, 1.4)
	if toggled_on:
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
			previous_window_mode = DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		fullscreen = true
	else:
		DisplayServer.window_set_mode(previous_window_mode)
		fullscreen = false

func _on_mouse_menus_check_toggled(toggled_on):
	AudioManager.play_audio(sfxs.get_sfx("click"),1, 1.4)
	if toggled_on:
		use_mouse_for_menus = true
		if Input.get_connected_joypads().size() == 0:
			get_viewport().gui_release_focus()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			$CanvasLayer/StopMouse.mouse_filter = MOUSE_FILTER_IGNORE
	else:
		#Input.warp_mouse(Vector2(100, 100))
		use_mouse_for_menus = false
		get_viewport().gui_release_focus()
		$MarginContainer/VBoxContainer/MouseHBox/MouseMenusCheck.grab_focus()
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		$CanvasLayer/StopMouse.mouse_filter = MOUSE_FILTER_STOP
	#_on_joy_connection_changed(0, Input.get_connected_joypads().size() > 0)

func _on_timer_check_toggled(toggled_on):
	AudioManager.play_audio(sfxs.get_sfx("click"),1, 1.4)
	speedrun_timer = toggled_on

static func set_loaded_settings():
	#if sfx_slider_value == 0:
	#	AudioServer.set_bus_mute(2, true)
	#else:
	AudioServer.set_bus_volume_db(2, linear_to_db(sfx_slider_value))
	#if music_slider_value == 0:
	#	AudioServer.set_bus_mute(1, true)
	#else:
	AudioServer.set_bus_volume_db(1, linear_to_db(music_slider_value))
	
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, borderless)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(304, 192))
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_keybind_button_pressed():
	AudioManager.play_audio(sfxs.get_sfx("click"),1, 1.4)
	save_settings()
	var keybind_menu = load("res://Menu/keybind_menu.tscn").instantiate()
	keybind_menu.back_scene = back_scene
	get_parent().add_child(keybind_menu)
	queue_free()

func _on_effects_check_toggled(toggled_on):
	reduced_effects = toggled_on
