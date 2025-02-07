extends Area2D

var player
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

var attack_count: int = 0
var last_attack: BossState = BossState.IDLE

var aim
var chance = 1

var tween1
var tween2
var timer1: Timer
var timer2: Timer

@onready var origin = $ForsakenAlly.position

var follow_pos
var aim_pos

var floor_spike = preload("res://Objects/big_floor_spike.tscn")
var warning_particle = preload("res://Particles/warning_particle.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_node("/root/World/Player")
	follow_pos = player.position
	#player.disable_movement(true)
	var room_states = get_node("/root/World").get_room_state()
	var free_check = false
	for pos in room_states:
		if Vector2i($ActivationColl.position) == Vector2i(pos): #check if boss has been defeated
			queue_free()
			free_check = true
	
	if !free_check:
		intro_sequence()


func _physics_process(delta):
	update_aim(delta)
	if $ForsakenAlly/GroundRay.is_colliding() and $ForsakenAlly/BossAnimPlayer.assigned_animation != "Lie Down":
		boss.scale.x = sign(boss.position.x - player.position.x)
		
		#if $ForsakenAlly/BossAnimPlayer.current_animation != "Land" and $ForsakenAlly/BossAnimPlayer.current_animation != "Jump":
		#	$ForsakenAlly/BossAnimPlayer.play("Idle")
	
	if player.position.x > boss.position.x-8 and player.position.x < boss.position.x+8 and player.position.y < boss.position.y-6:
		$ForsakenAlly/HurtColl.disabled = true
	elif hit_mode == HitMode.DODGE:
		$ForsakenAlly/HurtColl.disabled = false
	
	if boss_state == BossState.RESET: #pre attack stuff
		attack_state = 0
		attack_sub_state = 0
		attack_cooldown = 0
		attack_count += 1
		boss_state = BossState.IDLE
		await get_tree().create_timer(0.5).timeout
		choose_attack()
	elif boss_state == BossState.JUMP:
		jump_attack()
	elif boss_state == BossState.SPIKE:
		attack_count = 0
		floor_spikes()
	elif boss_state == BossState.DIVE:
		dive_attack()
	
func floor_spikes():
	if attack_state == 0: #attack setup
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
			attack_cooldown = 70
			attack_sub_state += 1
			var spike1 = floor_spike.instantiate()
			spike1.position = Vector2(aim_pos.x, 20*8)
			add_child(spike1)
		else: #await next spike
			attack_cooldown -= 1
		if attack_sub_state == 3: #finish sub_attack after 3 single spikes
			attack_state = 1
			attack_cooldown = 180
		
	elif attack_state == 3: # full floor spikes
		for i in range(0, 10):
			var s = floor_spike.instantiate()
			s.position = Vector2(24 + (256.0/9.0) * i, 20*8)
			s.spike_amount = 1
			if i > 1:
				s.sound = false
			add_child(s)
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
	
	if attack_cooldown == 50: #await next jump
		attack_state += 1
		attack_cooldown = 0
	
	if attack_state == 3: #finish attack
		boss_state = BossState.RESET


func dive_attack():
	if attack_state == 0: #jump through ground
		attack_state = -1
		$ForsakenAlly/HitArea/HitColl.set_deferred("disabled", true)
		$ForsakenAlly/HurtColl.set_deferred("disabled", true)
		#hit_mode = HitMode.DODGE
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
				
				if attack_state == 1:
					$WarningParticle.scale_curve_x.set_point_value(0, 9)
					$ForsakenAlly/DiveHurtCull.scale.x = 3.0/4.0
					$DiveImpactComp/DiveImpactParticles.emission_rect_extents.x = 36
				if attack_state == 2:
					$WarningParticle.scale_curve_x.set_point_value(0, 12)
					$ForsakenAlly/DiveHurtCull.scale.x = 1
					$DiveImpactComp/DiveImpactParticles.emission_rect_extents.x = 48
				if attack_state == 3:
					$WarningParticle.scale_curve_x.set_point_value(0, 18)
					$ForsakenAlly/DiveHurtCull.scale.x = 3.0/2.0
					$DiveImpactComp/DiveImpactParticles.emission_rect_extents.x = 96
			
			if $ForsakenAlly/GroundRay.is_colliding() and boss.position.y > 12*8: #hit ground
				AudioManager.play_audio(sfxs.get_sfx("dash"))
				get_node("/root/World/Camera").radial_blur()
				get_node("/root/World/Camera").shake(5, 0.03, 3)
				get_node("/root/World/Camera").invert_color(0.5, 0.3)
				
				$DiveImpactComp.position = Vector2(boss.position.x, 18.5*8)
				$DiveImpactComp/DiveImpactParticles.restart()
				$EnvAnimPlayer.play("Dive Impact")
				$ForsakenAlly/BossSprite.visible = false
				$ForsakenAlly/GroundRay.enabled = false
				attack_state += 1
				
				$ForsakenAlly/DiveHurtCull.disabled = false #damage player on/off
				await get_tree().create_timer(0.1).timeout
				$ForsakenAlly/DiveHurtCull.disabled = true
				
			if attack_state == 4: #finish attack/land
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


func spike_wave_warning():
	for i in range(-6, 7, 3):
		if i != 0:
			var w_p = warning_particle.instantiate()
			w_p.width = 2
			w_p.position = Vector2(boss.position.x - (i*16), 20*8)
			w_p.emitting = true
			add_child(w_p)
		
func spike_wave():
	for i in range(-6, 7, 3):
		if i != 0:
			var s = floor_spike.instantiate()
			s.spike_amount = 1
			s.mode = "Instant"
			s.position = Vector2(boss.position.x - (i*16), 20*8)
			add_child(s)


func dodge_player(dodge_speed: float, center: bool, reset_attack: bool):
	$ForsakenAlly/HitArea/HitColl.set_deferred("disabled", true)
	$ForsakenAlly/HurtColl.set_deferred("disabled", true)
	if reset_attack:
		boss_state = BossState.IDLE
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
	
	if $ForsakenAlly/GroundRay.is_colliding() and hit_mode != HitMode.DODGE: #if on ground, boss jumps a bit 
		tween2 = self.create_tween()
		set_tween(tween2, Tween.TRANS_QUAD, Tween.EASE_OUT)
		tween2.tween_property(boss, "position:y", origin.y - 8, dodge_speed/2.0)
		tween2.set_ease(Tween.EASE_IN)
		tween2.tween_property(boss, "position:y", origin.y, dodge_speed/2.0)
	else: #if in air, boss does not jump when dodging
		self.create_tween().tween_property(boss, "position:y", origin.y, dodge_speed)
	
	await get_tree().create_timer(dodge_speed).timeout
	$ForsakenAlly/HurtColl.disabled = false
	$ForsakenAlly/HitArea/HitColl.disabled = false
	if reset_attack:
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
	
	await get_tree().create_timer(3).timeout
	
	dodge_player(0.3, false, true)
	$ForsakenAlly/BossAnimPlayer.play("Idle")


func choose_attack():
	while boss_state == last_attack or boss_state == BossState.IDLE: #makes sure its a different attack each round
		if attack_count > 5: #after 5 attacks floor spike will happen
			boss_state = 2 as BossState
		elif attack_count > 3: #after 3 attacks floor spikes are available
			boss_state = rng.randi_range(2, 4) as BossState
		else: #no floor spikes
			boss_state = rng.randi_range(3, 4) as BossState
	last_attack = boss_state


#damage boss
func _on_hit_area_body_entered(body):
	if hit_mode == HitMode.DAMAGE:
		if (health+1)%3 == 0: #boss dodge to center
			dodge_player(0.15, true, false)
		elif (health+2)%3 == 0: # after 3 hits
			intermission()
		else: #normal hit
			dodge_player(0.3, false, false)
		body.bounce(body.jump_vel)
		health -= 1
		get_node("/root/World/Camera").shake(4, 0.03, 3)
		get_node("/root/World/Camera").invert_color(1, 0.3)
		AudioManager.play_audio(sfxs.get_sfx("damage"))
		AudioManager.play_audio(sfxs.get_sfx("jump"))
		
		if health == 3:
			$DiveImpactComp/DiveImpactParticles.emission_rect_extents.x = 38*8
			$DiveImpactComp/DiveImpactParticles.amount = 200
			$DiveImpactComp.position = Vector2(19*8, 18.5*8)
			$DiveImpactComp/DiveImpactParticles.restart()
			$DiveImpactComp/DiveImpactParticles.emitting = true
			$ForsakenAlly/FinalPhaseParticles.emitting = true
			await get_tree().create_timer(0.5).timeout
			$DiveImpactComp/DiveImpactParticles.amount = 30
	
	if health == 0:
		get_node("/root/World").save_room_state($ActivationColl.position)
		#$Gate.open()
		#$Gate2.open()
		queue_free()
		
	elif hit_mode == HitMode.DODGE:
		dodge_player(0.3, false, true)

func toggle_hit_coll(mode: HitMode):
	#$ForsakenAlly/HitArea/HitColl.disabled = false
	#$ForsakenAlly/HitArea/HitColl.set_deferred("disabled", false)
	
	if mode == HitMode.DODGE:
		$ForsakenAlly/HitArea.position.y = -10
		$ForsakenAlly/HitArea.scale.y = 2
	elif mode == HitMode.DAMAGE:
		$ForsakenAlly/HitArea.position.y = 0
		$ForsakenAlly/HitArea.scale.y = 1
	#elif mode == HitMode.NONE:
		#$ForsakenAlly/HitArea/HitColl.disabled = true
		#$ForsakenAlly/HitArea/HitColl.set_deferred("disabled", true)
		
	hit_mode = mode


#calculates aim for various attacks. Tries to predict future player pos
func update_aim(delta):
	if player.velocity.x == 0:
		follow_pos.x = player.position.x
	else:
		follow_pos = follow_pos.lerp(player.position, delta * 0.6)
	aim_pos = 2 * player.position - follow_pos #converts position from behind the player to in front
	if aim_pos.x <= 24:
		aim_pos.x = 24
	elif aim_pos.x >= 35*8:
		aim_pos.x = 35*8


func intro_sequence():
	player.disable_movement(true)
	player.get_node("AnimationPlayer").play("Walk")
	tween1 = self.create_tween()
	await tween1.tween_property(player, "position:x", player.position.x - 10*8, 1).finished
	player.disable_movement(false)
	$Gate.close()
	$Gate2.close()
	player.get_node("AnimationPlayer").play("Idle")
	toggle_hit_coll(HitMode.DODGE)
	boss_state = BossState.RESET


func set_tween(tween: Tween, t: int, e: int):
	tween.set_trans(t)
	tween.set_ease(e)
