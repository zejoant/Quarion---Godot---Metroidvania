extends Node2D

@export var frequency = 1.0 # objects spawned per second
@export var object : PackedScene = load("res://Objects/boulder.tscn")
var cooldown = false

# Called when the node enters the scene tree for the first time.
func _ready():
	print(object.resource_name)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if !cooldown:
		cooldown = true
		spawn_object()
		await get_tree().create_timer(1.0 / frequency).timeout
		cooldown = false

func spawn_object():
	var inst = object.instantiate()
	#if inst.name == "Boulder":
	#	pass
	call_deferred("add_child", inst)
