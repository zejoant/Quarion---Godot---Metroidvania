extends StaticBody2D

@export var sfxs : AudioLibrary
var player
var ui
var selector
var description
var open = false
var slot_pos = 0
var tween
var not_tweening = true

var bought_items: Array[bool]
# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_node("/root/World/Player")
	ui = get_node("/root/World/Camera/UILayer/ShopUIContainer")
	selector = ui.get_node("SelectorSprite")
	description = ui.get_node("DescriptionSprite")
	bought_items = get_node("/root/World").bought_shop_items
	
	if bought_items[0]:
		get_node("/root/World/Camera/UILayer/ShopUIContainer/BoughtCover1").visible = true
		go_down()
	if bought_items[1]:
		get_node("/root/World/Camera/UILayer/ShopUIContainer/BoughtCover2").visible = true
	if bought_items[2]:
		get_node("/root/World/Camera/UILayer/ShopUIContainer/BoughtCover3").visible = true
	
#func _process(_delta):
	#if not_tweening:
		#not_tweening = false
		#tween = self.create_tween()
		#await tween.tween_property(selector, "modulate", Color(0.6314, 0.8078, 0.6039), 0.5)
		#await tween.tween_property(selector, "modulate", Color.WHITE, 0.5).finished
		#not_tweening = true

func selector_flash():
	while open:
		if not_tweening:
			not_tweening = false
			tween = self.create_tween()
			await tween.tween_property(selector, "modulate", Color(0.6314, 0.8078, 0.6039), 0.5)
			await tween.tween_property(selector, "modulate", Color.WHITE, 0.5).finished
			not_tweening = true

func _input(event):
	if !open and player.in_interact_area and player.get_node("Area2D").get_overlapping_bodies()[0] == self:
		if event.is_action_pressed("Jump"):
			player.can_move = false
			open = true
			selector_flash()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			ui.visible = true
			self.create_tween().tween_property(ui.get_node("UICover"), "modulate:a", 0, 0.3)
			
	elif open:
		if event.is_action_pressed("UI Down"):
			go_down()
		elif event.is_action_pressed("UI Up"):
			go_up()
		elif event.is_action_pressed("UI Exit"):
			exit_shop()
			
		elif event.is_action_pressed("UI Confirm"):
			if slot_pos == 0 and player.apple_count >= 10:
				AudioManager.play_audio(sfxs.get_sfx("buy"))
				player.green_key_state = "collected"
				bought_items[0] = true
				get_node("/root/World/Camera").set_keys("Green")
				get_node("/root/World/Player").update_apple_count(-10)
				get_node("/root/World/Camera/UILayer/ShopUIContainer/BoughtCover1").visible = true
				go_down()
			elif slot_pos == 1 and player.apple_count >= 15:
				AudioManager.play_audio(sfxs.get_sfx("buy"))
				player.amulet_pieces += 1
				bought_items[1] = true
				get_node("/root/World/Player").update_apple_count(-15)
				get_node("/root/World/Camera/UILayer/ShopUIContainer/BoughtCover2").visible = true
				go_down()
				exit_shop()
				get_node("/root/World/Camera").collect_amulet_piece()
			elif slot_pos == 2 and player.apple_count >= 26:
				AudioManager.play_audio(sfxs.get_sfx("buy"))
				player.has_bubble = true
				bought_items[2] = true
				get_node("/root/World/Player").update_apple_count(-26)
				get_node("/root/World/Camera/UILayer/ShopUIContainer/BoughtCover3").visible = true
				go_down()
			else:
				AudioManager.play_audio(sfxs.get_sfx("buy_deny"))

func exit_shop():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	await self.create_tween().tween_property(ui.get_node("UICover"), "modulate:a", 1, 0.3).finished
	ui.visible = false
	player.can_move = true
	open = false
	get_node("/root/World").save_game()
			
func go_down():
	if bought_items[0] and bought_items[1] and bought_items[2]:
		get_node("/root/World/Camera/UILayer/ShopUIContainer/SelectorSprite").visible = false
		exit_shop()
		return
	
	slot_pos = fposmod(slot_pos + 1, 3)
	selector.position.y = 75 + slot_pos * 11
	selector.region_rect.position.y = 16 + slot_pos * 11
	description.region_rect.position.y = 48 + slot_pos * 32
	if (bought_items[0] and slot_pos == 0) or (bought_items[1] and slot_pos == 1) or (bought_items[2] and slot_pos == 2):
		go_down()
func go_up():
	if bought_items[0] and bought_items[1] and bought_items[2]:
		get_node("/root/World/Camera/UILayer/ShopUIContainer/SelectorSprite").visible = false
		exit_shop()
		return
	
	slot_pos = fposmod(slot_pos - 1, 3)
	selector.position.y = 75 + slot_pos * 11
	selector.region_rect.position.y = 16 + slot_pos * 11
	description.region_rect.position.y = 48 + slot_pos * 32
	if (bought_items[0] and slot_pos == 0) or (bought_items[1] and slot_pos == 1) or (bought_items[2] and slot_pos == 2):
		go_up()

func interactable():
	return true
