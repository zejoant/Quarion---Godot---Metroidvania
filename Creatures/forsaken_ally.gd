extends Area2D
class_name ForsakenAlly

var player
var camera
var world
@onready var boss = $ForsakenAlly
@export var sfxs : AudioLibrary
var rng = RandomNumberGenerator.new()
var health = 9

enum HitMode {DAMAGE, DODGE, NONE}
var hit_mode = HitMode.DODGE

enum BossState {IDLE, RESET, SPIKE, JUMP, DIVE, SHOT}
var boss_state: BossState = BossState.IDLE
var attack_state: int = 0
var attack_sub_state: int = 0
var attack_cooldown: int = 0

var done_attacks: Array[BossState] = [BossState.JUMP, BossState.DIVE, BossState.SHOT, BossState.DIVE, BossState.JUMP]
var attack_count: int = 0
var last_attack: BossState = BossState.IDLE

var aim
var chance = 1

var dodging = false
var spike_wave_origin: Vector2

var tween1
var tween2

@onready var origin = $ForsakenAlly.position

var follow_pos
#var follow_velocity
var aim_pos

var time: float = 0
var last_pos: Vector2

var dead = false
static var has_seen_intro = false
var during_intro: bool = false

var floor_spike = preload("res://Objects/big_floor_spike.tscn")
var flying_orb = preload("res://Objects/flying_orb.tscn")
var big_flying_orb = preload("res://Objects/big_flying_orb.tscn")
var warning_particle = preload("res://Particles/warning_particle.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	print(health)
	player = get_node("/root/World/Player")
	camera = get_node("/root/World/Camera")
	world = get_node("/root/World")
	camera.hide_ui(false)
	follow_pos = player.position
	if world.red_boss_beaten == true:
		if !world.secret_boss_beaten:
			boss.position.x = 152-16
			$ForsakenAlly/BossSprite.scale.x = -1
			$ForsakenAlly/BossAnimPlayer.play("Lie Down")
		else:
			boss.visible = false
			$Gate2.close(true)
			#$ActivationColl.disabled = true
		dead = true
		$DiveImpactComp.visible = false
		$ForsakenAlly/TrailParticle.emitting = false
		$ForsakenAlly/HurtColl.set_deferred("disabled", true)
		$ForsakenAlly/HitArea/HitColl.set_deferred("disabled", true)
		$Gate2.close(true)
	else:
		$ForsakenAlly/BossAnimPlayer.play("Idle")
		player.bubble_invincibility_time = 0.5
		intro_sequence()

func _physics_process(delta):
	if during_intro:
		time -= 1.4
		$HermitFleeSprite.position = Vector2(boss.position.x + time, boss.position.y - 20.0*sin(time/20.0)-time/2.0)
		return
	if !dead:
		update_aim(delta)
		if $ForsakenAlly/GroundRay.is_colliding() and $ForsakenAlly/BossAnimPlayer.assigned_animation != "Lie Down":
			if boss.position.x != player.position.x:
				$ForsakenAlly/BossSprite.scale.x = sign(boss.position.x - player.position.x)
		
		if player.position.x > boss.position.x-8 and player.position.x < boss.position.x+8 and player.position.y < boss.position.y-6 and hit_mode != HitMode.NONE:
			$ForsakenAlly/HurtColl.disabled = true
		elif hit_mode == HitMode.DODGE and !dodging:
			$ForsakenAlly/HurtColl.disabled = false
		if boss_state == BossState.RESET: #pre attack stuff
			attack_state = 0
			attack_sub_state = 0
			attack_cooldown = 0
			attack_count += 1
			boss_state = BossState.IDLE
			if tween1:
				tween1.kill()
			tween1 = self.create_tween()
			await tween1.tween_interval(0.5).finished
			if boss_state == BossState.IDLE:
				choose_attack()
		elif boss_state == BossState.JUMP:
			jump_attack()
		elif boss_state == BossState.SPIKE:
			attack_count = 0
			floor_spikes()
		elif boss_state == BossState.DIVE:
			dive_attack()
		elif boss_state == BossState.SHOT:
			aim_shot_attack()
		
		time += 1
		$ForsakenAlly/BossSprite.material.set_shader_parameter("strength", sin(time/40.0)/(4.0-float(health)/3.0))
		
		if last_pos != boss.position:
			$ForsakenAlly/TrailParticle.emitting = true
		else:
			$ForsakenAlly/TrailParticle.emitting = false
		
		last_pos = boss.position
		
		if health == 1 and !dodging:
			if player.position.y > 150:
				$ForsakenAlly/HitArea/HitColl.disabled = true
				$ForsakenAlly/HurtColl.disabled = false
			else:
				$ForsakenAlly/HitArea/HitColl.disabled = false
				$ForsakenAlly/HurtColl.disabled = true
	else:
		time += 1
		$HermitFleeSprite.position = Vector2(144.0 + float(time), 144.0 - 4.0*sin(float(time)/20.0)*sqrt(float(time)/3.0) - float(time))
	
func floor_spikes():
	if attack_state == 0: #attack setup
		if health <= 6 and rng.randi_range(0, 1) == 0:
			attack_state = -1
		else:
			attack_state = 1
		dodge_player(0.3, false, false)
		$ForsakenAlly/BossAnimPlayer.play("Kneel")
		toggle_hit_coll(HitMode.DAMAGE)
	
	if attack_state == 1: #randomize full floor spikes or 3x single spikes
		if !attack_cooldown:
			attack_sub_state = 0
			attack_state = rng.randi_range(2, 3)
		else:
			attack_cooldown -= 1
	
	if attack_state == 2: #3x single spikes
		if !attack_cooldown: #add spikes
			if health <= 3:
				attack_cooldown = 40
			else:
				attack_cooldown = 70
			attack_sub_state += 1
			var spike1 = floor_spike.instantiate()
			spike1.position = Vector2(aim_pos.x, 20*8)
			if health <= 3:
				spike1.spike_amount = 3
				spike1.speed = 1.5
			#spike1.spike_amount = ceil(float(10-health)/3.0)
			add_child(spike1)
		else: #await next spike
			attack_cooldown -= 1
		if attack_sub_state == 3: #finish sub_attack after 3 single spikes
			attack_state = 1
			if health <= 3:
				attack_cooldown = 140
			else:
				attack_cooldown = 180
		
	elif attack_state == 3: # full floor spikes
		for i in range(0, 10):
			var s = floor_spike.instantiate()
			s.position = Vector2(24 + (256.0/9.0) * i, 20*8)
			s.spike_amount = 1
			if i > 0:
				s.sound = false
			if health <= 3:
				s.speed = 1.5
			add_child(s)
		attack_state = 1
		if health <= 3:
			attack_cooldown = 140
		else:
			attack_cooldown = 180
	
	if attack_state == 4: #spike wave
		if attack_cooldown == 0: #add spikes
			attack_cooldown = 20
			attack_sub_state += int(spike_wave_origin.y)
			var spike1 = floor_spike.instantiate()
			spike1.position = Vector2(spike_wave_origin.x + attack_sub_state*16, 20*8)
			spike1.spike_amount = 1
			spike1.speed = 2
			add_child(spike1)
			if spike1.position.x < 3*8 or spike1.position.x > 35*8:
				attack_cooldown = -1
			elif (sign(attack_sub_state) > 0 and player.position.x <= spike1.position.x) or (sign(attack_sub_state) < 0 and player.position.x >= spike1.position.x):
				var spike2 = floor_spike.instantiate()
				spike2.position = Vector2(spike_wave_origin.x + sign(attack_sub_state)*32, 20*8)
				spike2.speed = 2
				add_child(spike2)
				attack_state = 1
				attack_cooldown = 70
				attack_sub_state = 0
			
		else: #await next spike
			attack_cooldown -= 1
		if attack_cooldown == -21: #finish after reaching end of arena
			attack_state = 1
			attack_cooldown = 180

func jump_attack():
	if !attack_cooldown:
		attack_cooldown = 1
		AudioManager.play_audio(sfxs.get_sfx("jump"))
		$ForsakenAlly/GroundRay.enabled = false
		$ForsakenAlly/BossAnimPlayer.play("Jump")
		tween1 = self.create_tween()
		set_tween(tween1, Tween.TRANS_SINE, Tween.EASE_OUT)
		tween1.tween_property(boss, "position:x", aim_pos.x, 1)
		
		tween2 = self.create_tween()
		set_tween(tween2, Tween.TRANS_QUAD, Tween.EASE_OUT)
		tween2.tween_property(boss, "position:y", origin.y-8*10, 0.5)
		tween2.set_ease(Tween.EASE_IN)
		tween2.tween_property(boss, "position:y", origin.y, 0.5)
		
	if boss.position.y < origin.y - 8*9.5 and attack_cooldown == 1: #fall
		$ForsakenAlly/BossAnimPlayer.play("Fall")
		$ForsakenAlly/GroundRay.enabled = true
		attack_cooldown = 2
	
	if $ForsakenAlly/GroundRay.is_colliding(): #land
		if attack_cooldown == 2:
			$ForsakenAlly/BossAnimPlayer.play("Land")
		attack_cooldown += 1
	
	if attack_cooldown == 40: #await next jump
		attack_state += 1
		attack_cooldown = 0
	
	if attack_state == 3: #finish attack
		boss_state = BossState.RESET


func dive_attack():
	if attack_state == 0: #jump through ground
		attack_state = -1
		$ForsakenAlly/HitArea/HitColl.set_deferred("disabled", true)
		$ForsakenAlly/HurtColl.set_deferred("disabled", true)
		$ForsakenAlly/BossAnimPlayer.play("Jump")
		AudioManager.play_audio(sfxs.get_sfx("jump"))
		
		tween1 = self.create_tween()
		set_tween(tween1, Tween.TRANS_QUAD, Tween.EASE_OUT)
		tween1.tween_property(boss, "position:y", origin.y - 4, 0.2)
		tween1.set_ease(Tween.EASE_IN)
		await tween1.tween_property(boss, "position:y", 30*8, 0.6).finished
		tween1.kill()
		$ForsakenAlly/HurtColl.set_deferred("disabled", false)
		attack_state = 1
	
	elif attack_state < 5:
		if $ForsakenAlly/BossAnimPlayer.assigned_animation == "Jump" and boss.position.y == origin.y-4:
			$ForsakenAlly/BossAnimPlayer.play("Fall")
		
		if attack_state > 0:
			if boss.position.y >= 30*8: #dive
				$ForsakenAlly/BossSprite.visible = true
				$ForsakenAlly/GroundRay.enabled = true
				$ForsakenAlly/BossAnimPlayer.play("Dive")
				boss.position.y = -8
				boss.position.x = aim_pos.x
				
				$WarningParticle.global_position = Vector2(aim_pos.x, 20*8)
				$WarningParticle.emitting = true
				
				if health <= 3:
					$WarningParticle.position.x = 152
					$WarningParticle.scale_curve_x.set_point_value(0, 38)
					$ForsakenAlly/DiveHurtCull.scale.x = 5
					$DiveImpactComp/DiveImpactParticles.emission_rect_extents.x = 304
				elif attack_state == 1:
					$WarningParticle.scale_curve_x.set_point_value(0, 9)
					$ForsakenAlly/DiveHurtCull.scale.x = 3.0/4.0
					$DiveImpactComp/DiveImpactParticles.emission_rect_extents.x = 36
				elif attack_state == 2:
					$WarningParticle.scale_curve_x.set_point_value(0, 12)
					$ForsakenAlly/DiveHurtCull.scale.x = 1
					$DiveImpactComp/DiveImpactParticles.emission_rect_extents.x = 48
				elif attack_state == 3:
					$WarningParticle.scale_curve_x.set_point_value(0, 18)
					$ForsakenAlly/DiveHurtCull.scale.x = 3.0/2.0
					$DiveImpactComp/DiveImpactParticles.emission_rect_extents.x = 96
			
			if $ForsakenAlly/GroundRay.is_colliding() and boss.position.y > 12*8: #hit ground
				AudioManager.play_audio(sfxs.get_sfx("dash"), 1, 1.2)
				#camera.radial_blur()
				camera.shake(5, 0.03, 3)
				camera.invert_color(0.7, 0.3)
				
				$DiveImpactComp.position = Vector2(boss.position.x, 18.5*8)
				$DiveImpactComp/DiveImpactParticles.restart()
				$EnvAnimPlayer.play("Dive Impact")
				$ForsakenAlly/BossSprite.visible = false
				$ForsakenAlly/GroundRay.enabled = false
				attack_state += 1
				
				if attack_state == 4 or health <= 3:
					create_orb(Vector2(boss.position.x, boss.position.y+16), Vector2(1.5, 0), Vector2(-0.05, -0.05), true, false)
					create_orb(Vector2(boss.position.x+8, boss.position.y+16), Vector2(2.5, 0), Vector2(-0.05, -0.05), true, false)
					create_orb(Vector2(boss.position.x, boss.position.y+16), Vector2(-1.5, 0), Vector2(0.05, -0.05), true, false)
					create_orb(Vector2(boss.position.x-8, boss.position.y+16), Vector2(-2.5, 0), Vector2(0.05, -0.05), true, false)
				
				$ForsakenAlly/DiveHurtCull.disabled = false #damage player on/off
				#await get_tree().create_timer(0.1).timeout
				await create_tween().tween_interval(0.1).finished
				$ForsakenAlly/DiveHurtCull.disabled = true
				
				
			if attack_state == 4: #finish attack/land
				#create_orb(Vector2(boss.position.x, boss.position.y+16), Vector2(1.5, 0), Vector2(-0.05, -0.05), true, false)
				#create_orb(Vector2(boss.position.x+8, boss.position.y+16), Vector2(2.5, 0), Vector2(-0.05, -0.05), true, false)
				#create_orb(Vector2(boss.position.x, boss.position.y+16), Vector2(-1.5, 0), Vector2(0.05, -0.05), true, false)
				#create_orb(Vector2(boss.position.x-8, boss.position.y+16), Vector2(-2.5, 0), Vector2(0.05, -0.05), true, false)
				attack_state = 5
				$ForsakenAlly/BossAnimPlayer.play("Land")
				$ForsakenAlly/BossSprite.visible = true
				boss.position.y = 18.5*8
				$ForsakenAlly/HitArea/HitColl.disabled = false
				toggle_hit_coll(HitMode.DODGE)
			else:
				boss.position.y += 4
	elif attack_state == 5:
		attack_cooldown += 1
		if attack_cooldown == 30:
			boss_state = BossState.RESET

func aim_shot_attack():
	if attack_state == 0:
		$ForsakenAlly/BossAnimPlayer.play("Charge Shot")
		attack_state = 1
		attack_cooldown = 70
	elif attack_state == 1:
		if attack_cooldown == 70:
			attack_cooldown = 0
			attack_sub_state += 1
			self.create_tween().tween_property($ForsakenAlly/Aim/AimSprite, "modulate:a", 1, 0.2)
			$ForsakenAlly/HitArea/HitColl.set_deferred("disabled", true)
			var big_orb = big_flying_orb.instantiate()
			big_orb.position = %Aim.global_position#Vector2(boss.position.x, boss.position.y-16)
			if health < 4 or (health < 7 and attack_sub_state == 3):
				big_orb.homing = true
				big_orb.max_speed = 3
				big_orb.acceleration = 0.1
				big_orb.speed = Vector2(sign(player.position.x - boss.position.x) * 3, 0)
			else:
				big_orb.target_player = true
				big_orb.speed = Vector2(3, 0)#4+3.0-health/3.0, 0)#Vector2(3+3.0-health/3.0, 0)
			add_child(big_orb)
		else:
			attack_cooldown += 1
			
		if attack_cooldown == 10:
			$EnvAnimPlayer.play("Aim Line Blink")
		elif attack_cooldown == 30:
			$EnvAnimPlayer.play("Aim Line Flash")
			$ForsakenAlly/HitArea/HitColl.set_deferred("disabled", false)
		if attack_cooldown <= 30:
			%Aim.rotation = %Aim.global_position.angle_to_point(player.position)
		
		if attack_sub_state == 3: #end after 3 shots
			attack_state = 2
			attack_cooldown = 70
	
	if attack_state == 2: #delay at end
		if attack_cooldown >= 40:
			%Aim.rotation = %Aim.global_position.angle_to_point(player.position)
		if attack_cooldown == 60:
			$EnvAnimPlayer.play("Aim Line Blink")
		elif attack_cooldown == 40:
			$EnvAnimPlayer.play("Aim Line Flash")
			$ForsakenAlly/HitArea/HitColl.set_deferred("disabled", false)
		if attack_cooldown == 0:
			boss_state = BossState.RESET
		else:
			attack_cooldown -= 1

func dodge_player(dodge_speed: float, center: bool, reset_attack: bool):
	dodging = true
	$ForsakenAlly/HitArea/HitColl.set_deferred("disabled", true)
	$ForsakenAlly/HurtColl.set_deferred("disabled", true)
	AudioManager.play_audio(sfxs.get_sfx("dodge"), 1, 1.1)
	if reset_attack:
		boss_state = BossState.IDLE
		$ForsakenAlly/BossAnimPlayer.play("Jump")
	if tween1 != null and tween1.is_valid():
		tween1.kill()
	if tween2 != null and tween2.is_valid():
		tween2.kill()
	
	tween1 = self.create_tween()
	if !center: #if boss should dodge to edges
		if player.position.x < 19*8:
			tween1.tween_property(boss, "position:x", 34*8, dodge_speed)
		else:
			tween1.tween_property(boss, "position:x", 4*8, dodge_speed)
	else: #during floor spike phase, if boss should dodge to center
		tween1.tween_property(boss, "position:x", 38*4, dodge_speed)
	
	if $ForsakenAlly/GroundRay.is_colliding():# and hit_mode != HitMode.DODGE: #if on ground, boss jumps a bit 
		tween2 = self.create_tween()
		set_tween(tween2, Tween.TRANS_QUAD, Tween.EASE_OUT)
		tween2.tween_property(boss, "position:y", origin.y - 8, dodge_speed/2.0)
		tween2.set_ease(Tween.EASE_IN)
		tween2.tween_property(boss, "position:y", origin.y, dodge_speed/2.0)
	else: #if in air, boss does not jump when dodging
		self.create_tween().tween_property(boss, "position:y", origin.y, dodge_speed)
	
	#await get_tree().create_timer(dodge_speed).timeout
	await create_tween().tween_interval(dodge_speed).finished
	$ForsakenAlly/HurtColl.disabled = false
	$ForsakenAlly/HitArea/HitColl.disabled = false
	dodging = false
	$ForsakenAlly/BossSprite.scale.x = sign(boss.position.x - player.position.x)
	
	if boss_state == BossState.SPIKE and attack_state == -1: #start spike wave after dodge
		await Engine.get_main_loop().process_frame
		attack_state = 4
		attack_sub_state = 0
		attack_cooldown = 0
		spike_wave_origin.x = boss.position.x
		spike_wave_origin.y = sign(19*8 - boss.position.x)
	if reset_attack:
		$ForsakenAlly/BossAnimPlayer.play("Idle")
		boss_state = BossState.RESET
		toggle_hit_coll(HitMode.DODGE)


func intermission():
	for child in get_children():
		if child.has_method("retract_spike"):
			child.retract_spike()
			
	boss_state = BossState.IDLE
	$ForsakenAlly/HurtColl.set_deferred("disabled", true)
	$ForsakenAlly/HitArea/HitColl.set_deferred("disabled", true)
	$ForsakenAlly/BossAnimPlayer.play("Lie Down")
	
	#await get_tree().create_timer(3).timeout
	await create_tween().tween_interval(3).finished
	
	dodge_player(0.3, false, true)
	$ForsakenAlly/BossAnimPlayer.play("Idle")


func choose_attack():
	if attack_count >= 6:
		boss_state = BossState.SPIKE
		done_attacks = [BossState.JUMP, BossState.DIVE, BossState.SHOT, BossState.DIVE, BossState.JUMP]
	else:
		var choice = last_attack
		for i in 3:
			choice = done_attacks[rng.randi_range(0, done_attacks.size()-1)]
			if choice != last_attack:
				break
		done_attacks.erase(choice)
		boss_state = choice
		
	last_attack = boss_state


#damage boss
func _on_hit_area_body_entered(body):
	if hit_mode == HitMode.DAMAGE:
		if (health+1)%3 == 0: #boss dodge to center
			dodge_player(0.15, true, false)
		elif (health+2)%3 == 0 and health != 1: # after 3 hits
			intermission()
		elif health != 1: #normal hit
			dodge_player(0.3, false, false)
			if health <= 6 and rng.randi_range(0, 1) == 0:
				attack_state = -1
		body.bounce(body.jump_vel)
		health -= 1
		camera.shake(4, 0.03, 3)
		camera.invert_color(1, 0.3)
		AudioManager.play_audio(sfxs.get_sfx("damage"))
		AudioManager.play_audio(sfxs.get_sfx("jump"))
		
		if health == 3:
			$DiveImpactComp/DiveImpactParticles.emission_rect_extents.x = 38*8
			$DiveImpactComp/DiveImpactParticles.amount = 200
			$DiveImpactComp.position = Vector2(19*8, 18.5*8)
			$DiveImpactComp/DiveImpactParticles.restart()
			$DiveImpactComp/DiveImpactParticles.emitting = true
			$ForsakenAlly/FinalPhaseParticles.emitting = true
			#await get_tree().create_timer(0.5).timeout
			#await create_tween().tween_interval(0.5).finished
		
		if health%3 == 0 and health != 0:
			if get_node("/root/World").secret_boss_beaten:
				$ForsakenAlly/HermitGhost.modulate.a = 1
				$ForsakenAlly/HermitGhost.scale = Vector2(1, 1)
				self.create_tween().tween_property($ForsakenAlly/HermitGhost, "modulate:a", 0, 0.9)
				player.paused = true
				await get_tree().create_timer(0.5, false).timeout
				AudioManager.play_audio(sfxs.get_sfx("hermit_scream"), 1, 1.5)
				self.create_tween().tween_property($ForsakenAlly/HermitGhost, "scale", Vector2(5, 5), 0.3)
				#camera.zoom_camera(1, 0.2)
				player.paused = false
			$DiveImpactComp/DiveImpactParticles.amount = 30
	
	if health == 0:
		die()
	elif hit_mode == HitMode.DODGE:
		dodge_player(0.3, false, true)

func die():
	player.bubble_action(false, true, false)
	#player.bubble_popped = true
	player.disable_movement(true)
	player.visible = false
	player.paused = true
	player.update_animations = false
	#player.can_die = false
	player.velocity = Vector2(0, 0)
	player.position = Vector2(boss.position.x+8, 19*8)
	player.get_node("AnimationPlayer").play("Idle")
	player.get_node("Sprite2D").scale.x = -1
	
	#player.position.x += 16
	$ForsakenAlly/BossSprite.material.set_shader_parameter("strength", 0)
	$ColorRect.modulate.a = 1
	$ForsakenAlly/BossSprite.scale.x = 1
	dead = true
	#player.after_red_boss = true
	get_node("/root/World").red_boss_beaten = true
	for child in get_children():
		if child.has_method("retract_spike"):
			child.retract_spike()
	$ForsakenAlly/FinalPhaseParticles.emitting = false
	$ForsakenAlly/HurtColl.set_deferred("disabled", true)
	$ForsakenAlly/HitArea/HitColl.set_deferred("disabled", true)
	AudioManager.stop_song()
	
	if !get_node("/root/World").secret_boss_beaten:
		$ForsakenAlly/BossAnimPlayer.play("Slow-Mo Fall")
		self.create_tween().tween_property(boss, "position:x", boss.position.x-16, 1.8)
		
		var t = self.create_tween()
		set_tween(t, Tween.TRANS_QUART, Tween.EASE_OUT)
		t.tween_property(boss, "position:y", boss.position.y-8, 0.9)
		set_tween(t, Tween.TRANS_QUART, Tween.EASE_IN)
		await t.tween_property(boss, "position:y", boss.position.y, 0.9).finished
		
		#$ForsakenAlly/BossAnimPlayer.play("Lie Down")
		await get_tree().create_timer(2, false).timeout
	
		$ForsakenAlly/BossAnimPlayer.play("Reach Out")
		await get_tree().create_timer(4, false).timeout
		
		player.visible = true
		player.paused = false
		await self.create_tween().tween_property($ColorRect, "modulate:a", 0, 0.3).finished
	else:
		$ForsakenAlly/BossAnimPlayer.play("Slow-Mo Fall + Release Hermit")
		tween_prop(tween1, Tween.TRANS_QUART, Tween.EASE_OUT, boss, "position:y", boss.position.y-8, 1.4)
		await self.create_tween().tween_property(boss, "position:x", boss.position.x-(22.4/3.0), 1.4).finished
		await get_tree().create_timer(0.7, false).timeout
		
		camera.shake(4, 0.03, 3)
		camera.invert_color(1, 0.3)
		
		$HermitFleeSprite.position = boss.position
		$HermitFleeSprite.modulate.a = 0.6
		time = 0
		tween_prop(tween1, Tween.TRANS_QUART, Tween.EASE_IN, boss, "position:y", boss.position.y+8, 0.7)
		await self.create_tween().tween_property(boss, "position:x", boss.position.x-(25.6/3.0), 0.9).finished
		await get_tree().create_timer(5, false).timeout
		
		player.visible = true
		player.paused = false
		await self.create_tween().tween_property($ColorRect, "modulate:a", 0, 0.3).finished
		await get_tree().create_timer(1, false).timeout
		player.update_animations = true
		player.velocity.x = -player.x_speed/4.0
		await get_tree().create_timer(0.5, false).timeout
		player.velocity.x = 0 
		await get_tree().create_timer(0.5, false).timeout
		player.position.x = boss.position.x + 10
		player.update_animations = false
		player.get_node("AnimationPlayer").play("Hand On Shoulder")
		await get_tree().create_timer(2.2, false).timeout
		player.get_node("AnimationPlayer").play("Idle")
		await get_tree().create_timer(1.3, false).timeout
		self.create_tween().tween_property(player, "position:x", player.position.x - 2, 0.2)
		await self.create_tween().tween_property(boss, "position:x", boss.position.x + 2, 0.2).finished
		$ForsakenAlly/BossSprite.material.set_shader_parameter("palette_choice", player.current_palette)
		player.visible = false # hug
		await get_tree().create_timer(3, false).timeout
		boss.visible = false
		player.visible = true
		camera.hide_ui(true)
		$Gate2.open()
		get_node("/root/World").add_red_as_companion()
	
	AudioManager.resume_previous_song()
	AudioManager.stop_song()
	
	player.update_animations = true
	player.disable_movement(false)
	$Gate.open()


func toggle_hit_coll(mode: HitMode):
	if mode == HitMode.DODGE:
		$ForsakenAlly/HitArea.position.y = -10
		$ForsakenAlly/HitArea.scale.y = 2
	elif mode == HitMode.DAMAGE:
		$ForsakenAlly/HitArea.position.y = 0
		$ForsakenAlly/HitArea.scale.y = 1
		
	hit_mode = mode


#calculates aim for various attacks. Tries to predict future player pos
func update_aim(delta):
	if player.velocity.x == 0:
		follow_pos.x = player.position.x
	if player.velocity.y == 0:
		follow_pos.y = player.position.y
	elif player.velocity.y != 0 and player.velocity.x != 0:
		follow_pos = follow_pos.cubic_interpolate(player.position, player.velocity, player.velocity, delta * 0.6)
	aim_pos = 2 * player.position - follow_pos #converts position from behind the player to in front
	
	if aim_pos.x <= 24:
		aim_pos.x = 24
	elif aim_pos.x >= 35*8:
		aim_pos.x = 35*8
	
	if aim_pos.y <= 0:
		aim_pos.y = 0
	elif aim_pos.y >= 19*8:
		aim_pos.y = 19*8


func intro_sequence():
	AudioManager.pause_song()
	$ForsakenAlly/BossSprite.material.set_shader_parameter("replace_color", Color(0x211a29ff))
	if !has_seen_intro:
		has_seen_intro = true
	
		player.bubble_popped = true
		tween_prop(tween1, Tween.TRANS_QUART, Tween.EASE_OUT, player.get_node("BubbleSprite"), "modulate:a", 0, 1)
		#player.get_node("BubbleSprite").modulate.a
		player.disable_movement(true)
		player.can_die = false
		if world.secret_boss_beaten:
			$ForsakenAlly/TrailParticle.emitting = false
			$ForsakenAlly/BossAnimPlayer.play("Kneel")
			camera.fade("000000", 1, 0, 0.2, 0.5)
			during_intro = true
			time = 300
			$HermitFleeSprite.modulate.a = 0.6
			$HermitFleeSprite.flip_h = true
			player.velocity.x = 0 
			player.visible = false
			await get_tree().create_timer(3.57, false).timeout
			camera.shake(4, 0.03, 3)
			camera.invert_color(1, 0.3)
			AudioManager.play_audio(sfxs.get_sfx("dash"), 1, 1.2)
			$EnvAnimPlayer.play("HermitEnter")
			$HermitFleeSprite.modulate.a = 0
			$HermitFleeSprite.flip_h = false
			during_intro = false
			await get_tree().create_timer(2, false).timeout
			$ForsakenAlly/BossAnimPlayer.play("Idle")
			player.visible = true
		player.position.x = 303#35*8
		player.velocity.x = -player.x_speed
		await get_tree().create_timer(1.25, false).timeout
		player.velocity.x = 0 
		
		$ForsakenAlly/BossAnimPlayer.play("Charge Shot")
		var big_orb = big_flying_orb.instantiate()
		big_orb.position = Vector2(boss.position.x, boss.position.y-16)
		big_orb.target_player = true
		big_orb.speed = Vector2(1, 0)*3#shot_speed*3
		add_child(big_orb)
		
		%Aim.rotation = -PI/2.0
		tween_prop(tween1, Tween.TRANS_QUART, Tween.EASE_OUT, $ForsakenAlly/Aim/AimSprite, "modulate:a", 1, 0.8)
		tween_prop(tween2, Tween.TRANS_QUART, Tween.EASE_OUT, %Aim, "rotation", %Aim.global_position.angle_to_point(player.position), 0.8)
		await get_tree().create_timer(0.55, false).timeout
		$EnvAnimPlayer.play("Aim Line Flash")
		await get_tree().create_timer(0.42, false).timeout
		#await get_tree().create_timer(0.38, false).timeout
		
		AudioManager.play_audio(player.sfxs.get_sfx("death"))
		camera.shake(4, 0.03, 3)
		camera.invert_color(1, 0.3)
		big_orb.queue_free()
		player.update_animations = false
		player.get_node("AnimationPlayer").play("Lie Down")
		tween_prop(tween1, Tween.TRANS_QUART, Tween.EASE_OUT, player, "position:x", player.position.x + 9*8, 1)
		await get_tree().create_timer(1, false).timeout
		
		aim_pos.x = player.position.x - 16
		AudioManager.play_audio(sfxs.get_sfx("jump"))
		$ForsakenAlly/BossAnimPlayer.play("Jump")
		tween_prop(tween1, Tween.TRANS_SINE, Tween.EASE_OUT, boss, "position:x", aim_pos.x, 1)
		tween_prop(tween2, Tween.TRANS_QUAD, Tween.EASE_OUT, boss, "position:y", origin.y-8*10, 0.5)
		await get_tree().create_timer(0.5, false).timeout
		
		tween_prop(tween2, Tween.TRANS_QUAD, Tween.EASE_IN, boss, "position:y", origin.y, 0.5)
		await get_tree().create_timer(0.5, false).timeout
		
		$ForsakenAlly/BossAnimPlayer.play("Land")
		hit_mode = HitMode.DAMAGE
		player.update_animations = true
		player.jump()
		tween_prop(tween1, Tween.TRANS_SINE, Tween.EASE_OUT, player, "position:x", player.position.x-16, 0.5)
		await get_tree().create_timer(1, false).timeout
		
		player.bubble_action(false, false)
		player.disable_movement(false)
		player.can_die = true
		health += 1
		#get_node("/root/World/MusicPlayer").stream_paused = false
		AudioManager.resume_song()
	else:
		player.disable_movement(true)
		player.position.x = 303#35*8
		player.velocity.x = -player.x_speed
		await get_tree().create_timer(0.7, false).timeout
		player.velocity.x = 0 
		player.disable_movement(false)
	
	$Gate.close()
	$Gate2.close()
	toggle_hit_coll(HitMode.DODGE)
	boss_state = BossState.RESET
	#boss_state = BossState.SHOT
	#player.can_die = false
	#boss_state = BossState.SPIKE
	if !world.secret_boss_beaten:
		AudioManager.play_song(load("res://Music/Itzaithr Yuoarmi.ogg"), 6.01)
	else:
		AudioManager.play_song(load("res://Music/Weerboath Maekennettoam.ogg"), 6.01)

func set_tween(tween: Tween, t: int, e: int):
	tween.set_trans(t)
	tween.set_ease(e)

func tween_prop(tween: Tween, t: int, e: int, target, prop: String, val, delay: float):
	tween = self.create_tween()
	set_tween(tween, t, e)
	tween.tween_property(target, prop, val, delay)

func create_orb(orb_pos: Vector2, orb_speed: Vector2, orb_acc: Vector2, friction_x: bool, friction_y: bool):
	var orb = flying_orb.instantiate()
	orb.position = orb_pos
	orb.speed = orb_speed
	orb.acceleration = orb_acc
	orb.friction_x = friction_x
	orb.friction_y = friction_y
	add_child(orb)

func play_sfx(sfx_name: String, volume: float = 1):
	AudioManager.play_audio(sfxs.get_sfx(sfx_name), 1, volume)

#func _on_body_entered(_body):
	#$ActivationColl.set_deferred("disabled", true)
	#intro_sequence()


#func _on_tree_exiting():
	#if world.secret_boss_beaten and player.position.x > 152:
		#AudioManager.resume_previous_song()
