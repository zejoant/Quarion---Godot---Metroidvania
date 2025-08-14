extends Node2D

@export var sfxs : AudioLibrary

var player
var camera
var world
var tween

var player_in_area: bool = false

func _ready():
	world = get_node("/root/World")
	player = get_node("/root/World/Player")
	camera = get_node("/root/World/Camera")
	$PlayerSprite.material.set_shader_parameter("palette_choice", player.current_palette)
	$"ShipComponents/Red&Yellow".material.set_shader_parameter("palette_choice", player.current_palette)
	$Tilemap.set_layer_enabled(0, false)
	$Tilemap.set_layer_enabled(4, false)
	
func _input(event):
	if event.is_action_pressed("Interact") and player_in_area and player.velocity.x == 0 and !player.paused:
		world.get_speedrun_timer().stop()
		if world.get_speedrun_time() < 1200:
			SteamManager.get_achivement("Speedrun")
		if player.death_count == 0:
			SteamManager.get_achivement("NoDeath")
		
		$InputIndicator.visible = false
		player.paused = true
		camera.fade("000000", 1, 0.5, 1, 0.5)
		
		await get_tree().create_timer(0.7, false).timeout #fix antenna
		if world.secret_boss_beaten:
			SteamManager.get_achivement("GoodEnding")
			world.red_as_companion.visible = false
			$RedSprite.visible = true
			$RedSprite.position = Vector2(259, 161)
			$RedSprite.region_rect = Rect2(192, 16, 16, 16)
		else:
			SteamManager.get_achivement("NormalEnding")
		player.visible = false
		$PlayerSprite.visible = true
		$PlayerSprite.position = Vector2(40, 148)
		camera.get_node("UILayer").visible = false
		AudioManager.stop_song()
		play_sfx("hit_1", 3, 0.4, 1)
		
		#change_to_outro()
		
		await get_tree().create_timer(2, false).timeout #remove glass
		AudioManager.play_audio(sfxs.get_sfx("move"))
		play_sfx("hit_1", 2, 0.4, 0.4)
		if world.secret_boss_beaten:
			$RedSprite.visible = false
			$Green.visible = false
		$ShipComponents/TopLeft.region_rect = Rect2(0, 32, 96, 24)
		$PlayerSprite.position = Vector2(116, 164)
		$PlayerSprite.flip_h = true
		
		await get_tree().create_timer(1.5, false).timeout #throw glass
		AudioManager.play_audio(sfxs.get_sfx("glass"))
		AudioManager.play_audio(sfxs.get_sfx("move"))
		if world.secret_boss_beaten:
			$RedSprite.visible = true
			$RedSprite.position = Vector2(172, 160)
			$RedSprite.region_rect = Rect2(208, 48, 16, 16)
			$PlayerSprite.position = Vector2(162, 160)
		else:
			$PlayerSprite.position = Vector2(169, 160)
		$PlayerSprite.region_rect = Rect2(272, 32, 16, 16)
		$PlayerSprite.flip_h = false
		$ShipGlass.visible = true
		$ShipComponents/Right.region_rect = Rect2(96, 160, 72, 64)
		
		await get_tree().create_timer(1.5, false).timeout #fix hatch
		AudioManager.play_audio(sfxs.get_sfx("glass_throw"))
		AudioManager.play_audio(sfxs.get_sfx("move"))
		play_sfx("cables", 1, 0, 0.8)
		if world.secret_boss_beaten:
			$RedSprite.visible = true
			$RedSprite.position = Vector2(57, 176)
			$RedSprite.region_rect = Rect2(192, 48, 16, 16)
			$PlayerSprite.position = Vector2(78, 148)
			$PlayerSprite.region_rect = Rect2(128, 48, 16, 16)
		else:
			$PlayerSprite.position = Vector2(57, 176)
			$PlayerSprite.region_rect = Rect2(256, 32, 16, 16)
		$ShipGlass.visible = false
		$ShipGlassBroken.visible = true
		
		await get_tree().create_timer(1.5, false).timeout #put new glass
		AudioManager.play_audio(sfxs.get_sfx("fix_hatch"))
		$ShipComponents/BottomLeft.region_rect = Rect2(0, 184, 96, 40)
		$ShipComponents/Right.region_rect = Rect2(96, 32, 72, 64)
		$PlayerSprite.position = Vector2(116, 164)
		$PlayerSprite.flip_h = true
		$PlayerSprite.region_rect = Rect2(240, 0, 16, 16)
		$SmokeParticles2.visible = false
		
		await get_tree().create_timer(1.5, false).timeout
		camera.fade("000000", 1, 0.5, 1, 0.5)
		
		await get_tree().create_timer(1.5, false).timeout #ship on planks
		if world.secret_boss_beaten:
			$"ShipComponents/Red&Yellow".visible = true
		$RedSprite.visible = false
		$Green.visible = false
		$ShipGlassBroken.visible = false
		$Tilemap.set_layer_enabled(0, true)
		$Tilemap.set_layer_enabled(4, true)
		$PlayerSprite.visible = false
		$ShipLegs.visible = true
		$ShipComponents.position.y -= 3*8
		$SmokeParticles1.visible = false
		
		await get_tree().create_timer(1.5, false).timeout #ship raised
		tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		await tween.tween_property($ShipComponents, "position:y", -4*8, 0.8).finished
		
		await get_tree().create_timer(2, false).timeout #start thrusters
		AudioManager.play_audio(sfxs.get_sfx("thrusters_on"))
		$ShipComponents/Thrusters.visible = true
		
		await get_tree().create_timer(1, false).timeout #fly away
		AudioManager.play_audio(sfxs.get_sfx("blast_of"), 0.8)
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

func play_sfx(sfx_name: String, count: int, delay: float, start_delay: float = 0):
	if start_delay:
		await get_tree().create_timer(start_delay, false).timeout
	for i in range(count):
		AudioManager.play_audio(sfxs.get_sfx(sfx_name))
		await get_tree().create_timer(delay, false).timeout


func change_to_outro():
	var outro_cutscene = load("res://outro_cutscene.tscn").instantiate()
	outro_cutscene.player_palette = player.current_palette
	outro_cutscene.good_ending = world.secret_boss_beaten
	outro_cutscene.death_count = player.death_count
	outro_cutscene.jump_count = player.jump_count
	outro_cutscene.completion_time = world.get_speedrun_time()
	outro_cutscene.completion_percentage = world.completion_percentage
	get_tree().root.add_child(outro_cutscene)
	get_tree().current_scene = outro_cutscene
	world.queue_free()


func _on_finish_game_area_body_entered(body):
	if body is CharacterBody2D:
		player_in_area = true
		$InputIndicator.visible = true

func _on_finish_game_area_body_exited(body):
	if body is CharacterBody2D:
		player_in_area = false
		$InputIndicator.visible = false
