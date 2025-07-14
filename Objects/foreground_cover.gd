extends Area2D

@onready var world = get_node("/root/World")

func _ready():
	await Engine.get_main_loop().process_frame
	monitoring = true

func _on_body_entered(body): #fade out foreground
	if body is CharacterBody2D:
		if world.changed_room_frames > 0:
			$Tilemap.modulate.a = 0
		else:
			self.create_tween().tween_property($Tilemap, "modulate:a", 0, 0.1)
			
		world.get_node("Camera/LensCircle").change_lens(world.room_coords, false, 1)
		$Tilemap.set_layer_enabled(1, false)

func _on_body_exited(body): #fade in foreground
	if body is CharacterBody2D:
		world.get_node("Camera/LensCircle").change_lens(world.room_coords, false, 2)
		self.create_tween().tween_property($Tilemap, "modulate:a", 1, 0.1)
		$Tilemap.set_layer_enabled(1, true)
