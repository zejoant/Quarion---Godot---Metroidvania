extends Camera2D

@export var sfxs : AudioLibrary ## Tagged audio files to play from this scene
var tween
var map_open = false

var keys_collected = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("RadialBlurLayer/ColorRect").material.set_shader_parameter("blur_power", 0) #radical blur disabled

func update_apple_count(value: int):
	$UILayer/UIContainer/AppleCount.text = str(value)

func set_keys(state: String, remove: bool = false):
	if remove:
		keys_collected -= 1
	
	if keys_collected == 0:
		$UILayer/UIContainer/RedKeySprite.position.x = 295
		$UILayer/UIContainer/GreenKeySprite.position.x = 295
		
		if state == "Red":
			$UILayer/UIContainer/RedKeySprite.visible = !remove
		if state == "Green":
			$UILayer/UIContainer/GreenKeySprite.visible = !remove
			
	if keys_collected == 1:
		if state == "Red":
			$UILayer/UIContainer/RedKeySprite.position.x = 279
			$UILayer/UIContainer/GreenKeySprite.position.x = 295
			$UILayer/UIContainer/RedKeySprite.visible = !remove
		if state == "Green":
			$UILayer/UIContainer/GreenKeySprite.position.x = 279
			$UILayer/UIContainer/RedKeySprite.position.x = 295
			$UILayer/UIContainer/GreenKeySprite.visible = !remove
			
	if !remove:
		keys_collected += 1
	
	if keys_collected < 0:
		keys_collected = 0
	elif keys_collected > 2:
		keys_collected = 2

func collect_amulet_piece():
	
	
	var player = get_node("/root/World/Player")
	#if player.amulet_pieces == 5:
		#$UILayer/AmuletContainer/Piece1.modulate.a = 1
		#$UILayer/AmuletContainer/Piece2.modulate.a = 1
		#$UILayer/AmuletContainer/Piece3.modulate.a = 1
		#$UILayer/AmuletContainer/Piece4.modulate.a = 1
		
	var piece = get_node("UILayer/AmuletContainer/Piece" + str(player.amulet_pieces))
	player.disable_movement()
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
	
	AudioManager.play_audio(sfxs.get_sfx("amulet_out"))
	blur(0, 0.2)
	if player.amulet_pieces == 5:
		flash(1, 0.3, 0.5, 0.4, Color("#78b45c"))
	tween = self.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property($UILayer/AmuletContainer, "scale", Vector2(10, 10), 0.3)
	await tween.parallel().tween_property($UILayer/AmuletContainer, "modulate:a", 0, 0.3).finished
	
	player.disable_movement(false)
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
	
	tween = self.create_tween()
	tween.tween_property($FlashLayer, "modulate:a", opacity, enter) #fade in the new opacity
	tween.tween_interval(hold)
	#tween.tween_property($FlashLayer, "modulate:a", opacity, hold) #hold the opacity for a time
	await tween.tween_property($FlashLayer, "modulate:a", 0, exit).finished #fade out to original opacity
	$FlashLayer.modulate = old_color

func fade(color: String, opacity: float, enter: float, hold: float, exit: float):
	#var start_opacity = $FlashLayer.modulate.a
	$FlashLayer.modulate = Color(color + "00")
	tween = self.create_tween()
	
	tween.tween_property($FlashLayer, "modulate:a", opacity, enter) #fade in the new opacity
	tween.tween_property($FlashLayer, "modulate:a", opacity, hold) #hold the opacity for a time
	tween.tween_property($FlashLayer, "modulate:a", 0, exit) #fade out to original opacity

func shake(strength: int, interval: float, count: int):
	var rng = RandomNumberGenerator.new()
	var origin = position
	for i in count:
		position = Vector2(origin.x + rng.randf_range(-1, 1)*strength, origin.y + rng.randf_range(-1, 1)*strength)
		await get_tree().create_timer(interval, false).timeout
	position = origin

func zoom_camera(amount: float, time: float, aim: Vector2 = Vector2(152, 96)):
	tween = self.create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(self, "zoom", Vector2(amount, amount), time)
	tween.parallel().tween_property(self, "position", aim, time)

func radial_blur(power: float = 0.03, duration: float = 0.3, sampling_count: int = 6):
	var callable = Callable(self, "set_shader_value").bind("RadialBlurLayer/ColorRect", "blur_power")
	$RadialBlurLayer/ColorRect.material.set_shader_parameter("sampling_count", sampling_count)
	tween = self.create_tween()
	tween.tween_method(callable, power, 0, duration); # args: (method / start value / end value / duration)


func invert_color(power: float, duration: float):
	var callable = Callable(self, "set_shader_value").bind("InvertColorLayer/ColorRect", "strength")
	tween = self.create_tween()
	tween.tween_method(callable, power, 0.0, duration); # args: (method / start value / end value / duration)
	

func set_shader_value(value: float, path: String, param: String):
	get_node(path).material.set_shader_parameter(param, value)
