#@tool
extends Node2D

@export_enum("left", "right") var direction = "left"
@export var speed : float = 1.0
var moving = false
var dir
var start_pos
var platform
var player
const loop_distance = 56

func _ready():
	player = get_node("/root/World/Player")
	platform = $ColorRect/StaticBody2D
	start_pos = platform.position.x
	if direction == "left":
		dir = -1
	else:
		dir = 1

func _process(_delta):
	if !moving:
		moving = true
		await self.create_tween().tween_method(move_platform, start_pos, start_pos + loop_distance*dir, speed).finished
		platform.position.x = start_pos
		#await self.create_tween().tween_property(platform, "position:x", start_pos + loop_distance*dir, speed).finished
		
		moving = false

func move_platform(pos):
	if player.get_slide_collision_count() != 0 and player.get_slide_collision(0).get_collider() == $ColorRect/StaticBody2D:
			player.position.x += pos-platform.position.x
	platform.position.x = pos
