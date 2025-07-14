extends Area2D

@export var sfxs : AudioLibrary
var player
var ui
var selector
var description
var open = false
var slot_pos = 0
var tween
var not_tweening = true
var value
var color 

var player_in_area: bool = false

var bought_items: Array[bool]
# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_node("/root/World/Player")
	ui = $ShopUIContainer#get_node("/root/World/Camera/UILayer/ShopUIContainer")
	selector = $ShopUIContainer/SelectorSprite#ui.get_node("SelectorSprite")
	description = $ShopUIContainer/DescriptionSprite#ui.get_node("DescriptionSprite")
	bought_items = get_node("/root/World").bought_shop_items
	
	$ShopUIContainer.global_position = Vector2(304, 0)
	
	if bought_items[0]:
		$ShopUIContainer/KeyButton.disabled = true
		$ShopUIContainer/KeyButton.focus_mode = 0 as Control.FocusMode
		$ShopUIContainer/LockCover.visible = false
	
	if bought_items[1] or !bought_items[0]:
		$ShopUIContainer/AmuletButton.disabled = true
		$ShopUIContainer/AmuletButton.focus_mode = 0 as Control.FocusMode
	if bought_items[2] or !bought_items[0]:
		$ShopUIContainer/BubbleButton.disabled = true
		$ShopUIContainer/BubbleButton.focus_mode = 0 as Control.FocusMode

	
func _on_joy_connection_changed(_device_id, connected):
	release_all_focus()
	if !connected and OptionsMenu.use_mouse_for_menus:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		#$ShopUIContainer/KeyButton.grab_focus()
		find_next_focus($ShopUIContainer/BubbleButton)
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func open_setup():
	open = true
	ui.visible = true
	self.create_tween().tween_property($ShopUIContainer/UICover, "modulate:a", 0, 0.3)
	player.disable_movement()
	get_node("/root/World").other_ui_open = true
	selector_flash()
	release_all_focus()
	#if Input.get_connected_joypads().size() > 0:
		#find_next_focus($ShopUIContainer/BubbleButton)
		#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#else:
		#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	_on_joy_connection_changed(0, Input.get_connected_joypads().size() > 0)
		
	if !Input.joy_connection_changed.is_connected(Callable(self, "_on_joy_connection_changed")):
				Input.joy_connection_changed.connect(self._on_joy_connection_changed)

func selector_flash():
	while open:
		value = abs(cos(Engine.get_frames_drawn()/20.0))
		color = Color8(145+int(value*110), 215+int(value*40), 143+int(value*112))
		selector.modulate = color
		await Engine.get_main_loop().process_frame

#func _process(_delta):
	#if open:
		#value = abs(cos(Engine.get_frames_drawn()/20.0))
		#color = Color8(145+int(value*110), 215+int(value*40), 143+int(value*112))
		#selector.modulate = color

func _input(event):
	if !open and player_in_area: #and player.get_node("Area2D").has_overlapping_bodies() and player.get_node("Area2D").get_overlapping_bodies().has(self):
		if event.is_action_pressed("ui_up"):
			open_setup()
	else:
		if event.is_action_released("Pause") or event.is_action_released("UI Back"):
			exit_shop()
	
	#if !get_viewport().gui_get_focus_owner():
		#if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			#find_next_focus($ShopUIContainer/BubbleButton, true)

func exit_shop():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	await self.create_tween().tween_property($ShopUIContainer/UICover, "modulate:a", 1, 0.3).finished
	ui.visible = false
	get_node("/root/World").save_game()
	
	get_node("/root/World").other_ui_open = false
	open = false
	player.disable_movement(false)

func _on_key_button_focus_entered():
	set_focus(0)
func _on_amulet_button_focus_entered():
	set_focus(1)
func _on_bubble_button_focus_entered():
	set_focus(2)

func _on_key_button_mouse_entered():
	if !$ShopUIContainer/KeyButton.disabled:
		set_focus(0)
func _on_amulet_button_mouse_entered():
	if !$ShopUIContainer/AmuletButton.disabled:
		set_focus(1)
