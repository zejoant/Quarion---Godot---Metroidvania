extends Control

var exiting = false

func _ready():
	hide()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _on_joy_connection_changed(_device_id, connected):
	get_viewport().gui_release_focus()
	if !connected:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		#get_viewport().gui_release_focus()
		$MarginContainer/VBoxContainer/ResumeButton.grab_focus()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_resume_button_pressed():
	get_owner().pauseMenu()

func _on_quit_button_pressed():
	get_tree().paused = false
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
		get_owner().pauseMenu()
		if get_parent().get_node_or_null("OptionsMenu") != null:
			SaveManager.save_settings()
			get_parent().get_node("OptionsMenu").queue_free()
		exiting = false
