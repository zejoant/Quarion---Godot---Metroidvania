extends Camera2D

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
	player.can_move = false
	blur(1.032, 0.3)
	$UILayer/AmuletContainer.visible = true
	

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
	
func fade(color, opacity, enter, hold, exit):
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
