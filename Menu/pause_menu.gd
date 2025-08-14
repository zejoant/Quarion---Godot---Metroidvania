extends Control

@export var sfxs : AudioLibrary
var exiting = false

var paused = false

var song_paused: bool

func _ready():
	hide()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _on_joy_connection_changed(_device_id, connected):
	#get_viewport().gui_release_focus()
	if paused:
		if !connected and OptionsMenu.use_mouse_for_menus:
			get_viewport().gui_release_focus()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			$CanvasLayer/StopMouse.mouse_filter = MOUSE_FILTER_IGNORE
		else:
			get_viewport().gui_release_focus()
			$MarginContainer/VBoxContainer/ResumeButton.grab_focus()
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			$CanvasLayer/StopMouse.mouse_filter = MOUSE_FILTER_STOP

func pause_menu():
	if paused:
		if get_node("/root/World").get_tilemap():
			get_node("/root/World").get_tilemap().resume_animated_tiles()
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		hide()
		paused = false
		AudioManager.audioPlayer.stream_paused = song_paused
		get_tree().paused = false
		$CanvasLayer/StopMouse.mouse_filter = MOUSE_FILTER_IGNORE
	else:
		if get_node("/root/World").get_tilemap():
			get_node("/root/World").get_tilemap().pause_animated_tiles()
		song_paused = AudioManager.audioPlayer.stream_paused
		AudioManager.pause_song()
		get_tree().paused = true
		show()
		paused = true
		_on_joy_connection_changed(0, Input.get_connected_joypads().size() > 0)

	if get_node("/root/World/WorldMap").open:
		get_node("/root/World/WorldMap").open_or_close()

func _on_resume_button_pressed():
	AudioManager.play_audio(sfxs.get_sfx("click"),1, 1.4)
	pause_menu()
	$CanvasLayer/StopMouse.mouse_filter = MOUSE_FILTER_IGNORE
	#get_owner().pauseMenu()

func _on_quit_button_pressed():
	AudioManager.play_audio(sfxs.get_sfx("click"),1, 1.4)
	AudioManager.stop_song()
	SaveManager.save_game(get_node("/root/World"))
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Menu/main_menu.tscn")


func _on_options_button_pressed():
	var instance = load("res://Menu/options_menu.tscn").instantiate()
	instance.back_scene = "game"
	get_parent().add_child(instance)
	hide()
	$CanvasLayer/StopMouse.mouse_filter = MOUSE_FILTER_IGNORE

func _unhandled_input(event):
	if (event.is_action_pressed("Pause") or event.is_action_pressed("ui_cancel") and visible) and !exiting:
		exiting = true
		await get_tree().create_timer(0.01).timeout
		pause_menu()
		#get_owner().pauseMenu()
		if get_parent().get_node_or_null("OptionsMenu") != null:
			SaveManager.save_settings()
			get_parent().get_node("OptionsMenu").queue_free()
		if get_parent().get_node_or_null("KeybindMenu") != null:
			SaveManager.save_keymaps()
			get_parent().get_node("KeybindMenu").queue_free()
		exiting = false
	
	#if !get_viewport().gui_get_focus_owner():
		#if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			#$MarginContainer/VBoxContainer/ResumeButton.grab_focus()
