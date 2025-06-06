#@tool
extends Node2D

@export var sfxs : AudioLibrary ## Tagged audio files to play from this scene
@export_enum("green", "blue", "pink", "yellow") var color = "green"
@export_range(0, 5) var start_raise : float = 0
@export_range(0, 2) var difficulty : int = 0

var sprite_sheet : Texture2D
var boss : CharacterBody2D
var start_pos : Vector2
var player
var rng = RandomNumberGenerator.new()

var health = 3
var boss_state = -2
var attack_state = 0
var bullet_cooldown = false

var activated = false

var mod : float = 0.01
var time : float = 0
var aim
var idle_origin : Vector2

var tween2
var tween3

var chance = 1
var bullet_count = 0

func _ready():
	var room_states = get_node("/root/World").get_room_state()
	for pos in room_states:
		if Vector2i($ActivateBossColl.position) == Vector2i(pos): #check if boss has been defeated
			queue_free()
	
	
	boss = $Boss
	boss.visible = false
	%Aim.modulate.a = 0
	$Boss/DamageColl.disabled = true
	param_setup()


func _process(_delta):
	if activated:
		if boss_state == -1: #pre attack stuff
			boss_state = 0
			attack_state = 0
			bullet_count = 0
			await get_tree().create_timer(rng.randi_range(3, 4)).timeout
			choose_attack()
			#boss_state = rng.randi_range(1, 1)
		if mod > 0 and boss_state >= 0: #idle animation
			idle_movement()
		if boss_state == 1: #lunge attack
			lunge()
		if boss_state == 2: #bullet rain
			rain()
		if boss_state == 3:
			aiming_bullets() #bullets aimed at the player


func choose_attack():
	var num = rng.randi_range(0, 3)
	
	if chance == -1:
		chance = 3
	elif chance == 4:
		chance = 0
	
	if num <= chance:
		boss_state = 1
		chance -= 1
	else:
		boss_state = rng.randi_range(2, 3)
		chance += 1


func rain():
	if attack_state == 0 and boss_state == 2: #wait time, then the attack ends
		#get_node("/root/World/Camera").radial_blur()
		attack_state = 1
		await get_tree().create_timer(5).timeout
		boss_state = -1
		
	if !bullet_cooldown: #create a rain bullet
		bullet_cooldown = true
		var bullet = load("res://Objects/bullet.tscn").instantiate()
		bullet.setup(2.0, Vector2(rng.randf_range(-0.5, 0.5), 1), Vector2(rng.randi_range(3, 35)*8, 0))
		call_deferred("add_child", bullet) 
		await get_tree().create_timer(0.2).timeout
		bullet_cooldown = false
	


func idle_movement():
	boss.position.y = idle_origin.y - sin(time)*12.0
	boss.position.x = idle_origin.x + sin(time/2.0)*50.0
	
	time += 0.08 * mod #progression along the sine wave
	if mod < 1 and boss_state == 0: #ease in movement
		mod += 0.01


func lunge():
	if attack_state == 0: #back up and aim
		attack_state = 1
		
		tween3 = self.create_tween()
		tween3.parallel().tween_property(%Aim, "modulate:a", 1, 1)
		tween3.parallel().tween_property(boss, "modulate", Color(0.8, 0.3, 0.3, 1), 1.8)
		tween3.parallel().tween_property(self, "mod", 0, 0.5)
		
		await get_tree().create_timer(0.5).timeout
		aim = player.position.direction_to(boss.position)
		tween2 = self.create_tween()
		tween2.set_trans(Tween.TRANS_SINE)
		tween2.set_ease(Tween.EASE_IN_OUT)
		await tween2.tween_property(boss, "position", boss.position + aim*28, 1.3).finished
		
		attack_state = 2
		tween2.kill()
		tween3.kill()
	
	if attack_state < 2:
		%Aim.rotation = (player.position - boss.position).angle() - PI/2 #aim line rotation
	
	if attack_state == 2: #switch to lunge
		attack_state = 3
		aim = player.position.direction_to(boss.position)*5
	
	if attack_state == 3: #lunge towards player
		boss.position -= aim
		if %Aim/WallRay.is_colliding():
			get_node("/root/World/Camera").shake(3, 0.03, 3)
			AudioManager.play_audio(sfxs.get_sfx("impact"))
			#get_node("/root/World/Camera").invert_color(1, 0.3)
			attack_state = 4
			%Aim.modulate.a = 0
			$Boss/AnimationPlayer.play("Sad")
			boss.modulate = Color(1, 1, 1, 1)
			$Boss/DamageColl.disabled = true
			await get_tree().create_timer(3).timeout
			if attack_state == 4 and health:
				reset_lunge()


