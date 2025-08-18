extends Camera2D

@export var sfxs : AudioLibrary ## Tagged audio files to play from this scene
var map_open = false

#var keys_collected = 0
var p_up_window_open = false

var shake_origin

var tween: Tween
var zoom_tween: Tween
var radial_tween: Tween
var flash_tween: Tween
var fade_tween: Tween
var invert_tween: Tween
var p_up_tween: Tween

enum CollectedItem {RED_KEY, GREEN_KEY, AMULET}
var item_display: Array[CollectedItem]

func _ready():
	close_p_up_window(true)
	$InvertColorLayer/ColorRect.material.set_shader_parameter("strength", 0) #invert color disabled
	$RadialBlurLayer/ColorRect.material.set_shader_parameter("blur_power", 0) #radical blur disabled

func load_items():
	if get_node("/root/World/Player").green_key_state == "collected":
		add_collected_item(CollectedItem.GREEN_KEY)
	if get_node("/root/World/Player").red_key_state == "collected":
		add_collected_item(CollectedItem.RED_KEY)
	if get_node("/root/World/Player").amulet_pieces == 5:
		add_collected_item(CollectedItem.AMULET)

func update_apple_count(value: int):
	$UILayer/UIContainer/AppleCount.text = str(value)
	if value == 0:
		for item in get_parent().bought_shop_items:
			if !item:
				return
		$UILayer/UIContainer/AppleCount.visible = false
		$UILayer/UIContainer/AppleSprite.visible = false

func add_collected_item(item: CollectedItem):
	item_display.append(item)
	update_item_display()

func remove_collected_item(item: CollectedItem):
	item_display.erase(item)
	update_item_display()

func update_item_display():
	$UILayer/UIContainer/RedKeySprite.visible = false
	$UILayer/UIContainer/GreenKeySprite.visible = false
	$UILayer/UIContainer/AmuletSprite.visible = false
	
	for i in item_display.size():
		if item_display[i] == CollectedItem.RED_KEY:
			$UILayer/UIContainer/RedKeySprite.position.x = 295 - 16*i
			$UILayer/UIContainer/RedKeySprite.visible = true
		elif item_display[i] == CollectedItem.GREEN_KEY:
			$UILayer/UIContainer/GreenKeySprite.position.x = 295 - 16*i
			$UILayer/UIContainer/GreenKeySprite.visible = true
		elif item_display[i] == CollectedItem.AMULET:
			$UILayer/UIContainer/AmuletSprite.position.x = 295 - 16*i
			$UILayer/UIContainer/AmuletSprite.visible = true
			

#func set_keys(state: String, remove: bool = false):
	#if remove:
		#keys_collected -= 1
	#
	#if keys_collected == 0:
		#$UILayer/UIContainer/RedKeySprite.position.x = 295
		#$UILayer/UIContainer/GreenKeySprite.position.x = 295
		#
		#if state == "Red":
			#$UILayer/UIContainer/RedKeySprite.visible = !remove
		#if state == "Green":
			#$UILayer/UIContainer/GreenKeySprite.visible = !remove
			#
	#if keys_collected == 1:
		#if state == "Red":
			#$UILayer/UIContainer/RedKeySprite.position.x = 279
			#$UILayer/UIContainer/GreenKeySprite.position.x = 295
			#$UILayer/UIContainer/RedKeySprite.visible = !remove
		#if state == "Green":
			#$UILayer/UIContainer/GreenKeySprite.position.x = 279
			#$UILayer/UIContainer/RedKeySprite.position.x = 295
			#$UILayer/UIContainer/GreenKeySprite.visible = !remove
			#
	#if !remove:
		#keys_collected += 1
	#
	#if keys_collected < 0:
		#keys_collected = 0
	#elif keys_collected > 2:
		#keys_collected = 2

func enable_amulet_pieces(count: int):
	get_parent().get_node("Player").amulet_pieces = count
	for num in range(count, 0, -1):
		get_node("UILayer/AmuletContainer/Piece" + str(num)).modulate.a = 1

