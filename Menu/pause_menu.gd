extends Control

var exiting = false

func _ready():
	hide()

func _on_resume_button_pressed():
	get_owner().pauseMenu()

func _on_quit_button_pressed():
	get_tree().paused = false
	get_owner().queue_free()
	get_tree().change_scene_to_file("res://Menu/main_menu.tscn")


func _on_options_button_pressed():
	var instance = load("res://Menu/options_menu.tscn").instantiate()
	instance.back_scene = "game"
	get_parent().add_child(instance)
	hide()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and !exiting:
		exiting = true
		await get_tree().create_timer(0.01).timeout
		get_owner().pauseMenu()
		exiting = false
