extends CPUParticles2D

@export var width: int = 12

# Called when the node enters the scene tree for the first time.
func _ready():
	set_width(width)

func set_width(w: int):
	scale_curve_x.set_point_value(0, w)