func collect_amulet_piece():
	var player = get_node("/root/World/Player")
	
	var piece = get_node("UILayer/AmuletContainer/Piece" + str(player.amulet_pieces))
	player.disable_movement()
	AudioManager.pause_song()
	blur(1.032, 0.3)
	$FlashLayer.modulate = Color(0, 0, 0, 0.5)
	$UILayer/AmuletContainer.modulate.a = 1
	piece.scale = Vector2(3, 3)
	
	tween = self.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_interval(0.8)
	tween.tween_property(piece, "modulate:a", 1, 0.2)
	await tween.tween_property(piece, "scale", Vector2(1, 1), 0.3).finished
	
	AudioManager.play_audio(sfxs.get_sfx("amulet_impact"))
	$UILayer/AmuletContainer/RingExplosionParticles.emitting = true
	$UILayer/AmuletContainer.scale = Vector2(1.6, 1.6)
	self.create_tween().tween_property($UILayer/AmuletContainer, "scale", Vector2(2, 2), 0.2)
	await get_tree().create_timer(2, false).timeout
	
	tween = self.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	if player.amulet_pieces == 5:
		add_collected_item(CollectedItem.AMULET)
		$UILayer/UIContainer/AmuletSprite.visible = false
		tween.parallel().tween_property($UILayer/AmuletContainer, "position", $UILayer/UIContainer/AmuletSprite.position, 1)
		await tween.parallel().tween_property($UILayer/AmuletContainer, "scale", Vector2(1, 1), 1).finished
		for child in $UILayer/AmuletContainer.get_children():
			if child == $UILayer/AmuletContainer/RingExplosionParticles:
				child.emitting = true
				continue
			child.visible = false
			$UILayer/UIContainer/AmuletSprite.visible = true
		AudioManager.play_audio(sfxs.get_sfx("amulet_out"))
		blur(0, 0.2)
		SteamManager.get_achivement("FullAmulet")
	else:
		AudioManager.play_audio(sfxs.get_sfx("amulet_out"))
		blur(0, 0.2)
		tween.parallel().tween_property($UILayer/AmuletContainer, "scale", Vector2(10, 10), 0.3)
		await tween.parallel().tween_property($UILayer/AmuletContainer, "modulate:a", 0, 0.3).finished
	
	player.disable_movement(false)
	AudioManager.resume_song()
	$FlashLayer.modulate = Color(1, 1, 1, 0)
	$UILayer/AmuletContainer.scale = Vector2(2, 2)


func blur(strength: float, time):
	#Callable allows me to call a method and send a param along in tween_method()
	var callable = Callable(self, "set_shader_value").bind("BlurLayer/ColorRect", "amount") 
	var current_blur = $BlurLayer/ColorRect.material.get_shader_parameter("amount")
	create_tween().tween_method(callable, current_blur, strength, time); # args: (method / start value / end value / duration)

func flash(opacity, enter, hold, exit, color: Color = Color(1, 1, 1, 0)):
	#var start_opacity = $FlashLayer.modulate.a
	var old_color = $FlashLayer.modulate
	old_color.a = 0
	$FlashLayer.modulate = color#Color(1, 1, 1, 0)
	
	if fade_tween:
		fade_tween.kill()
	
	flash_tween = self.create_tween()
	flash_tween.tween_property($FlashLayer, "modulate:a", opacity, enter) #fade in the new opacity
	flash_tween.tween_interval(hold)
	#tween.tween_property($FlashLayer, "modulate:a", opacity, hold) #hold the opacity for a time
	await flash_tween.tween_property($FlashLayer, "modulate:a", 0, exit).finished #fade out to original opacity
	$FlashLayer.modulate = old_color

func fade(color: String, opacity: float, enter: float, hold: float, exit: float):
	#var start_opacity = $FlashLayer.modulate.a
	if flash_tween:
		flash_tween.kill()
	$FlashLayer.modulate = Color(color + "00")
	fade_tween = self.create_tween()
	
	fade_tween.tween_property($FlashLayer, "modulate:a", opacity, enter) #fade in the new opacity
	fade_tween.tween_property($FlashLayer, "modulate:a", opacity, hold) #hold the opacity for a time
	fade_tween.tween_property($FlashLayer, "modulate:a", 0, exit) #fade out to original opacity

func shake(strength: int, interval: float, count: int):
	var rng = RandomNumberGenerator.new()
	shake_origin = Vector2(152, 96)#position
	for i in count:
		position = Vector2(shake_origin.x + rng.randf_range(-1, 1)*strength, shake_origin.y + rng.randf_range(-1, 1)*strength)
		await get_tree().create_timer(interval, false).timeout
	position = shake_origin

