extends Sprite2D

var origin
var time: float = 0

func _ready():
	origin = position
	var tween = self.create_tween()
	#tween.parallel().tween_property(self, "scale", Vector2(0.5, 0.5), 0.3)
	await tween.parallel().tween_method(self.set_alpha, 0.1, 0.0, 0.3).finished
	call_deferred("queue_free")

func set_alpha(value):
	var col = material.get_shader_parameter("color")
	col.a = value
	material.set_shader_parameter("color", col)

#func _physics_process(_delta):
	#time += 1
	#position.y = origin.y - (time/2.0 + sin(time/2.0))
	#position.x -= 1
