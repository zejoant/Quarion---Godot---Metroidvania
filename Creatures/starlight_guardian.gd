#@tool
extends Node2D

@export var sfxs : AudioLibrary ## Tagged audio files to play from this scene
@export_enum("Green", "Blue", "Pink", "Yellow") var color = "Green"
@export_range(0, 5) var start_raise : float = 0
@export_range(0, 2) var difficulty : int = 0
@export_range(18, 22) var floor_height : float = 20

var sprite_sheet : Texture2D
var boss : CharacterBody2D
var start_pos : Vector2
var last_pos
var player
var rng = RandomNumberGenerator.new()

var health = 3
var boss_state = -2
var last_attack
var attack_state = 0
var bullet_cooldown = false

var activated = false

var mod : float = 0.01
var time : float = 0
var aim
var idle_origin : Vector2

var tween2
var tween3

var attack_count = 0
var bullet_count = 0

var homing_speed: float = 0.0
var bounce_accel: float

var bullet_scene = preload("res://Objects/bullet.tscn")

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


func _physics_process(_delta):
	if activated:
		if boss_state == -1: #pre attack stuff
			boss_state = 0
			attack_state = 0
			bullet_count = 0
			await get_tree().create_timer(rng.randf_range(3-difficulty*0.7, 4-difficulty), false).timeout
			choose_attack()
			#boss_state = 1
			#boss_state = rng.randi_range(1, 1)
		if mod > 0 and boss_state >= 0: #idle animation
			idle_movement()
		if boss_state == 1: #lunge attack
			lunge()
		if boss_state == 2: #bullet rain
			rain()
		if boss_state == 3: #sweep down
			if abs(sin(time/2.0)) < 0.05:
				fly_by()
		if boss_state == 4: #bullets aimed at the player
			aiming_bullets() 
		if boss_state == 5: #bullets aimed at the player
			bouncing_attack() 


func choose_attack():
	#var num = rng.randi_range(1+int(float(difficulty)/2.0), 3+int(float(difficulty)/2.0))
	var attack = last_attack
	
	if attack_count >= 3: #chance of lunge gets higher each attack
		attack = 1
	else:
		if difficulty > 0: #after first boss it can do aim shots
			while attack == last_attack:
				attack = rng.randi_range(2, 4)
		else:
			while attack == last_attack:
				attack = rng.randi_range(2, 3)
		attack_count += 1
	
	boss_state = attack
	last_attack = boss_state


func rain():
	if attack_state == 0 and boss_state == 2: #wait time, then the attack ends
		get_node("/root/World/Camera").radial_blur(0.03, 0.6, 12)
		AudioManager.play_audio(sfxs.get_sfx("scream"), 1, 0.8)
		attack_state = 1
		await get_tree().create_timer(5, false).timeout
		boss_state = -1
		
	if !bullet_cooldown: #create a rain bullet
		bullet_cooldown = true
		var bullet = bullet_scene.instantiate()
		bullet.setup(2.0, Vector2(rng.randf_range(-0.5, 0.5), 1), Vector2(rng.randi_range(3, 35)*8, 0), true, true, 40)
		call_deferred("add_child", bullet) 
		await get_tree().create_timer(0.2-float(difficulty)*0.04, false).timeout
		bullet_cooldown = false
	


func idle_movement():
	last_pos = boss.position
	boss.position.y = idle_origin.y - sin(time)*12.0
	boss.position.x = idle_origin.x + sin(time/2.0)*50.0
	
	time += 0.08 * mod #progression along the sine wave
	if mod < 1 and (boss_state == 0 or boss_state == 4): #ease in movement
		mod += 0.01


