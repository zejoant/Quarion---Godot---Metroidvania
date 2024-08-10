extends Control

var back_scene = "menu"
static var volume_slider_value = 0
static var window_mode = 0

func _ready():
	$MarginContainer/VBoxContainer/Volume.value = volume_slider_value
	$MarginContainer/VBoxContainer/WindowMode.selected = window_mode
	_on_window_mode_item_selected(window_mode)

func _on_back_button_pressed():
	#save_settings()
	if back_scene == "menu":
		get_tree().change_scene_to_file("res://Menu/main_menu.tscn")
	elif back_scene == "game":
		get_parent().get_node("PauseMenu").show()
		queue_free()

func _on_volume_value_changed(value):
	volume_slider_value = value
	if value == -25:
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, false)
		AudioServer.set_bus_volume_db(0, value)


func _on_window_mode_item_selected(index):
	window_mode = index
	if index == 0:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	elif index == 1:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	elif index == 2:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func save_settings():
	pass
