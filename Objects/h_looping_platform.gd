#@tool
extends Node2D

var sfx = preload("res://Sfx/looping platform.wav")

@export_enum("left", "right") var direction = "left"
@export var speed : float = 1.0
@export var sound: bool = false
var moving = false
var dir
var start_pos
var platform
var player
const loop_distance = 56

var leave_frame = false

func _ready():
	if sound:
		AudioManager.play_audio(sfx, speed/2.0, 0.8, self)
	player = get_node("/root/World/Player")
	platform = $ColorRect/StaticBody2D
	start_pos = platform.position.x
	if direction == "left":
		dir = -1
	else:
		dir = 1

func _physics_process(_delta):
	if !moving:
		moving = true
		await self.create_tween().tween_method(move_platform, start_pos, start_pos + loop_distance*dir, speed).finished
		platform.position.x = start_pos
		
		moving = false

func move_platform(pos):
	if !player.is_dead:
		if player.get_slide_collision_count() != 0 and player.get_slide_collision(0).get_collider() == $ColorRect/StaticBody2D:
			player.position.x += pos-platform.position.x
			leave_frame = true
		elif leave_frame:
			player.position.x += pos-platform.position.x
			leave_frame = false
	platform.position.x = pos
