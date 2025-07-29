extends Node2D

@export var frequency = 1.0 # objects spawned per second
@export var object : PackedScene = load("res://Objects/boulder.tscn")
var cooldown = false

func _physics_process(_delta):
	if !cooldown:
		cooldown = true
		spawn_object()
		await get_tree().create_timer(1.0 / frequency).timeout
		cooldown = false

func spawn_object():
	var inst = object.instantiate()
	call_deferred("add_child", inst)
