extends StaticBody2D

@export var sfxs : AudioLibrary ## Tagged audio files to play from this scene
@export_range(0, 120) var cooldown: int = 60 ## cooldown in frames
@export_range(0, 120) var offset: int = 0 ## offset in frames
@export_enum("up", "down", "right", "left") var direction = "down" ##shoot direction
@export var sound : bool = false

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
		if sound:
			AudioManager.play_audio(sfxs.get_sfx("shoot"))
			b.sound = true
		get_parent().add_child(b)
