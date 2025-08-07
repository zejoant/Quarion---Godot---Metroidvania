extends Area2D

@onready var world = get_node("/root/World")
@export var lens_circle: bool = true

func _ready():
	await Engine.get_main_loop().process_frame
	monitoring = true

func _on_body_entered(body): #fade out foreground
	if body is CharacterBody2D:
		if world.changed_room_frames > 0:
			modulate.a = 0
		else:
			self.create_tween().tween_property(self, "modulate:a", 0, 0.1)
		
		if lens_circle:
			world.get_node("Camera/LensCircle").change_lens(world.room_coords, false, 1)
		$Tilemap.set_layer_enabled(1, false)

func _on_body_exited(body): #fade in foreground
	if body is CharacterBody2D:
		if lens_circle:
			world.get_node("Camera/LensCircle").change_lens(world.room_coords, false, 2)
		self.create_tween().tween_property(self, "modulate:a", 1, 0.1)
		$Tilemap.set_layer_enabled(1, true)
