#@tool
extends Node2D

@export_enum("up", "down") var direction = "up"
@export var speed : float = 1.0
var moving = false
var dir
var start_pos
var platform
var player
const loop_distance = 80#40

func _ready():
	player = get_node("/root/World/Player")
	platform = $ColorRect/StaticBody2D
	start_pos = platform.position.y
	if direction == "down":
		dir = 1
	else:
		dir = -1

func _process(_delta):
	if !moving:
		moving = true
		await self.create_tween().tween_method(move_platform, start_pos, start_pos + loop_distance*dir, speed).finished
		platform.position.y = start_pos
		#await self.create_tween().tween_property(platform, "position:x", start_pos + loop_distance*dir, speed).finished
		
		moving = false

func move_platform(pos):
	if player.get_slide_collision_count() != 0 and player.get_slide_collision(0).get_collider() == $ColorRect/StaticBody2D:
			player.position.y += pos-platform.position.y
	platform.position.y = pos
