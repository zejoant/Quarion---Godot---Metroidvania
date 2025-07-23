extends Control

var exiting = false

var paused = false

func _ready():
	hide()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _on_joy_connection_changed(_device_id, connected):
	#get_viewport().gui_release_focus()
	if !connected and OptionsMenu.use_mouse_for_menus:
		get_viewport().gui_release_focus()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		get_viewport().gui_release_focus()
		$MarginContainer/VBoxContainer/ResumeButton.grab_focus()
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func pause_menu():
	if paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		hide()
		#get_node("/root/World").process_mode = PROCESS_MODE_INHERIT
		get_tree().paused = false
	else:
		#get_node("/root/World").process_mode = PROCESS_MODE_DISABLED
		get_tree().paused = true
		show()
		if Input.get_connected_joypads().size() > 0 or !OptionsMenu.use_mouse_for_menus:
			if !Input.joy_connection_changed.is_connected(Callable(self, "_on_joy_connection_changed")):
				Input.joy_connection_changed.connect(_on_joy_connection_changed)
			$MarginContainer/VBoxContainer/ResumeButton.grab_focus()
			#pause_menu.get_node("MarginContainer/VBoxContainer/ResumeButton").grab_focus()
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	paused = !paused
	if get_node("/root/World/WorldMap").open:
		get_node("/root/World/WorldMap").open_or_close()

func _on_resume_button_pressed():
	pause_menu()
	#get_owner().pauseMenu()

func _on_quit_button_pressed():
	AudioManager.stop_song()
	get_tree().paused = false
	#get_node("/root/World").process_mode = PROCESS_MODE_INHERIT
	get_tree().change_scene_to_file("res://Menu/main_menu.tscn")


func _on_options_button_pressed():
	var instance = load("res://Menu/options_menu.tscn").instantiate()
	instance.back_scene = "game"
	get_parent().add_child(instance)
	hide()

func _input(event):
	if (event.is_action_pressed("Pause") or event.is_action_pressed("UI Back") and visible) and !exiting:
		exiting = true
		await get_tree().create_timer(0.01).timeout
		pause_menu()
		#get_owner().pauseMenu()
		if get_parent().get_node_or_null("OptionsMenu") != null:
			SaveManager.save_settings()
			get_parent().get_node("OptionsMenu").queue_free()
		exiting = false
	
	#if !get_viewport().gui_get_focus_owner():
		#if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			#$MarginContainer/VBoxContainer/ResumeButton.grab_focus()
