extends Control

var world = preload("res://world.tscn").instantiate()

func _on_continue_button_pressed():
	world.new_game = false
	get_tree().root.add_child(world)
	queue_free()

func _on_new_game_button_pressed():
	get_tree().change_scene_to_file("res://world.tscn")

func _on_options_button_pressed():
	get_tree().change_scene_to_file("res://Menu/options_menu.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
