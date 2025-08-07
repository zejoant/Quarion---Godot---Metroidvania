#@tool
extends Node2D

var sfx = preload("res://Sfx/looping platform.wav")

@export_enum("up", "down") var direction = "up"
@export var speed : float = 1.0
@export var sound: bool = false
var moving = false
var dir
var start_pos
var platform
var player
const loop_distance = 80#40

func _ready():
	if sound:
		AudioManager.play_audio(sfx, speed/2.0, 0.8, self)
	player = get_node("/root/World/Player")
	platform = $ColorRect/StaticBody2D
	start_pos = platform.position.y
	if direction == "down":
		dir = 1
	else:
		dir = -1

func _physics_process(_delta):
	if !moving:
		moving = true
		await self.create_tween().tween_method(move_platform, start_pos, start_pos + loop_distance*dir, speed).finished
		platform.position.y = start_pos
		
		moving = false

func move_platform(pos):
	if !player.is_dead:
		if player.get_slide_collision_count() != 0 and player.get_slide_collision(0).get_collider() == $ColorRect/StaticBody2D:
			player.position.y += pos-platform.position.y
	platform.position.y = pos
