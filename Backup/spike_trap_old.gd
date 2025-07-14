extends StaticBody2D

var dir
var anim_tween
var animating = false
var origin: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	origin = position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	$Sprite2D.region_rect.position.x += 1
	
	#if !animating:
		#animating = true
		#
		#await create_tween().tween_interval(0.55).finished
		#create_tween().tween_method(extend_spike, 0, 16, 0.05)
		#$AudioStreamPlayer2D.play()
		#await create_tween().tween_interval(1.2).finished
		#create_tween().tween_method(extend_spike, 16, 0, 0.10)
		#
		#animating = false


func extend_spike(distance):
	position.x = origin.x + distance*dir.x
	position.y = origin.y + distance*dir.y


#sets rotation based on tile rotation
func set_dir(d: Vector2):
	dir = d
	if dir != Vector2(0, -1):
		rotation_degrees = dir.x*90 + dir.y*180
	