func aiming_bullets():
	if attack_state == 0:
		attack_state = 1
		tween3 = self.create_tween()
		tween3.parallel().tween_property(%Aim, "modulate:a", 1, 1)
		tween3.parallel().tween_property(self, "idle_origin:y", idle_origin.y - 24, 1.4)
		await tween3.parallel().tween_property(boss, "modulate", Color(0.8, 0.3, 0.3, 1), 1.4).finished
		attack_state = 2
		boss.modulate = Color(1, 1, 1, 1)
		tween3.kill()
	
	if attack_state < 3:
		%Aim.rotation = (player.position - boss.position).angle() - PI/2 #aim line rotation
	
	if attack_state == 2 and !bullet_cooldown:
		bullet_cooldown = true
		%Aim.modulate.a = 1
		tween3 = self.create_tween()
		tween3.parallel().tween_property(%Aim, "modulate:a", 0, 0.4)
		aim = boss.position.direction_to(player.position)
		
		AudioManager.play_audio(sfxs.get_sfx("shot"))
		get_node("/root/World/Camera").flash(0.3, 0, 0, 0.2)
		var bullet = load("res://Objects/bullet.tscn").instantiate()
		bullet.setup(3.0, aim, boss.position)
		call_deferred("add_child", bullet)
		bullet_count += 1
		await get_tree().create_timer(0.5).timeout
		tween3.kill()
		bullet_cooldown = false
	
	if bullet_count >= 6:
		boss_state = -1
		tween2 = self.create_tween()
		tween2.set_trans(Tween.TRANS_QUAD)
		tween2.set_ease(Tween.EASE_IN_OUT)
		tween2.parallel().tween_property(self, "idle_origin", start_pos, 0.8)


func param_setup():
	boss.position.y -= start_raise*8
	start_pos = boss.position
	idle_origin = start_pos
	#start_pos.y -= start_raise*8
	
	if color == "green":
		sprite_sheet = load("res://Assets/Sun Boss Green.png")
	elif color == "blue":
		sprite_sheet = load("res://Assets/Sun Boss Blue.png")
	elif color == "pink":
		sprite_sheet = load("res://Assets/Sun Boss Pink.png")
	elif color == "yellow":
		sprite_sheet = load("res://Assets/Sun Boss Yellow.png")
	
	boss.get_node("Base").texture = sprite_sheet
	boss.get_node("Spikes").texture = sprite_sheet
	boss.get_node("Face").texture = sprite_sheet


func _on_body_entered(body):
	$ActivateBossColl.set_deferred("disabled", true)
	boss.get_node("DamageColl").set_deferred("disabled", false)
	get_node("/root/World").switch_music("res://Music/Hi GI Joe!.wav")
	#get_node("/root/World/MusicPlayer").stream = load("res://Music/Hi GI Joe!.wav")
	#get_node("/root/World/MusicPlayer").play()
	
	player = body
	activated = true
	
	$Gate.close()
	$Gate2.close()
	
	await self.create_tween().tween_interval(2).finished
	get_node("/root/World/Camera").radial_blur(0.03, 0.6, 12)
	boss.visible = true
	boss_state = -1


func _on_hit_area_body_entered(body): #damage boss
	get_node("/root/World/Camera").shake(4, 0.03, 3)
	get_node("/root/World/Camera").invert_color(1, 0.3)
	AudioManager.play_audio(sfxs.get_sfx("impact"))
	
	health -= 1
	if !health:
		die()
	else:
		reset_lunge()
	body.bounce(body.jump_vel)

func die():
	$Boss/AnimationPlayer.play("Default")
	get_node("/root/World/MusicPlayer").stop()
	get_node("/root/World").save_room_state($ActivateBossColl.position)
	tween2 = self.create_tween()
	tween2.set_trans(Tween.TRANS_SINE)
	tween2.set_ease(Tween.EASE_IN_OUT)
	await tween2.tween_property(boss, "position", Vector2(start_pos.x, start_pos.y + start_raise*8), 3).finished
	$Gate.open()
	$Gate2.open()
	#boss.visible = false
	AudioManager.play_audio(sfxs.get_sfx("death"))
	$Boss/Base.modulate.a = 0
	$Boss/Spikes.modulate.a = 0
	$Boss/Face.modulate.a = 0
	$Boss/SilhouetteParticles.visible = false
	$Boss/DeathParticles.emitting = true
	$Boss/DeathParticles2.emitting = true
	get_node("/root/World/Camera").shake(4, 0.03, 3)
	get_node("/root/World/Camera").invert_color(1, 0.3)
	get_node("/root/World").resume_previous_music()

func reset_lunge(): #reset back to idle
	$Boss/AnimationPlayer.play("Default")
	idle_origin = boss.position
	time = 0
	boss_state = -1
	mod = 0.01
	tween2 = self.create_tween()
	tween2.set_trans(Tween.TRANS_QUAD)
	tween2.set_ease(Tween.EASE_IN_OUT)
	await tween2.tween_property(self, "idle_origin", start_pos, 0.8).finished
	$Boss/DamageColl.disabled = false
