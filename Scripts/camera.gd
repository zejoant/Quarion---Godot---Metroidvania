extends Camera2D

var tween
var map_open = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite2D.modulate.a = 0
	get_node("CanvasLayer/ColorRect").material.set_shader_parameter("blur_power", 0) #radical blur disabled


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func flash(opacity, enter, hold, exit):
	var start_opacity = get_node("Sprite2D").modulate.a
	tween = self.create_tween()
	
	tween.tween_property($Sprite2D, "modulate:a", opacity, enter) #fade in the new opacity
	tween.tween_property($Sprite2D, "modulate:a", opacity, hold) #hold the opacity for a time
	tween.tween_property($Sprite2D, "modulate:a", start_opacity, exit) #fade out to original opacity
	

func radial_blur():
	tween = self.create_tween()
	tween.tween_method(set_shader_value, 0.03, 0, 0.3); # args: (method / start value / end value / duration)

func set_shader_value(value: float):
	get_node("CanvasLayer/ColorRect").material.set_shader_parameter("blur_power", value)
	
func alternate_map():
	if !map_open:
		$Sprite2D.modulate = Color(0, 0, 0, 0.8)
		$Map.modulate.a = 1
		map_open = true
	elif map_open:
		$Sprite2D.modulate = Color(1, 1, 1, 0)
		$Map.modulate.a = 0
		map_open = false

func close_map():
	$Sprite2D.modulate = Color(1, 1, 1, 0)
	$Map.modulate.a = 0
	map_open = false

func open_map():
	$Sprite2D.modulate = Color(0, 0, 0, 0.8)
	$Map.modulate.a = 1
	map_open = true
