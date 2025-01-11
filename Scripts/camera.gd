extends Camera2D

var tween
var map_open = false

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("BlurShaderLayer/ColorRect").material.set_shader_parameter("blur_power", 0) #radical blur disabled

func flash(opacity, enter, hold, exit):
	#var start_opacity = $FlashLayer.modulate.a
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

func radial_blur():
	var callable = Callable(self, "set_shader_value").bind("BlurShaderLayer/ColorRect", "blur_power")
	tween = self.create_tween()
	tween.tween_method(callable, 0.03, 0, 0.3); # args: (method / start value / end value / duration)
	
	
func invert_color(power: float, duration: float):
	var callable = Callable(self, "set_shader_value").bind("InvertColorLayer/ColorRect", "strength")
	tween = self.create_tween()
	tween.tween_method(callable, power, 0.0, duration); # args: (method / start value / end value / duration)
	

func set_shader_value(value: float, path: String, param: String):
	get_node(path).material.set_shader_parameter(param, value)
