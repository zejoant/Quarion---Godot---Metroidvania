extends Area2D

var player
@onready var boss = $ForsakenAlly
@export var sfxs : AudioLibrary
var rng = RandomNumberGenerator.new()
var health = 3
var attack_state: int = 0
var attack_cooldown: int = 0

enum HitMode {DAMAGE, DODGE}
var hit_mode = HitMode.DODGE

enum BossState {IDLE, RESET, JUMP, SPIKE, DIVE, SHOT}
var boss_state: BossState = BossState.IDLE

var aim
var chance = 1

var tween1
var tween2

@onready var origin = $ForsakenAlly.position

var follow_pos
var aim_pos

var floor_spike = preload("res://Objects/big_floor_spike.tscn")

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
	if $ForsakenAlly/GroundRay.is_colliding() and $ForsakenAlly/AnimationPlayer.assigned_animation != "Lie Down":
		boss.scale.x = sign(boss.position.x - player.position.x)
		
		#if $ForsakenAlly/AnimationPlayer.current_animation != "Land" and $ForsakenAlly/AnimationPlayer.current_animation != "Jump":
		#	$ForsakenAlly/AnimationPlayer.play("Idle")
	
	if player.position.x > boss.position.x-8 and player.position.x < boss.position.x+8 and player.position.y < boss.position.y-6:
		$ForsakenAlly/HurtColl.disabled = true
	elif hit_mode == HitMode.DODGE:
		$ForsakenAlly/HurtColl.disabled = false
	
	if boss_state == BossState.RESET: #pre attack stuff
		attack_state = 0
		attack_cooldown = 0
		boss_state = BossState.IDLE
		#await get_tree().create_timer(rng.randi_range(1. 2)).timeout
		choose_attack()
	elif boss_state == BossState.JUMP:
		jump_attack()
	elif boss_state == BossState.SPIKE:
		floor_spikes()
	elif boss_state == BossState.DIVE:
		dive_attack()

func floor_spikes():
	if attack_state == 0:
		dodge_player(0.3, false, false)
		$ForsakenAlly/AnimationPlayer.play("Kneel")
		toggle_hit_coll(HitMode.DAMAGE)
		attack_state = rng.randi_range(4, 4)
	
	if attack_cooldown == 0: 
		var spike1 = floor_spike.instantiate()
		if attack_state > 0 and attack_state < 5: #x3 double spikes
			attack_state -= 1
			spike1.position = Vector2(aim_pos.x, 20*8)
		#elif attack_state == 5: #full flor spikes
			#spike1.position = Vector2(38*4, 20*8)
			#spike1.spike_amount = 19
			
		if attack_state == 1 or attack_state == 5: #reset for next spike attack
			attack_state = rng.randi_range(4, 4)
			attack_cooldown = -150 
			
		add_child(spike1)
		
	attack_cooldown += 1
	
	if attack_cooldown == 70:
		attack_cooldown = 0
	

func jump_attack():
	if !attack_cooldown:
		attack_cooldown = 1
		$ForsakenAlly/AnimationPlayer.play("Jump")
		tween1 = self.create_tween()
		set_tween(tween1, Tween.TRANS_SINE, Tween.EASE_OUT)
		tween1.tween_property(boss, "position:x", aim_pos.x, 1)
		
		tween2 = self.create_tween()
		set_tween(tween2, Tween.TRANS_QUAD, Tween.EASE_OUT)
		tween2.tween_property(boss, "position:y", origin.y-8*10, 0.5)
		tween2.set_ease(Tween.EASE_IN)
		tween2.tween_property(boss, "position:y", origin.y, 0.5)
		
	if boss.position.y <= origin.y - 8*9.5: #fall
		$ForsakenAlly/AnimationPlayer.play("Fall")
	
	#if $ForsakenAlly/AnimationPlayer.assigned_animation == "Fall" and boss.position.y > origin.y-8*5 and boss.position.y < origin.y-8*4:
		#if !rng.randi_range(0, 4): #possible double jump to trick the player
		#	boss.scale.x = sign(boss.position.x - player.position.x)
		#	attack_cooldown = false
	
	if $ForsakenAlly/GroundRay.is_colliding() and $ForsakenAlly/AnimationPlayer.assigned_animation == "Fall": #land
		$ForsakenAlly/AnimationPlayer.play("Land")
	
	if $ForsakenAlly/AnimationPlayer.assigned_animation == "Land": #wait until next jump
		attack_cooldown += 1
	
	if attack_cooldown == 50: #reset for next jump
		attack_state += 1
		attack_cooldown = false
	
	if attack_state == 3: #finish attack
		boss_state = BossState.RESET


