extends StaticBody2D

@export var speed : Vector2
@export var homing : bool = false
@export var target_player : bool = false
@export_range(0, 10) var acceleration : float = 1
@export_range(0, 50) var max_speed : float = 50
@export_range(0, 60) var startup_speed : int = 30
@export var sfxs : AudioLibrary

var player
var homing_lifetime = 120

func _ready():
	player = get_node("/root/World/Player")
	$AnimationPlayer.play("Default")
	scale = Vector2(0, 0)
	AudioManager.play_audio(sfxs.get_sfx("charge up"))

func _process(_delta):
	if scale.x < 1:
		scale.x += 1.0/float(startup_speed)
		scale.y += 1.0/float(startup_speed)
	else:
		if $TrailParticles.visible != true:
			#get_node("/root/World/Camera").flash(0.8, 0, 0.1, 0.2)
			get_node("/root/World/Camera").invert_color(0.7, 0.3)
			AudioManager.play_audio(sfxs.get_sfx("shot 1"))
			AudioManager.play_audio(sfxs.get_sfx("shot 2"))
			$TrailParticles.visible = true
			scale = Vector2(1, 1)
			if target_player:
				var angle = position.angle_to_point(player.position)
				speed = speed.rotated(angle)
		position += speed
		if homing and homing_lifetime > 0:
			speed += Vector2(player.position.x-position.x, player.position.y-position.y).normalized()*acceleration
			if abs(speed.x) > max_speed:
				speed.x = sign(speed.x)*max_speed
			if abs(speed.y) > max_speed:
				speed.y = sign(speed.y)*max_speed
		
		if position.y > 30*8 or position.y < -6*8 or position.x > 44*8 or position.x < -6*8:
			queue_free()
		
		homing_lifetime -= 1

#func setup(s, d, p):
#	speed = s
#	direction = d
#	position = p
	
