extends Node2D

@export var sfxs : AudioLibrary
@export_enum("red", "purple", "brown") var boulder_color = "red"
@export_enum("stop on wall", "turn on wall", "ignore wall") var boulder_type = "stop on wall"

@export var frequency = 1.0 # objects spawned per second
@export var object : PackedScene = preload("res://Objects/boulder.tscn")
var cooldown = false

func _ready():
	AudioManager.play_audio(sfxs.get_sfx("boulder_sound"), 1, 1, get_node("/root/World").get_room())

func _physics_process(_delta):
	if !cooldown:
		cooldown = true
		spawn_object()
		await get_tree().create_timer(1.0 / frequency, false).timeout
		cooldown = false

func spawn_object():
	var inst = object.instantiate()
	inst.color = boulder_color
	inst.mode = boulder_type
	call_deferred("add_child", inst)
