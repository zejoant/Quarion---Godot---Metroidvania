#@tool
extends StaticBody2D

var sfx = preload("res://Sfx/looping platform.wav")

@export_enum("up", "down") var direction = "up"
@export var speed : float = 1.0
@export var sound: bool = false
var moving = false
var dir
var start_pos
const loop_distance = 80#40

#var player_on_platform = false
var player

func _ready():
	if sound:
		AudioManager.play_audio(sfx, speed/2.0, 0.8, self)
	start_pos = position.y
	if direction == "down":
		dir = 1
	else:
		dir = -1

func _physics_process(_delta):
	if !moving:
		moving = true
		await self.create_tween().tween_method(move_platform, start_pos, start_pos + loop_distance*dir, speed).finished
		position.y = start_pos
		
		moving = false

func move_platform(pos):
	#if player_on_platform:
	#		player.position.y += pos-position.y
	position.y = pos