func lunge():
	if attack_state == 0: #back up and aim
		attack_state = 1
		AudioManager.play_audio(sfxs.get_sfx("charge"))
		
		tween3 = self.create_tween()
		tween3.parallel().tween_property(%Aim, "modulate:a", 1, 1)
		
		tween3.parallel().tween_method(Callable(self, "set_shader_value").bind("Boss/BossSprites/Base", "strength"), 0.0, 1.0, 1.8)
		tween3.parallel().tween_method(Callable(self, "set_shader_value").bind("Boss/BossSprites/Spikes", "strength"), 0.0, 1.0, 1.8)
		tween3.parallel().tween_method(Callable(self, "set_shader_value").bind("Boss/BossSprites/Face", "strength"), 0.0, 1.0, 1.8)
		#tween3.parallel().tween_property(boss, "modulate", Color(0.8, 0.3, 0.3, 1), 1.8)
		tween3.parallel().tween_property(self, "mod", 0, 0.5)#-difficulty*0.1)
		
		#await get_tree().create_timer(0.5-difficulty*0.1, false).timeout
		await get_tree().create_timer(0.5, false).timeout
		aim = player.position.direction_to(boss.position)
		tween2 = self.create_tween()
		tween2.set_trans(Tween.TRANS_SINE)
		tween2.set_ease(Tween.EASE_IN_OUT)
		await tween2.tween_property(boss, "position", boss.position + aim*28, 1.3).finished
		
		$Boss/BossSprites/Base.material.set_shader_parameter("strength", 0)
		$Boss/BossSprites/Spikes.material.set_shader_parameter("strength", 0)
		$Boss/BossSprites/Face.material.set_shader_parameter("strength", 0)
		attack_state = 2
		tween2.kill()
		tween3.kill()
	
	if attack_state < 2:
		%Aim.rotation = (player.position - boss.position).angle() - PI/2 #aim line rotation
	
	if attack_state == 2: #switch to lunge
		attack_state = 3
		aim = player.position.direction_to(boss.position)*5
	
	if attack_state == 3: #lunge towards player
		last_pos = boss.position
		boss.position -= aim
		if %Aim/WallRay.is_colliding():
			get_node("/root/World/Camera").shake(3, 0.03, 3)
			AudioManager.play_audio(sfxs.get_sfx("impact"))
			#get_node("/root/World/Camera").invert_color(1, 0.3)
			attack_state = 4
			%Aim.modulate.a = 0
			#boss.modulate = Color(1, 1, 1, 1)
			$GroundHitEffect.position = boss.position
			if difficulty == 0:
				$Boss/AnimationPlayer.play("Sad Ground Hit")
				$Boss/DamageColl.disabled = true
				await get_tree().create_timer(3-difficulty, false).timeout
				if attack_state == 4 and health:
					reset_lunge()
			else:
				$Boss/AnimationPlayer.play("Ground Hit")
				boss_state = 5
				bullet_count = 0
				attack_state = 0

func bouncing_attack():
	if attack_state == 0: #hit ground / bounce
		attack_state = 1
		idle_origin = boss.position
		bullet_count += 1
		
		homing_speed = (boss.position.x - last_pos.x)
		if abs(homing_speed) > 3:
			homing_speed = sign(homing_speed)*3
			
		var target_pos = rng.randi_range(int(boss.position.x) - 19*8, int(boss.position.x) + 19*8)
		if target_pos < 32:
			target_pos = 32
		elif target_pos > 272:
			target_pos = 272
		#bounce_accel = ((rng.randi_range(3, 27)*10+2) - boss.position.x - 60 * homing_speed)/1770
		bounce_accel = (target_pos - boss.position.x - 60 * homing_speed)/1770
		
		tween2 = self.create_tween()
		tween2.set_trans(Tween.TRANS_QUAD)
		tween2.set_ease(Tween.EASE_OUT)
		tween2.parallel().tween_property(boss, "position:y", 32, 0.5)
		tween2.set_ease(Tween.EASE_IN)
		await tween2.tween_property(boss, "position:y", idle_origin.y, 0.5).finished
		attack_state = 0
		get_node("/root/World/Camera").shake(3, 0.03, 3)
		AudioManager.play_audio(sfxs.get_sfx("impact"))
		$GroundHitEffect.position = boss.position
		if (difficulty == 2 and bullet_count == 3) or (difficulty == 1 and bullet_count == 1):
			attack_state = 4
			$Boss/AnimationPlayer.play("Sad Ground Hit")
			$Boss/DamageColl.disabled = true
			await get_tree().create_timer(3-float(difficulty)*0.6, false).timeout
			if attack_state == 4 and health:
				reset_lunge()
		else:
			$Boss/AnimationPlayer.play("Ground Hit")
		
	elif attack_state == 1: #move in x axis
		last_pos = boss.position
		boss.position.x += homing_speed
		homing_speed += bounce_accel

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

func aiming_bullets():
	if attack_state == 0:
		attack_state = 1
		AudioManager.play_audio(sfxs.get_sfx("charge"), 1.29)
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
		var bullet = bullet_scene.instantiate()
		bullet.setup(3.0, aim, boss.position, true, true, 0)
		call_deferred("add_child", bullet)
		if difficulty == 2:
			bullet = bullet_scene.instantiate()
			bullet.setup(3.0, aim.rotated(PI/4), boss.position, true, true, 0)
			call_deferred("add_child", bullet)
			bullet = bullet_scene.instantiate()
			bullet.setup(3.0, aim.rotated(-PI/4), boss.position, true, true, 0)
			call_deferred("add_child", bullet)
		bullet_count += 1
		await get_tree().create_timer(0.5, false).timeout
		tween3.kill()
		bullet_cooldown = false
	
	if bullet_count >= 6:
		boss_state = -1
		tween2 = self.create_tween()
		tween2.set_trans(Tween.TRANS_QUAD)
		tween2.set_ease(Tween.EASE_IN_OUT)
		tween2.parallel().tween_property(self, "idle_origin", start_pos, 0.8)