func _on_bubble_button_mouse_entered():
	if !$ShopUIContainer/BubbleButton.disabled:
		set_focus(2)

func _on_key_button_mouse_exited():
	release_all_focus()
func _on_amulet_button_focus_exited():
	release_all_focus()
func _on_bubble_button_mouse_exited():
	release_all_focus()
	
func set_focus(pos):
	selector.visible = true
	description.visible = true
	slot_pos = pos
	selector.position.y = 75 + slot_pos * 11
	selector.region_rect.position.y = 16 + slot_pos * 11
	description.region_rect.position.y = 48 + slot_pos * 32

func find_next_focus(button: Button, ignore_controller: bool = false):
	if Input.get_connected_joypads().size() > 0 or ignore_controller or !OptionsMenu.use_mouse_for_menus:
		var next = button.find_next_valid_focus()
		if next:
			selector.visible = true
			description.visible = true
			next.grab_focus()
		else:
			release_all_focus()
	else:
		release_all_focus()

func release_all_focus():
	get_viewport().gui_release_focus()
	slot_pos = -1
	selector.visible = false
	description.visible = false

func _on_key_button_pressed():
	if player.apple_count < 10:
		AudioManager.play_audio(sfxs.get_sfx("buy_deny"))
		return
	
	$ShopUIContainer/AmuletButton.focus_mode = 2 as Control.FocusMode
	$ShopUIContainer/BubbleButton.focus_mode = 2 as Control.FocusMode
	$ShopUIContainer/AmuletButton.disabled = false
	$ShopUIContainer/BubbleButton.disabled = false
	$ShopUIContainer/LockCover.visible = false
	
	$ShopUIContainer/KeyButton.disabled = true
	$ShopUIContainer/KeyButton.focus_mode = 0 as Control.FocusMode
	#$ShopUIContainer/KeyButton.find_next_valid_focus().grab_focus()
	find_next_focus($ShopUIContainer/KeyButton)
	
	AudioManager.play_audio(sfxs.get_sfx("buy"))
	player.green_key_state = "collected"
	get_node("/root/World").completion_percentage += 2
	bought_items[0] = true
	get_node("/root/World/Camera").set_keys("Green")
	player.update_apple_count(-10)


func _on_amulet_button_pressed():
	if player.apple_count < 18:
		AudioManager.play_audio(sfxs.get_sfx("buy_deny"))
		return
	
	$ShopUIContainer/AmuletButton.disabled = true
	$ShopUIContainer/AmuletButton.focus_mode = 0 as Control.FocusMode
	#$ShopUIContainer/AmuletButton.find_next_valid_focus().grab_focus()
	find_next_focus($ShopUIContainer/AmuletButton)
	
	AudioManager.play_audio(sfxs.get_sfx("buy"))
	player.amulet_pieces += 1
	get_node("/root/World").completion_percentage += 1
	bought_items[1] = true
	get_node("/root/World/Player").update_apple_count(-15)
	exit_shop()
	get_node("/root/World/Camera").collect_amulet_piece()


func _on_bubble_button_pressed():
	if player.apple_count < 22:
		AudioManager.play_audio(sfxs.get_sfx("buy_deny"))
		return
	
	$ShopUIContainer/BubbleButton.disabled = true
	$ShopUIContainer/BubbleButton.focus_mode = 0 as Control.FocusMode
	#$ShopUIContainer/BubbleButton.find_next_valid_focus().grab_focus()
	find_next_focus($ShopUIContainer/BubbleButton)
	
	AudioManager.play_audio(sfxs.get_sfx("buy"))
	get_node("/root/World").completion_percentage += 2
	player.bubble_action(true, false)
	bought_items[2] = true
	get_node("/root/World/Player").update_apple_count(-26)


func _on_body_entered(body):
	if body is CharacterBody2D:
		player_in_area = true
		$InputIndicator.visible = true


func _on_body_exited(body):
	if body is CharacterBody2D:
		player_in_area = false
		$InputIndicator.visible = false