func dive_attack():
	if attack_state == 0: #jump through ground
		attack_state = -1
		$ForsakenAlly/HitArea/HitColl.disabled = true
		$ForsakenAlly/AnimationPlayer.play("Jump")
		hit_mode = HitMode.DODGE
		tween1 = self.create_tween()
		set_tween(tween1, Tween.TRANS_QUAD, Tween.EASE_OUT)
		tween1.tween_property(boss, "position:y", origin.y - 4, 0.2)
		tween1.set_ease(Tween.EASE_IN)
		await tween1.tween_property(boss, "position:y", 30*8, 0.6).finished
		tween1.kill()
		attack_state = 1
	
	elif attack_state > 0:
		if boss.position.y >= 30*8: #dive
			$ForsakenAlly/GroundRay.enabled = true
			$ForsakenAlly/AnimationPlayer.play("Dive")
			boss.position.y = -8
			boss.position.x = aim_pos.x
			
			$WarningParticle.global_position = Vector2(aim_pos.x, 20*8)
			$WarningParticle.emitting = true
		
		if $ForsakenAlly/GroundRay.is_colliding() and boss.position.y > 12*8: #hit ground
			attack_state += 1
			$ForsakenAlly/GroundRay.enabled = false
			
			get_node("/root/World/Camera").radial_blur()
			get_node("/root/World/Camera").flash(0.3, 0, 0, 0.4)
			AudioManager.play_audio(sfxs.get_sfx("dash"))
			
			$DiveImpact.position = Vector2(boss.position.x, 18.5*8)
			#$DiveImpact.scale.x = 1
			$DiveImpact.visible = true
			await get_tree().create_timer(0.15).timeout
			#await create_tween().tween_property($DiveImpact, "scale:x", 1, 0.2).finished
			$DiveImpact.visible = false
			
		
		if attack_state == 4: #finish attack/land
			$ForsakenAlly/AnimationPlayer.play("Land")
			boss.position.y = 19*8
			$ForsakenAlly/HitArea/HitColl.disabled = false
			boss_state = BossState.IDLE
			await get_tree().create_timer(2).timeout
			boss_state = BossState.RESET
		else:
			boss.position.y += 4
	
	if $ForsakenAlly/AnimationPlayer.assigned_animation == "Jump" and boss.position.y == origin.y-4:
		$ForsakenAlly/AnimationPlayer.play("Fall")

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
	if !center:
		if player.position.x < 19*8:
			tween1.tween_property(boss, "position:x", 34*8, dodge_speed)
		else:
			tween1.tween_property(boss, "position:x", 4*8, dodge_speed)
	else:
		tween1.tween_property(boss, "position:x", 38*4, dodge_speed)
	
	if $ForsakenAlly/GroundRay.is_colliding() and hit_mode != HitMode.DODGE:
		tween2 = self.create_tween()
		set_tween(tween2, Tween.TRANS_QUAD, Tween.EASE_OUT)
		tween2.tween_property(boss, "position:y", origin.y - 8, dodge_speed/2.0)
		tween2.set_ease(Tween.EASE_IN)
		tween2.tween_property(boss, "position:y", origin.y, dodge_speed/2.0)
	else:
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
	$ForsakenAlly/AnimationPlayer.play("Lie Down")
	
	await get_tree().create_timer(3).timeout
	
	dodge_player(0.3, false, true)
	$ForsakenAlly/AnimationPlayer.play("Idle")


func choose_attack():
	boss_state = rng.randi_range(2, 4) as BossState
	#boss_state = BossState.DIVE


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
	
	if health == 0:
		get_node("/root/World").save_room_state($ActivationColl.position)
		#$Gate.open()
		#$Gate2.open()
		queue_free()
		
	elif hit_mode == HitMode.DODGE:
		dodge_player(0.3, false, true)

func toggle_hit_coll(mode: HitMode):
	if mode == HitMode.DODGE:
		$ForsakenAlly/HitArea.position.y = -16
	elif mode == HitMode.DAMAGE:
		$ForsakenAlly/HitArea.position.y = 0
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