func fly_by():
	if attack_state == 0:
		attack_state = 1
		mod = 0
		tween3 = self.create_tween()
		tween3.set_ease(Tween.EASE_OUT)
		tween3.set_trans(Tween.TRANS_SINE)
		
		if last_pos.x > boss.position.x:
			tween3.parallel().tween_property(boss, "position:x", 2*8, 1.7)
			tween3.set_ease(Tween.EASE_IN)
			tween3.tween_property(boss, "position:x", 40*8, 1.2)
		else:
			tween3.parallel().tween_property(boss, "position:x", 36*8, 1.7)
			tween3.set_ease(Tween.EASE_IN)
			tween3.tween_property(boss, "position:x", -2*8, 1.2)
		
		tween2 = self.create_tween()
		tween2.set_ease(Tween.EASE_OUT)
		tween2.set_trans(Tween.TRANS_SINE)
		tween2.tween_property(boss, "position:y", boss.position.y - 8*3, 0.75)
		tween2.set_ease(Tween.EASE_IN_OUT)
		if rng.randi_range(0, 1): #low attack
			tween2.tween_property(boss, "position:y", floor_height*8, 1.5)
		else: #high attack
			tween2.tween_property(boss, "position:y", (floor_height-3)*8, 1.4)
		await get_tree().create_timer(3, false).timeout
		boss.position.y = idle_origin.y + 16
		reset_lunge()

func param_setup():
	boss.position.y -= start_raise*8
	start_pos = boss.position
	idle_origin = start_pos
	#start_pos.y -= start_raise*8
	sprite_sheet = load("res://Assets/Sun Boss " + color + ".png")
	#if color == "green":
		#sprite_sheet = load("res://Assets/Sun Boss Green.png")
	#elif color == "blue":
		#sprite_sheet = load("res://Assets/Sun Boss Blue.png")
	#elif color == "pink":
		#sprite_sheet = load("res://Assets/Sun Boss Pink.png")
	#elif color == "yellow":
		#sprite_sheet = load("res://Assets/Sun Boss Yellow.png")
	
	$Boss/BossSprites/Base.texture = sprite_sheet
	$Boss/BossSprites/Spikes.texture = sprite_sheet
	$Boss/BossSprites/Face.texture = sprite_sheet
	#boss.get_node("BossSprites/Base").texture = sprite_sheet
	#boss.get_node("BossSprites/Spikes").texture = sprite_sheet
	#boss.get_node("BossSprites/Face").texture = sprite_sheet
	
	var p = get_node("/root/World/Player")
	if p.has_wallclimb != p.has_blue_blocks and difficulty == 0: #if you have killed one boss already
		difficulty = 1

func _on_body_entered(body):
	$ActivateBossColl.set_deferred("disabled", true)
	AudioManager.play_song(load("res://Music/Hi GI Joe!.wav"))
	
	player = body
	activated = true
	
	$Gate.close()
	$Gate2.close()
	get_node("/root/World/Camera").hide_ui(false)
	
	player.bubble_invincibility_time = 0.5
	await self.create_tween().tween_interval(2).finished
	#get_node("/root/World/Camera").radial_blur(0.03, 0.6, 12)
	boss.get_node("DamageColl").set_deferred("disabled", false)
	AudioManager.play_audio(sfxs.get_sfx("scream"), 1, 0.8)
	get_node("/root/World/Camera").radial_blur(0.03, 0.6, 12)
	boss.visible = true
	boss_state = -1


func _on_hit_area_body_entered(body): #damage boss
	get_node("/root/World/Camera").shake(4, 0.03, 3)
	get_node("/root/World/Camera").invert_color(1, 0.3)
	AudioManager.play_audio(sfxs.get_sfx("impact"))
	
	attack_count = 0
	health -= 1
	if !health:
		die()
	else:
		reset_lunge()
	body.bounce(body.jump_vel)

func die():
	player.bubble_invincibility_time = 0.3
	$Boss/AnimationPlayer.play("Default")
	AudioManager.pause_song()
	get_node("/root/World").save_room_state($ActivateBossColl.position, true)
	AudioManager.play_audio(sfxs.get_sfx("death charge"), 1.44)
	get_node("/root/World/Camera").zoom_camera(1.8, 3)
	tween2 = self.create_tween()
	tween2.set_trans(Tween.TRANS_SINE)
	tween2.set_ease(Tween.EASE_IN_OUT)
	await tween2.tween_property(boss, "position", Vector2(start_pos.x, start_pos.y + start_raise*8), 3).finished
	$Gate.open()
	$Gate2.open()
	#boss.visible = false
	get_node("/root/World/Camera").zoom_camera(1, 0)
	AudioManager.play_audio(sfxs.get_sfx("death"))
	$Boss/BossSprites/Base.modulate.a = 0
	$Boss/BossSprites/Spikes.modulate.a = 0
	$Boss/BossSprites/Face.modulate.a = 0
	$Boss/SilhouetteParticles.visible = false
	$Boss/DeathParticles.emitting = true
	$Boss/DeathParticles2.emitting = true
	get_node("/root/World/Camera").shake(4, 0.03, 3)
	get_node("/root/World/Camera").invert_color(1, 0.3)
	get_node("/root/World/Camera").hide_ui(true)
	AudioManager.resume_previous_song()

func set_shader_value(value: float, path: String, param: String):
	get_node(path).material.set_shader_parameter(param, value)
