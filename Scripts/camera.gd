extends Camera2D

var tween
var map_open = false

var keys_collected = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("BlurShaderLayer/ColorRect").material.set_shader_parameter("blur_power", 0) #radical blur disabled

func set_keys(state: String, remove: bool = false):
	if remove:
		keys_collected -= 1
	
	if keys_collected == 0:
		$UIContainer/RedKeySprite.position.x = 295
		$UIContainer/GreenKeySprite.position.x = 295
		
		if state == "Red":
			$UIContainer/RedKeySprite.visible = !remove
		if state == "Green":
			$UIContainer/GreenKeySprite.visible = !remove
			
	if keys_collected == 1:
		if state == "Red":
			$UIContainer/RedKeySprite.position.x = 279
			$UIContainer/GreenKeySprite.position.x = 295
			$UIContainer/RedKeySprite.visible = !remove
		if state == "Green":
			$UIContainer/GreenKeySprite.position.x = 279
			$UIContainer/RedKeySprite.position.x = 295
			$UIContainer/GreenKeySprite.visible = !remove
			
	if !remove:
		keys_collected += 1
	
	if keys_collected < 0:
		keys_collected = 0
	elif keys_collected > 2:
		keys_collected = 2

func flash(opacity, enter, hold, exit):
	#var start_opacity = $FlashLayer.modulate.a
	$FlashLayer.modulate = Color(1, 1, 1, 0)
	tween = self.create_tween()
	
	tween.tween_property($FlashLayer, "modulate:a", opacity, enter) #fade in the new opacity
	tween.tween_property($FlashLayer, "modulate:a", opacity, hold) #hold the opacity for a time
	tween.tween_property($FlashLayer, "modulate:a", 0, exit) #fade out to original opacity
	
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
		await get_tree().create_timer(interval).timeout
	position = origin

func radial_blur(power: float = 0.03, duration: float = 0.3, sampling_count: int = 6):
	var callable = Callable(self, "set_shader_value").bind("BlurShaderLayer/ColorRect", "blur_power")
	$BlurShaderLayer/ColorRect.material.set_shader_parameter("sampling_count", sampling_count)
	tween = self.create_tween()
	tween.tween_method(callable, power, 0, duration); # args: (method / start value / end value / duration)
	
	
func invert_color(power: float, duration: float):
	var callable = Callable(self, "set_shader_value").bind("InvertColorLayer/ColorRect", "strength")
	tween = self.create_tween()
	tween.tween_method(callable, power, 0.0, duration); # args: (method / start value / end value / duration)
	

func set_shader_value(value: float, path: String, param: String):
	get_node(path).material.set_shader_parameter(param, value)
