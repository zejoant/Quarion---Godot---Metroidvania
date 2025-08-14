extends Area2D

@export_enum("DropPrompt", "MapPrompt") var type = "DropPrompt"
@export var wait_before: float = 2

@onready var world = get_node("/root/World")
var waitTween: Tween

func _ready():
	await Engine.get_main_loop().process_frame
	#if (type == "DropPrompt" and !world.show_drop_prompt) or (type == "MapPrompt" and !world.show_map_prompt):
	if !world.prompts_to_show[type]:
		queue_free()
		return
	
	if type == "MapPrompt":
		reparent(world)

func _input(event):
	if event.is_action_pressed("Map") and type == "MapPrompt":
		fade_out(true, true)
	elif event.is_action_pressed("Drop") and type == "DropPrompt":
		#world.prompts_to_show[type] = false
		#world.show_drop_prompt = false
		fade_out(true, false)

func fade_out(instant: bool = false, free: bool = false):
	if waitTween:
		waitTween.kill()
	
	if !instant:
		await self.create_tween().tween_property(get_node(type), "modulate:a", 0, 0.4).finished
	else:
		get_node(type).modulate.a = 0
	
	if free:
		queue_free()

func _on_body_entered(body):
	if world.prompts_to_show[type] and body is CharacterBody2D:
		await get_tree().create_timer(wait_before, false).timeout
		
		self.create_tween().tween_property(get_node(type), "modulate:a", 1, 0.4)
		if Input.get_connected_joypads().size() > 0:
			get_node(type + "/ControllerInput").visible = true
			get_node(type + "/KeyboardInput").visible = false
		
		world.prompts_to_show[type] = false
		
		waitTween = self.create_tween()
		await waitTween.tween_interval(10).finished
		fade_out(false, true)
