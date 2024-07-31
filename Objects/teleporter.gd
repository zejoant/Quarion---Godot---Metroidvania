extends Area2D

@export var destination_room : Vector2 = Vector2(0, 1)
@export var destination_position : Vector2 = Vector2(19, 12)

func _on_body_entered(_body):
	get_node("/root/World").change_room(destination_room)
	get_node("/root/World/Player").position = destination_position*8

func _physics_process(_delta):
	$Sprite2D.rotation_degrees += 1
	$Sprite2D2.rotation_degrees -= 2
