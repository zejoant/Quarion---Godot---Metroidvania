extends Control

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
