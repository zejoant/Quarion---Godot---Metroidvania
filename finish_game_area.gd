extends Node2D

var player
var camera
var world
var tween

func _ready():
	world = get_node("/root/World")
	player = get_node("/root/World/Player")
	camera = get_node("/root/World/Camera")
	$PlayerSprite.material.set_shader_parameter("palette_choice", player.get_node("Sprite2D").material.get_shader_parameter("palette_choice"))
	$Tilemap.set_layer_enabled(0, false)
	$Tilemap.set_layer_enabled(4, false)

func _input(event):
	if event.is_action_released("UI Up") and player.get_node("Area2D").has_overlapping_bodies() and player.get_node("Area2D").get_overlapping_bodies().has($FinishGameArea):
		
		change_to_outro()
		#player.can_move = false
		player.paused = true
		camera.fade("000000", 1, 0.5, 1, 0.5)
		
		await get_tree().create_timer(0.7, false).timeout #fix antenna
		player.visible = false
		$PlayerSprite.visible = true
		camera.get_node("UILayer").visible = false
		world.get_node("MusicPlayer").stream_paused = true
		
		await get_tree().create_timer(2, false).timeout #remove glass
		$ShipComponents/TopLeft.region_rect = Rect2(0, 32, 96, 24)
		$PlayerSprite.position = Vector2(116, 164)
		$PlayerSprite.flip_h = true
		
		await get_tree().create_timer(1.5, false).timeout #throw glass
		$ShipGlass.visible = true
		$ShipComponents/Right.region_rect = Rect2(96, 160, 72, 64)
		$PlayerSprite.position = Vector2(169, 160)
		$PlayerSprite.region_rect = Rect2(272, 32, 16, 16)
		$PlayerSprite.flip_h = false
		
		await get_tree().create_timer(1.5, false).timeout #fix hatch
		$PlayerSprite.position = Vector2(57, 176)
		$PlayerSprite.region_rect = Rect2(256, 32, 16, 16)
		$ShipGlass.visible = false
		
		await get_tree().create_timer(1.5, false).timeout #put new glass
		$ShipComponents/BottomLeft.region_rect = Rect2(0, 184, 96, 40)
		$ShipComponents/Right.region_rect = Rect2(96, 32, 72, 64)
		$PlayerSprite.position = Vector2(116, 164)
		$PlayerSprite.flip_h = true
		$PlayerSprite.region_rect = Rect2(240, 0, 16, 16)
		
		await get_tree().create_timer(1.5, false).timeout
		camera.fade("000000", 1, 0.5, 1, 0.5)
		
		await get_tree().create_timer(1.5, false).timeout #ship on planks
		$Green.visible = false
		$Tilemap.set_layer_enabled(0, true)
		$Tilemap.set_layer_enabled(4, true)
		$PlayerSprite.visible = false
		$ShipLegs.visible = true
		$ShipComponents.position.y -= 3*8
		
		await get_tree().create_timer(1.5, false).timeout #ship raised
		tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		await tween.tween_property($ShipComponents, "position:y", -4*8, 0.8).finished
		
		await get_tree().create_timer(2, false).timeout #start thrusters
		$ShipComponents/Thrusters.visible = true
		
		await get_tree().create_timer(1, false).timeout #fly away
		tween = create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.parallel().tween_property($ShipLegs, "position:y", -2.5*8, 1.6)
		tween.parallel().tween_property($ShipLegs, "position:x", 90*8, 4.6)
		tween.parallel().tween_property($ShipComponents, "position", Vector2(90*8, -5.5*8), 4.6)
		
		await get_tree().create_timer(3, false).timeout #ship exit screen
		camera.fade("000000", 1, 0.5, 2, 0)
		await get_tree().create_timer(1.5, false).timeout #transition to space
		
		change_to_outro()
		#var outro_cutscene = load("res://outro_cutscene.tscn").instantiate()
		#outro_cutscene.death_count = player.death_count
		#outro_cutscene.jump_count = player.jump_count
		#outro_cutscene.completion_time = world.timer
		#outro_cutscene.completion_percentage = world.completion_percentage
		#get_tree().root.add_child(outro_cutscene)
		#get_tree().current_scene = outro_cutscene
		#world.queue_free()
		#get_tree().change_scene_to_file("res://outro_cutscene.tscn")
		
func change_to_outro():
	var outro_cutscene = load("res://outro_cutscene.tscn").instantiate()
	outro_cutscene.death_count = player.death_count
	outro_cutscene.jump_count = player.jump_count
	outro_cutscene.completion_time = world.timer
	outro_cutscene.completion_percentage = world.completion_percentage
	get_tree().root.add_child(outro_cutscene)
	get_tree().current_scene = outro_cutscene
	world.queue_free()
