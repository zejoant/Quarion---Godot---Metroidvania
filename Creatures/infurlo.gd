extends StaticBody2D

@export var sfxs : AudioLibrary ## Tagged audio files to play from this scene
@export_range(0, 120) var cooldown: int = 60 ## cooldown in frames
@export_range(0, 120) var offset: int = 0 ## offset in frames
@export_enum("up", "down", "right", "left") var direction = "down" ##shoot direction
@export_enum("crimson", "brick", "rock") var style = "crimson"
@export var sound : bool = false
@export var blast_effect: bool = true
@export var bullet_collide_effect: bool = true

var bullet = preload("res://Objects/bullet.tscn")
var dir
var cooldown_counter

var first_frame = true

# Called when the node enters the scene tree for the first time.
func _ready():
	cooldown_counter = int(float(cooldown)/2.0)
	if direction == "down":
		dir = Vector2(0, 1)
	if direction == "up":
		dir = Vector2(0, -1)
	if direction == "right":
		dir = Vector2(1, 0)
	if direction == "left":
		dir = Vector2(-1, 0)
	$FrontSprite.rotation = dir.angle() - PI/2.0
	$BackSprite.rotation = dir.angle() - PI/2.0
	$BlastEffect.rotation = dir.angle() - PI/2.0
	
	if style == "rock":
		$FrontSprite.region_rect.position.y += 8
		$BackSprite.region_rect.position.y += 8
	elif style == "brick":
		$FrontSprite.region_rect.position.y += 16
		$BackSprite.region_rect.position.y += 16


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	if offset > 0:
		offset -= 1
		return
	
	if cooldown_counter > 0:
		cooldown_counter -= 1
		return
	
	if cooldown_counter == 0:
		cooldown_counter = cooldown
		var b = bullet.instantiate()
		b.direction = dir
		b.speed = 1
		b.collide = true
		b.position = position
		b.sprite = "ball"
		b.grace_period = 20
		if !bullet_collide_effect:
			b.collide_effect = false
		if sound:
			AudioManager.play_audio(sfxs.get_sfx("shoot"))
			b.sound = true
		get_parent().add_child(b)
		if blast_effect:
			$AnimationPlayer.play("Blast")
		position -= dir
		await get_tree().create_timer(0.2, false).timeout
		position += dir
		#self.create_tween().tween_property(self, "position", position+dir, 0.2)
