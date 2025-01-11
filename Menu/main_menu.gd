extends Control

var world = preload("res://world.tscn").instantiate()

func _on_continue_button_pressed():
	world.new_game = false
	get_tree().root.add_child(world)
	queue_free()

func _on_new_game_button_pressed():
	#get_node("Menu").visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	$Menu/VersionNumber.visible = false
	self.create_tween().tween_property($Menu, "offset:x", -150, 0.2)
	self.create_tween().tween_method(set_blur_power, 1.032, 0, 0.5); # args: (method / start value / end value / duration)
	get_node("IntroObjects/AnimationPlayer").play("Start")

func set_blur_power(power: float):
	get_node("BlurRect").material.set_shader_parameter("amount", power)

func _on_options_button_pressed():
	get_tree().change_scene_to_file("res://Menu/options_menu.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
