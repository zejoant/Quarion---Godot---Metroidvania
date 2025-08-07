extends Control

@export var sfxs : AudioLibrary
@onready var input_button = preload("res://Menu/input_button.tscn")
@onready var action_list = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ActionList

var is_remapping: bool = false
var action_to_remap = null
var remapping_button = null

var back_scene: String
var input_type: int = 0

var input_actions = {
	"Left": "Move left",
	"Right": "Move right",
	"Jump": "Jump",
	"Drop": "Drop",
	"Dash": "Dash",
	"Map": "Open map",
	"Quick Respawn": "Respawn",
	"Interact": "Interact"
}

func _ready():
	#SaveManager.load_keymaps()
	_on_joy_connection_changed(0, Input.get_connected_joypads().size() > 0)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	
	#create_action_list()

func _on_joy_connection_changed(_device_id, connected):
	if !connected and OptionsMenu.use_mouse_for_menus:
		get_viewport().gui_release_focus()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		$CanvasLayer/StopMouse.mouse_filter = MOUSE_FILTER_IGNORE
	else:
		get_viewport().gui_release_focus()
		$Panel/MarginContainer/VBoxContainer/HBoxContainer/BackButton.grab_focus()
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		$CanvasLayer/StopMouse.mouse_filter = MOUSE_FILTER_STOP
	
	if !connected:
		input_type = 0
		create_action_list()
	else:
		input_type = 1
		create_action_list()

func create_action_list():
	for item in action_list.get_children():
		item.queue_free()
	
	for action in input_actions:
		if input_type == 0 or (action != "Right" and action != "Left" and action != "Drop"):
			var button = input_button.instantiate()
			var action_label = button.find_child("LabelAction")
			var input_label = button.find_child("LabelInput")
			
			action_label.text = input_actions[action]
			
			var events = InputMap.action_get_events(action)
			if events.size() > input_type:
				input_label.text = format_event(events[input_type].as_text())
			else:
				input_label.text = ""
			
			action_list.add_child(button)
			button.pressed.connect(_on_input_button_pressed.bind(button, action))

func _on_input_button_pressed(button, action):
	if !is_remapping:
		AudioManager.play_audio(sfxs.get_sfx("click"),1, 1.4)
		is_remapping = true
		action_to_remap = action
		remapping_button = button
		button.find_child("LabelInput").text = "Awaiting input..."

func _input(event):
	if is_remapping:
		if input_type == 1:
			if (event is InputEventJoypadButton and event.pressed) or (event is InputEventJoypadMotion and abs(event.axis_value) == 1):
				var events = InputMap.action_get_events(action_to_remap)
				events[input_type] = event
				InputMap.erase_action(action_to_remap)
				InputMap.add_action(action_to_remap)
				for e in events:
					InputMap.action_add_event(action_to_remap, e)
				update_action_list(remapping_button, event)
				is_remapping = false
				action_to_remap = null
				remapping_button = null
				accept_event()
		
		elif input_type == 0:
			if event is InputEventKey or (event is InputEventMouseButton and event.pressed):
				
				if event is InputEventMouseButton and event.double_click:
					event.double_click = false
				
				var events = InputMap.action_get_events(action_to_remap)
				events[input_type] = event
				InputMap.erase_action(action_to_remap)
				InputMap.add_action(action_to_remap)
				for e in events:
					InputMap.action_add_event(action_to_remap, e)

				update_action_list(remapping_button, event)
				
				is_remapping = false
				action_to_remap = null
				remapping_button = null
				
				accept_event()
	else:
		if event.is_action_pressed("ui_cancel"):
			_on_back_button_pressed()
			accept_event()

func update_action_list(button, event):
	AudioManager.play_audio(sfxs.get_sfx("key"))
	button.find_child("LabelInput").text = format_event(event.as_text())

func _on_reset_button_pressed():
	AudioManager.play_audio(sfxs.get_sfx("click"),1, 1.4)
	InputMap.load_from_project_settings()
	create_action_list()

func _on_back_button_pressed():
	AudioManager.play_audio(sfxs.get_sfx("click"),1, 1.4)
	SaveManager.save_keymaps()
	var instance = load("res://Menu/options_menu.tscn").instantiate()
	instance.back_scene = back_scene
	get_parent().add_child(instance)
	queue_free()

func format_event(t: String) -> String:
	if input_type == 0:
		return t.trim_suffix(" (Physical)")
	if t.find(",") != -1:
		return t.substr(t.find("(")+1, t.find(",")-t.find("(")-1)
	elif t.find(")") != -1:
		return t.substr(t.find("(")+1, t.find(")")-t.find("(")-1)
	return t.substr(t.find("(")+1, -1)