func zoom_camera(amount: float, time: float, aim: Vector2 = Vector2(152, 96)):
	shake_origin = aim
	if time == 0:
		zoom = Vector2(amount, amount)
		position = aim
	else:
		if zoom_tween:
			zoom_tween.kill()
		zoom_tween = self.create_tween()
		zoom_tween.set_ease(Tween.EASE_IN_OUT)
		zoom_tween.set_trans(Tween.TRANS_QUAD)
		zoom_tween.parallel().tween_property(self, "zoom", Vector2(amount, amount), time)
		zoom_tween.parallel().tween_property(self, "position", aim, time)

func radial_blur(power: float = 0.03, duration: float = 0.3, sampling_count: int = 6):
	var callable = Callable(self, "set_shader_value").bind("RadialBlurLayer/ColorRect", "blur_power")
	$RadialBlurLayer/ColorRect.material.set_shader_parameter("sampling_count", sampling_count)
	radial_tween = self.create_tween()
	radial_tween.tween_method(callable, power, 0, duration); # args: (method / start value / end value / duration)


func invert_color(power: float, duration: float):
	var callable = Callable(self, "set_shader_value").bind("InvertColorLayer/ColorRect", "strength")
	invert_tween = self.create_tween()
	await invert_tween.tween_method(callable, power, 0.0, duration).finished # args: (method / start value / end value / duration)
	

func set_shader_value(value: float, path: String, param: String):
	get_node(path).material.set_shader_parameter(param, value)

func close_p_up_window(instant: bool = false):
	p_up_window_open = false
	$PowerUpTexts/InputIndicator.modulate.a = 0
	if p_up_tween:
		p_up_tween.kill()
	if !instant:
		p_up_tween = self.create_tween()
		p_up_tween.set_ease(Tween.EASE_OUT)
		p_up_tween.set_trans(Tween.TRANS_BOUNCE)
		p_up_tween.parallel().tween_property($PowerUpTexts/MaskLight, "scale:y", 0, 0.3)
		p_up_tween.parallel().tween_property($PowerUpTexts/BorderTop, "offset:y", 4, 0.3)
		await p_up_tween.parallel().tween_property($PowerUpTexts/BorderBottom, "offset:y", -4, 0.3).finished
	else:
		$PowerUpTexts/MaskLight.scale.y = 0
		$PowerUpTexts/BorderTop.offset.y = 4
		$PowerUpTexts/BorderBottom.offset.y = -4
	$PowerUpTexts.visible = false
	$PowerUpTexts/SkyfishAura.visible = false
	$PowerUpTexts/SpiderGauntlets.visible = false
	$PowerUpTexts/SwiftwindAmulet.visible = false
	$PowerUpTexts/PegasusBoots.visible = false
	$PowerUpTexts/FreezewakeCharm.visible = false
	$PowerUpTexts/TreasureMap.visible = false
	$PowerUpTexts/PhantomFlame.visible = false

func open_p_up_window(p_up: String):
	$PowerUpTexts/InputIndicator.modulate.a = 0
	p_up_window_open = true
	$PowerUpTexts.visible = true
	get_node(str("PowerUpTexts/", p_up)).visible = true
	if p_up == "SwiftwindAmulet" and Input.get_connected_joypads().size() > 0:
		$PowerUpTexts/SwiftwindAmulet/InputController.visible = true
		$PowerUpTexts/SwiftwindAmulet/InputKeyboard.visible = false
	
	p_up_tween = self.create_tween()
	p_up_tween.set_ease(Tween.EASE_OUT)
	p_up_tween.set_trans(Tween.TRANS_BOUNCE)
	p_up_tween.parallel().tween_property($PowerUpTexts/MaskLight, "scale:y", 2.375, 0.3)
	p_up_tween.parallel().tween_property($PowerUpTexts/BorderTop, "offset:y", -14, 0.3)
	await p_up_tween.parallel().tween_property($PowerUpTexts/BorderBottom, "offset:y", 14, 0.3).finished
	
	await get_tree().create_timer(1.5, false).timeout
	#p_up_window_open = true
	p_up_tween = self.create_tween()
	p_up_tween.tween_property($PowerUpTexts/InputIndicator, "modulate:a", 1, 0.2)

func hide_ui(show_ui: bool = false):
	$UILayer/UIContainer.visible = show_ui
	

func _input(event):
	if $PowerUpTexts/InputIndicator.modulate.a > 0 and p_up_window_open and event.is_action_pressed("Interact"):
		close_p_up_window()
	
