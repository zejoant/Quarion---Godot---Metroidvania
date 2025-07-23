extends StaticBody2D

@export var sfxs : AudioLibrary ## Tagged audio files to play from this scene
@export var speed : float
@export var direction : Vector2
@export var collide : bool = false
@export var sound : bool = false
@export_enum("arrow", "ball") var sprite = "arrow"
@export var grace_period: int = 0

func _ready():
	if collide:
		$RayCast2D.enabled = true
	rotation = direction.angle() - PI/2
	
	if sprite == "ball":
		$AnimationPlayer.play("Fireball")
		$Sprite2D.region_rect = Rect2(96, 104, 8, 8)

func _physics_process(_delta):
	if $Sprite2D.visible == false:
		pass
	elif collide and $RayCast2D.is_colliding() and grace_period <= 0:
		speed = 0
		$AnimationPlayer.play("Collide")
		#$Sprite2D.visible = false
		#$CollisionShape2D.disabled = true
		#$CPUParticles2D.emitting = false
		if sound:
			AudioManager.play_audio(sfxs.get_sfx("collide"))
		await get_tree().create_timer(1, false).timeout
		call_deferred("queue_free")
	else:
		position += direction * speed
		grace_period -= 1
		
		if position.y > 30*8 or position.y < -6*8 or position.x > 44*8 or position.x < -6*8:
			call_deferred("queue_free")

func setup(s, d, p, sound_on: bool = false, collide_on: bool = false, grace: int = 0):
	speed = s
	direction = d
	position = p
	
	sound = sound_on
	collide = collide_on
	grace_period = grace
	
