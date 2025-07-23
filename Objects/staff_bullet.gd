extends StaticBody2D

@export var sfxs : AudioLibrary

@export var aim_pos: Vector2
@export var speed: float = 250
#@export var spread: int = 0
#@export var enter_spin: bool = true

var dir: Vector2
var hit: bool = false
var tween: Tween
var spin_done: bool = false
var rng = RandomNumberGenerator.new()

func _ready():
	dir = (aim_pos-position).normalized()
	rotation = dir.angle() - PI/2.0
	$Sprite2D.scale = Vector2(0, 0)
	tween = self.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	#if enter_spin:
	tween.parallel().tween_property(self, "rotation", rotation+4*PI, 0.7)
	tween.parallel().tween_property($Sprite2D, "scale", Vector2(1, 1), 0.5)
	await tween.tween_property($AimLine, "modulate:a", 0.4, 0.2).finished
	AudioManager.play_audio(sfxs.get_sfx("shot"))
	
	$CollisionShape2D.disabled = false
	spin_done = true
	
	tween = self.create_tween()
	tween.tween_property($AimLine, "modulate:a", 0, 0.3)

func _physics_process(delta):
	if spin_done:
		if $RayCast2D.is_colliding() and !hit:
			hit = true
			AudioManager.play_audio(sfxs.get_sfx("hit"))
			get_node("/root/World/Camera").shake(1, 0.03, 2)
			$HitParticles.emitting = true
			$Sprite2D.z_index = 2
			$CollisionShape2D.disabled = true
			
			tween = self.create_tween()
			tween.tween_interval(0.5)
			await tween.tween_property(self, "modulate:a", 0, 0.5).finished
			call_deferred("queue_free")
			
		elif !hit:
			position += dir*speed*delta

func setup(aim, pos, s = 250, spread = 0):#, spin = true, c_scale = 1):
	if spread:
		aim_pos = aim + (aim - pos).normalized().rotated(PI/2.0) * rng.randi_range(-spread, spread)
	else:
		aim_pos = aim
		
	position = pos
	speed = s
	#spread = aim_spread
	
	#var aim = Vector2(aim_pos.x, player.position.y)
	#var pos = Vector2(rng.randi_range(16, 288), lev_origin.y-rng.randi_range(0, 1)*8)
	#s.setup(aim + (aim - pos).normalized().rotated(PI/2.0) * rng.randi_range(-64, 64), pos)
	#enter_spin = spin
	#$CollisionShape2D.scale.x = c_scale
	
