extends Node2D
class_name Hermit

@export var sfxs : AudioLibrary

static var has_seen_intro = false
var player_from_right = false

@onready var player = get_node("/root/World/Player")
@onready var cam = get_node("/root/World/Camera")
@onready var p = get_parent()
var rng = RandomNumberGenerator.new()

var lev_origin = Vector2(152, 32)
enum AirState {LEVITATING, SIDE_LEVITATING, GROUNDED}
var air_state = AirState.GROUNDED

enum HitMode {NONE, HIT, GHOST}
var hit_mode = HitMode.HIT

var health = 12
enum BossState {IDLE, CHOOSE_ATTACK, REPAIR_SHIELD, FAKEOUT, AROUND_SHOTS, SIDE_BEAMS, STAFF_SHOTS, DASH, DOWN_SLAM, CIRCLE_EXPLOSIONS}
var boss_state: BossState = BossState.IDLE
var attack_state: int = 0
var attack_sub_state: int = 0
var attack_cooldown: int = 0

var last_attack: BossState
var last_hittable_attack: BossState
var attack_count = 0

var aim_pos: Vector2
var same_dir_time: float = 0

var time = 0
var lev_distance: float = 1

var afterimage_texture = preload("res://afterimage.tscn")
var afterimage_cooldown = 0
var afterimage_active: bool = true

var tween1: Tween
var teleportTween: Tween

var long_afterimage: bool = false

var hermit_flee: bool = false

var paused: bool = false

#@onready var teleportTimer: Timer = Timer.new()
#@onready var timer1: Timer = Timer.new()

var bullet1 = preload("res://Objects/bullet.tscn")
var beam = preload("res://Objects/staff_beam.tscn")
var shockwave = preload("res://Objects/shockwave.tscn")
var cirplosion = preload("res://Objects/circle_explosion.tscn")
var staff_bullet = preload("res://Objects/staff_bullet.tscn")

func _ready():
	
	if get_node("/root/World").secret_boss_beaten:
		queue_free()
		return
	#for pos in get_node("/root/World").get_room_state():
		#if Vector2i(position) == Vector2i(pos): #check if boss has been defeated
			#queue_free()
			#return
	
	player.bubble_invincibility_time = 0.5
	if player.position.x > 152: 
		p.scale.x = -1
		p.position.x = 304
		player_from_right = true
	
	cam.hide_ui(false)
	
	intro_sequence()

func _physics_process(_delta):
	if !paused:
		if hit_mode == HitMode.HIT:
			update_hit_coll()
		
		update_aim()
		
		if air_state != AirState.GROUNDED:
			position.y = lev_origin.y + cos(float(time)/30.0)*10#*2
			if air_state == AirState.LEVITATING:
				position.x = lev_origin.x + cos(float(time)/40.0)*10*lev_distance#*2
				
		if boss_state == BossState.CHOOSE_ATTACK:
			boss_state = BossState.IDLE
			
			$DashSlashHurtColl.disabled = true
			$HurtColl.position.y = 7
			lev_distance = 1
			long_afterimage = false
			#set_hit_mode(HitMode.HIT)
			if tween1:
				tween1.kill()
			tween1 = self.create_tween()
			if health > 3:
				await tween1.tween_interval(1).finished
			else:
				await tween1.tween_interval(0.4).finished
			choose_attack()
		elif boss_state == BossState.AROUND_SHOTS:
			around_shots()
		elif boss_state == BossState.SIDE_BEAMS:
			side_beams()
		elif boss_state == BossState.DOWN_SLAM:
			down_slam()
		elif boss_state == BossState.CIRCLE_EXPLOSIONS:
			circle_explosions()
		elif boss_state == BossState.DASH:
			dash_attack()
		elif boss_state == BossState.STAFF_SHOTS:
			staff_shots()
		elif boss_state == BossState.REPAIR_SHIELD:
			repair_shield()
		elif boss_state == BossState.FAKEOUT:
			second_phase_fakout()
		
		if afterimage_active:
			afterimage()
		
		time += 1
	
	if hermit_flee:
		p.get_node("HermitFleeSprite").position = Vector2(152.0 - float(time/2.2), 96.0 - sin(float(time)/20.0)*sqrt(float(time)/4.0) - float(time/4.0))
		time += 1

func second_phase_fakout():
	if attack_state == 0:
		set_hit_mode(HitMode.GHOST)
		air_state = AirState.GROUNDED
		AudioManager.pause_song()
		AudioManager.play_audio(sfxs.get_sfx("explode_charge"), 0.72, 1, self)
		attack_state = 1
		
	if attack_state == 1:
		attack_state = -1
		if attack_sub_state == 14:
			teleport(Vector2(152, 72), true, 0, "levitate", false)
		else:
			teleport(Vector2(rng.randi_range(64, 240), rng.randi_range(64, 128)), true, 0, "levitate", false)
		#cam.invert_color(1, 0.2)
		cam.shake(4, 0.03, 3)
		AudioManager.play_audio(sfxs.get_sfx("hit"))
		tween1 = self.create_tween()
		if attack_sub_state <= 10:
			await tween1.tween_interval(0.7 - attack_sub_state*0.05).finished
		else:
			await tween1.tween_interval(0.2).finished
		attack_sub_state += 1
		if attack_sub_state == 15:
			attack_state = 2
		else:
			attack_state = 1
		
	if attack_state == 2:
		attack_state = -1
		cam.invert_color(1, 0.2)
		AudioManager.play_audio(sfxs.get_sfx("hit"))
		AudioManager.play_audio(sfxs.get_sfx("death_explosion"))
		$RingExplosionParticles.emitting = true
		$BossSprite.visible = false
		afterimage_active = false
		#teleport(Vector2(-100, -100), true, 0.1, "levitate", false)
		await get_tree().create_timer(2, false).timeout
		position = Vector2(-100, -100)
		lev_origin = position
		AudioManager.resume_song()	
		self.create_tween().tween_method(AudioManager.set_speed, 0.01, 1, 0.8)
		await get_tree().create_timer(0.5, false).timeout
		$BossSprite.visible = true
		afterimage_active = true
		teleport(Vector2(152, 72), true, 0, "levitate", false)
		await get_tree().create_timer(0.21, false).timeout
		AudioManager.play_audio(sfxs.get_sfx("scream"), 1, 1.5)
		get_node("/root/World/Camera").radial_blur(0.03, 1, 12)
		await get_tree().create_timer(0.5, false).timeout
		boss_state = BossState.CHOOSE_ATTACK
		#attack_state = 3

func repair_shield():
	if attack_state == 0:
		attack_state = -1
		air_state = AirState.SIDE_LEVITATING
		if lev_origin != Vector2(152, 32):
			teleport(Vector2(152, 32), true, 0, "hands_together")
			tween1 = self.create_tween()
			await tween1.tween_interval(0.42).finished
		lev_distance = 0.5
		tween1 = self.create_tween()
		await tween1.tween_interval(0.5).finished
		attack_state = 1
	
	if attack_state == 1:
			attack_state = -1
			$GlassShield.modulate.a = 0.8
			$GlassShield.play("repair")
			AudioManager.play_audio(sfxs.get_sfx("glass_repair"))
			await self.create_tween().tween_property($GlassShield, "modulate:a", 0, 1.4).finished
			boss_state = BossState.CHOOSE_ATTACK

func dash_attack():
	if attack_state == 0:
		attack_state = -1
		air_state = AirState.GROUNDED
		if player.position.x < 152:
			teleport(Vector2(304-32, 18.5*8), false, 0)
			$BossSprite.scale.x = 1
			$WarningArea.scale.x = 433
		else:
			teleport(Vector2(32, 18.5*8), false)
			$BossSprite.scale.x = -1
			$WarningArea.scale.x = -433
		tween1 = self.create_tween()
		await tween1.tween_interval(0.42).finished
		attack_state = 1
	
	if attack_state == 1:
		attack_state = -1
		tween1 = self.create_tween()
		if health > 3:
			$AnimationPlayer.play("dash_wind_up")
			await tween1.tween_property($WarningArea, "modulate:a", 0.4, 1).finished
		else:
			$AnimationPlayer.play("dash_wind_up", -1, 1.5)
			await tween1.tween_property($WarningArea, "modulate:a", 0.4, 0.75).finished
		#await tween1.tween_interval(0.7).finished
		$WarningArea.modulate.a = 0
		p.get_node("ImpactEffectBig").rotation = -PI/2.0
		p.get_node("ImpactEffectBig").position = position
		p.get_node("ImpactEffectBig").play("default")
		AudioManager.play_audio(sfxs.get_sfx("dash"))
		#cam.invert_color(1, 0.2)
		cam.shake(4, 0.03, 3)
		long_afterimage = true
		attack_state = 2
	
	if attack_state == 2:
		attack_state = -1
		var dest
		if $BossSprite.scale.x == 1:
			dest = Vector2(60, position.y)
		else:
			dest = Vector2(244, position.y)
			
		p.get_node("TeleportLine").position = dest
		p.get_node("TeleportLine").modulate.a = 1
		p.get_node("TeleportLine").scale.y = position.distance_to(dest)/16.0
		p.get_node("TeleportLine").rotation = position.angle_to_point(dest) + PI/2.0
		self.create_tween().tween_property(p.get_node("TeleportLine"), "modulate:a", 0, 0.3)
		
		self.create_tween().tween_property(self, "position:x", dest.x, 0.2)
		tween1 = self.create_tween()
		await tween1.tween_interval(0.15).finished
		
		$AnimationPlayer.play("dash_slash")
		tween1 = self.create_tween()
		await tween1.tween_interval(0.05).finished
		long_afterimage = false
		AudioManager.play_audio(sfxs.get_sfx("swing"))
		AudioManager.play_audio(sfxs.get_sfx("shot"))
		tween1 = self.create_tween()
		if health > 3:
			await tween1.tween_interval(0.9).finished
		else:
			await tween1.tween_interval(0.4).finished
		teleport(Vector2(-100, -100), true, 0.1)
		boss_state = BossState.CHOOSE_ATTACK

func staff_shots():
	if attack_state == 0:
		attack_state = -1
		air_state = AirState.LEVITATING
		if lev_origin != Vector2(152, 32):
			teleport(Vector2(152, 32), true, 0, "levitate_hands_up")
			tween1 = self.create_tween()
			await tween1.tween_interval(0.91).finished
		else:
			$AnimationPlayer.play("levitate_hands_up")
		attack_state = 1
	
	if attack_state == 1:
		attack_state = -1
		attack_sub_state += 1
		
		#if health <= 3:
			#if attack_sub_state == 2:
				#aim_pos.x += 24
			#elif attack_sub_state == 3:
				#aim_pos.x -= 24
		if health > 3:
			var s = staff_bullet.instantiate()
			s.setup(Vector2(aim_pos.x, player.position.y), Vector2(lev_origin.x, lev_origin.y-8))
			p.add_child(s)
			
			s = staff_bullet.instantiate()
			s.setup(Vector2(aim_pos.x+8, player.position.y-24), Vector2(lev_origin.x-50, lev_origin.y))
			p.add_child(s)
			
			s = staff_bullet.instantiate()
			s.setup(Vector2(aim_pos.x+32, player.position.y-24), Vector2(lev_origin.x-100, lev_origin.y+16))
			p.add_child(s)
			
			s = staff_bullet.instantiate()
			s.setup(Vector2(aim_pos.x-8, player.position.y-24), Vector2(lev_origin.x+50, lev_origin.y))
			p.add_child(s)
			
			s = staff_bullet.instantiate()
			s.setup(Vector2(aim_pos.x-32, player.position.y-24), Vector2(lev_origin.x+100, lev_origin.y+16))
			p.add_child(s)
		else:
			if attack_sub_state > 4:
				$AnimationPlayer.play("swing_hand_down")
				$BossSprite.scale.x *= -1
			var s = staff_bullet.instantiate()
			if !attack_sub_state%5:
				s.setup(Vector2(aim_pos.x, player.position.y), Vector2(rng.randi_range(16, 288), lev_origin.y-rng.randi_range(0, 1)*8), 250, 72)
			else:
				s.setup(Vector2(aim_pos.x, player.position.y), Vector2(rng.randi_range(16, 288), lev_origin.y-rng.randi_range(0, 1)*8))
			p.add_child(s)
		
		if (attack_sub_state == 3 and health > 3) or attack_sub_state == 20:
			$AnimationPlayer.play("levitate_hands_up")
			$BossSprite.scale.x = 1
			boss_state = BossState.CHOOSE_ATTACK
		else:
			tween1 = self.create_tween()
			if health > 3:
				await tween1.tween_interval(1.1).finished
			else:
				await tween1.tween_interval(0.2).finished
			attack_state = 1

func circle_explosions():
	if attack_state == 0:
		lev_distance = 0
		air_state = AirState.LEVITATING
		#air_state = AirState.GROUNDED
		attack_state = 1
		if lev_origin != Vector2(152, 72):
			teleport(Vector2(152, 72), true, 0.5, "levitate")
			tween1 = self.create_tween()
			await tween1.tween_interval(0.91).finished
		#air_state = AirState.LEVITATING
		tween1 = self.create_tween()
		set_tween(tween1, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
		tween1.tween_property(self, "lev_distance", 5, 2)
		#lev_distance = 5
	
	elif attack_state == 1:
		attack_state = -1
		attack_sub_state += 1
			
		var c = cirplosion.instantiate()
		if attack_sub_state == 6 or attack_sub_state == 12:
			c.position = aim_pos
		else:
			c.position = Vector2(rng.randi_range(40, 304-40), rng.randi_range(40, 192-40))
		p.add_child(c)

		if attack_sub_state == 12:
			attack_sub_state = 0
		
		tween1 = self.create_tween()
		if health > 3:
			await tween1.tween_interval(0.5).finished
		else:
			await tween1.tween_interval(0.3).finished
		attack_state = 1

func down_slam():
	if attack_state == 0:
		attack_state = -1
		air_state = AirState.LEVITATING
		if lev_origin != Vector2(152, 32):
			teleport(Vector2(152, 32), true)
			tween1 = self.create_tween()
			await tween1.tween_interval(0.42).finished
		
		$AnimationPlayer.play("levitate")
		tween1 = self.create_tween()
		await tween1.tween_interval(0.5).finished
		tween1 = self.create_tween()
		if health > 3:
			$AnimationPlayer.play("raise_staff", -1, 1.5)
			AudioManager.play_audio(sfxs.get_sfx("charge"), 2)
			await tween1.tween_interval(1.067).finished
		else:
			$AnimationPlayer.play("raise_staff", -1, 2.25)
			AudioManager.play_audio(sfxs.get_sfx("charge"), 3)
			await tween1.tween_interval(0.7113).finished
		attack_state = 1
	
	if attack_state == 1:
		attack_state = -1
		set_hit_mode(HitMode.NONE)
		#hit_mode = HitMode.NONE
		air_state = AirState.GROUNDED
		p.get_node("ImpactEffect").rotation = 0
		p.get_node("ImpactEffect").position = position
		p.get_node("ImpactEffect").play("default")
		#cam.invert_color(0.7, 0.2)
		tween1 = self.create_tween()
		await tween1.tween_property(self, "position:y", 18.5*8, 0.4).finished
		
		var s = shockwave.instantiate()
		s.setup(-1, 1.6, Vector2(position.x, 22*8))
		p.add_child(s)
		s = shockwave.instantiate()
		s.setup(1, 1.6, Vector2(position.x, 22*8))
		p.add_child(s)
		
		cam.invert_color(1, 0.2)
		cam.shake(4, 0.03, 3)
		AudioManager.play_audio(sfxs.get_sfx("ground_impact"))
		$StaffRaise.visible = false
		
		attack_sub_state += 1
		if attack_sub_state == 4:
			#hit_mode = HitMode.HIT
			set_hit_mode(HitMode.HIT)
			$AnimationPlayer.play("stand_up")
			attack_state = 2
		else:
			if player.position.y > 32:
				teleport(Vector2(aim_pos.x, 32), true)
			else:
				teleport(Vector2(aim_pos.x, player.position.y), true)
			lev_origin = position
			air_state = AirState.LEVITATING
			tween1 = self.create_tween()
			await tween1.tween_interval(0.42).finished
			tween1 = self.create_tween()
			if health > 3:
				$AnimationPlayer.play("raise_staff", -1, 2.3)
				AudioManager.play_audio(sfxs.get_sfx("charge"), 2.86)
				await tween1.tween_interval(0.7).finished# - (0.6 - ceil(float(health)/3.0)*0.15)).finished
			else:
				
				#$AnimationPlayer.play_section("raise_staff", -1, 0.1)
				$AnimationPlayer.play("raise_staff", -1, 16)
				await tween1.tween_interval(0.1).finished
			attack_state = 1
	
	if attack_state == 2:
		attack_state = -1
		tween1 = self.create_tween()
		await tween1.tween_interval(2).finished
		$AnimationPlayer.play("stand")
		lev_origin = position
		boss_state = BossState.CHOOSE_ATTACK

func around_shots():
	if attack_state == 0:
		attack_state = -1
		air_state = AirState.LEVITATING
		if lev_origin != Vector2(152, 32):
			teleport(Vector2(152, 32), true)
			tween1 = self.create_tween()
			await tween1.tween_interval(0.42).finished
		#tween1 = self.create_tween()
		#set_tween(tween1, Tween.TRANS_QUART, Tween.EASE_IN_OUT)
		#await tween1.tween_property(self, "lev_origin", Vector2(152, 32), 0.5).finished
		#await tween1.tween_property(self, "position", Vector2(lev_origin.x, 3*8), 0.3).finished
		$BossSprite.scale.x = 1
		$AnimationPlayer.play("hold_out_staff_right")
		$StaffChargeParticles.emitting = true
		AudioManager.play_audio(sfxs.get_sfx("charge"), 2)
		tween1 = self.create_tween()
		await tween1.tween_interval(1).finished
		attack_state = 1
	
	if attack_state == 1 or attack_state == 2:
		if !attack_cooldown:
			attack_cooldown -= 1
			if attack_sub_state != 0 and health <= 9: #teleport every swing
				if attack_sub_state == 1:
					teleport(Vector2(228, 56), true)
				elif attack_sub_state == 2:
					teleport(Vector2(76, 56), true)
				elif attack_sub_state == 3:
					teleport(Vector2(152, 32), true)
				tween1 = self.create_tween()
				await tween1.tween_interval(0.42).finished
			
			for num in range(0, 12-attack_state): #spawn all bullets
				var b = bullet1.instantiate()
				if attack_state == 1:
					b.setup(2.0, Vector2.LEFT.rotated(-num*PI/10.0), position, num%2 == 0, true, 20)
				elif attack_state == 2:
					b.setup(2.0, Vector2.LEFT.rotated(-PI*0.05 - num*PI/10.0), position, num%2 == 0, true, 20)
				p.add_child(b)
			
			AudioManager.play_audio(sfxs.get_sfx("swing"))
			AudioManager.play_audio(sfxs.get_sfx("shot"))
			if attack_state == 1:
				$AnimationPlayer.play("below_swing_left")
				attack_state = 2
			elif attack_state == 2:
				$AnimationPlayer.play("below_swing_right")
				attack_state = 1
			attack_cooldown = 30 - (28 - ceil(float(health)/3.0)*7)
			attack_sub_state += 1
		else:
			attack_cooldown -= 1
	
	if attack_sub_state == 4:
		boss_state = BossState.CHOOSE_ATTACK


func side_beams():
	if attack_state == 0:
		enable_wallspikes()
		#p.get_node("WallSpikeComps/WallSpikes").position.y = 0
		attack_state = -1
		air_state = AirState.SIDE_LEVITATING
		var side = rng.randi_range(0, 1)
		teleport(Vector2(16 + side*272, 192-64), true)
		if side == 0:
			$BossSprite.scale.x = -1
		else:
			$BossSprite.scale.x = 1
		tween1 = self.create_tween()
		await tween1.tween_interval(0.42).finished
		
		
		$BossSprite.region_rect = Rect2(0, 176, 32, 40)
		$BossSprite.offset = Vector2(1, 3)
		tween1 = self.create_tween()
		await tween1.tween_interval(1).finished
		attack_state = 1
	
	if attack_state == 1:
		if attack_cooldown == 0:
			attack_cooldown -= 1
			var r = rng.randi_range(0, 7)
			
			if r <= 1:
				side_shot_spawn_beam(Vector2(position.x, 152), true)
				tween1 = self.create_tween()
				await tween1.tween_interval(0.1 + r*0.2).finished
				
				side_shot_spawn_beam(Vector2(position.x, 152-24), true)
				if r == 1:
					side_shot_spawn_beam(Vector2(position.x, 152-48), false)
			
			elif r == 2 or r == 3:
				side_shot_spawn_beam(Vector2(position.x, 152-24*(r-2)), true)
				side_shot_spawn_beam(Vector2(position.x, 152-48), false)
			
			if r >= 4 and r < 7:
				side_shot_spawn_beam(Vector2(position.x, 152), true)
				tween1 = self.create_tween()
				await tween1.tween_interval(0.3).finished
				
				side_shot_spawn_beam(Vector2(position.x, 152), true)
				if r >= 5:
					side_shot_spawn_beam(Vector2(position.x, 152-(48-(r-5)*24)), false)
				tween1 = self.create_tween()
				await tween1.tween_interval(0.3).finished
				
				side_shot_spawn_beam(Vector2(position.x, 152), true)
			
			if r == 7:
				side_shot_spawn_beam(Vector2(position.x, 152-24), true)
				side_shot_spawn_beam(Vector2(position.x, 152-48), false)
				tween1 = self.create_tween()
				await tween1.tween_interval(0.3).finished
				side_shot_spawn_beam(Vector2(position.x, 152), true)
			
			if health > 3:
				attack_cooldown = 60# - (20 - ceil(float(health)/3.0)*5)
			else:
				attack_cooldown = 40
			attack_sub_state += 1
			if attack_sub_state == 5:
				attack_state = 2
		else:
			attack_cooldown -= 1
	
	if attack_state == 2:
		if attack_cooldown == 0:
			enable_wallspikes(false)
			#p.get_node("WallSpikeComps/WallSpikes").position.y = -1000
			boss_state = BossState.CHOOSE_ATTACK
		else:
			attack_cooldown -= 1

func side_shot_spawn_beam(pos: Vector2, sound: bool = true):
	if sound:
		AudioManager.play_audio(sfxs.get_sfx("swing"))
		AudioManager.play_audio(sfxs.get_sfx("shot"))
	$AnimationPlayer.stop()
	$AnimationPlayer.play("side_swing")
	var b = beam.instantiate()
	b.setup(pos, Vector2(-1*$BossSprite.scale.x, 0), 3)
	p.add_child(b)

func teleport(destination: Vector2, move_lev_origin: bool, wait_between: float = 0, after_anim: String = "none", change_hit_mode: bool = true):
	var old_hit_mode = hit_mode
	set_hit_mode(HitMode.GHOST)
	#var old_state = air_state
	#air_state = AirState.GROUNDED
	AudioManager.play_audio(sfxs.get_sfx("teleport"))
	$AnimationPlayer.play("teleport_out")
	#$HurtColl.disabled = true
	$DashSlashHurtColl.disabled = true
	teleportTween = self.create_tween()
	await teleportTween.tween_interval(0.21).finished
	if wait_between:
		position = Vector2(-100, -100)
		lev_origin = position
		teleportTween = self.create_tween()
		await teleportTween.tween_interval(wait_between).finished
		if wait_between > 0.1:
			AudioManager.play_audio(sfxs.get_sfx("teleport"))
	else:
		p.get_node("TeleportLine").position = destination
		p.get_node("TeleportLine").modulate.a = 1
		p.get_node("TeleportLine").scale.y = position.distance_to(destination)/16.0
		p.get_node("TeleportLine").rotation = position.angle_to_point(destination) + PI/2.0
		if player_from_right:
			self.create_tween().tween_property(p.get_node("TeleportLine"), "modulate:a", 0, 0.21)
		else:
			self.create_tween().tween_property(p.get_node("TeleportLine"), "modulate:a", 0, 0.3)
	
	if move_lev_origin:
		lev_origin = destination
	position = destination
	$AnimationPlayer.play("teleport_in")
	teleportTween = self.create_tween()
	await teleportTween.tween_interval(0.21).finished
	#air_state = old_state
	#$HurtColl.disabled = false
	if change_hit_mode:
		set_hit_mode(HitMode.HIT)
	else:
		set_hit_mode(old_hit_mode)
	if after_anim != "none":
		$AnimationPlayer.play(after_anim)

func choose_attack():
	if health > 3:
		if attack_count < 2 or (attack_count == 3 and rng.randi_range(0, 1)):
			boss_state = random_choice(4, 7, last_attack)
			last_attack = boss_state
		else:
			boss_state = random_choice(8, 9, last_hittable_attack)
			last_hittable_attack = boss_state
			attack_count = 0
	else:
		if attack_count < 3 or (attack_count == 4 and rng.randi_range(0, 1)):
			boss_state = random_choice(4, 7, last_attack)
			last_attack = boss_state
		else:
			boss_state = random_choice(8, 9, last_hittable_attack)
			last_hittable_attack = boss_state
			attack_count = 0
	
	
	attack_count += 1
	attack_state = 0
	attack_sub_state = 0
	attack_cooldown = 0

func random_choice(start: int, end: int, exclude: int = 0) -> BossState:
	if exclude:
		if exclude == start:
			return rng.randi_range(start+1, end) as BossState
		elif exclude == end:
			return rng.randi_range(start, end-1) as BossState
		else:
			if rng.randi_range(0, 1):
				return rng.randi_range(start, exclude-1) as BossState
			else:
				return rng.randi_range(exclude+1, end) as BossState
	return rng.randi_range(start, end) as BossState

func enable_wallspikes(enable: bool = true):
	if !enable:
		p.get_node("WallSpikeComps/Left/WallSpikeWarning").modulate.a = 0
		p.get_node("WallSpikeComps/Right/WallSpikeWarning").modulate.a = 0
		p.get_node("WallSpikeComps/SpikeColl/CollLeft").set_deferred("disabled", true)
		p.get_node("WallSpikeComps/SpikeColl/CollRight").set_deferred("disabled", true)
		
		var t = self.create_tween()
		t.parallel().tween_property(p.get_node("WallSpikeComps/Left/WallSpikes"), "position:x", 15, 0.1)
		await t.parallel().tween_property(p.get_node("WallSpikeComps/Right/WallSpikes"), "position:x", 289, 0.1).finished
		
		p.get_node("WallSpikeComps/Left/WallSpikes").visible = false
		p.get_node("WallSpikeComps/Right/WallSpikes").visible = false
		p.get_node("WallSpikeComps").visible = false
	else:
		p.get_node("WallSpikeComps").visible = true
		
		var t = self.create_tween()
		t.parallel().tween_property(p.get_node("WallSpikeComps/Left/WallSpikeWarning"), "modulate:a", 0.5, 0.2)
		t.parallel().tween_property(p.get_node("WallSpikeComps/Right/WallSpikeWarning"), "modulate:a", 0.5, 0.2)
		
		await t.tween_interval(0.8).finished
		p.get_node("WallSpikeComps/Left/WallSpikes").visible = true
		p.get_node("WallSpikeComps/Right/WallSpikes").visible = true
		
		AudioManager.play_audio(sfxs.get_sfx("spike_wall"))
		t = self.create_tween()
		t.parallel().tween_property(p.get_node("WallSpikeComps/Left/WallSpikes"), "position:x", 15+6, 0.1)
		await t.parallel().tween_property(p.get_node("WallSpikeComps/Right/WallSpikes"), "position:x", 289-6, 0.1).finished
		
		p.get_node("WallSpikeComps/Left/WallSpikeWarning").modulate.a = 0
		p.get_node("WallSpikeComps/Right/WallSpikeWarning").modulate.a = 0
		p.get_node("WallSpikeComps/SpikeColl/CollLeft").set_deferred("disabled", false)
		p.get_node("WallSpikeComps/SpikeColl/CollRight").set_deferred("disabled", false)


func intro_sequence():
	AudioManager.pause_song()
	player.disable_movement(true)
	$BossSprite.scale.x = -1
	if player_from_right:
		player.position.x = 303
	else:
		player.position.x = 1
		
	if !has_seen_intro:
		$AnimationPlayer.play("point_staff")
		player.paused = true
		p.get_node("Red").visible = true
		cam.fade("000000", 1, 0, 0.2, 0.5)
		cam.zoom_camera(1.4, 0, Vector2(position.x+8, position.y-8*3))
		has_seen_intro = true
		player.position.y = 19*8
		player.visible = false
		await get_tree().create_timer(2, false).timeout
		
		p.get_node("Red").flip_h = false
		p.get_node("Red").region_rect.position = Vector2(0, 16)
		await get_tree().create_timer(0.2, false).timeout
		
		$AnimationPlayer.play("stand")
		await get_tree().create_timer(0.2, false).timeout
		
		AudioManager.play_audio(sfxs.get_sfx("jump"))
		p.get_node("Red").region_rect.position = Vector2(64, 16)
		tween1 = self.create_tween()
		tween_prop(tween1, Tween.TRANS_QUART, Tween.EASE_OUT, p.get_node("Red"), "position:y", 10*8, 0.8, true)
		tween_prop(tween1, Tween.TRANS_LINEAR, Tween.EASE_OUT, p.get_node("Red"), "position:x", 39*8, 0.8, true)
		await get_tree().create_timer(1.3, false).timeout
		
		cam.zoom_camera(1, 0.4)
		player.visible = true
		player.get_node("ParticleComps/DashParticles").lifetime = 0.01
		
		player.paused = false
		player.position.y = 20*8
	
	
	
	#player.position.x = 1
	if player_from_right:
		player.velocity = Vector2(-player.x_speed, 0)
	else:
		player.velocity = Vector2(player.x_speed, 0)
	await get_tree().create_timer(1, false).timeout
	
	player.velocity.x = 0
	await get_tree().create_timer(0.5, false).timeout
	
	$BossSprite.scale.x = 1
	await get_tree().create_timer(0.8, false).timeout
	#$BossSprite.play("point staff")
	$AnimationPlayer.play("point_staff")
	AudioManager.play_audio(sfxs.get_sfx("swing"))
	await get_tree().create_timer(1, false).timeout
	
	#$AnimationPlayer.play("teleport_out")
	teleport(lev_origin, false)
	await get_tree().create_timer(0.21, false).timeout
	
	player.disable_movement(false)
	player.get_node("ParticleComps/DashParticles").lifetime = 3
	p.get_node("Gate").close()
	p.get_node("Gate2").close()
	AudioManager.resume_song()
	AudioManager.play_song(load("res://Music/Everhood_The_Final_Battle.mp3"))
	
	#position = lev_origin
	#$AnimationPlayer.play("teleport_in")
	await get_tree().create_timer(0.21, false).timeout
	if player_from_right:
		p.scale.x = 1
		p.position.x = 0
		#p.get_node("TeleportLine").modulate.a = 0
		player_from_right = false
	
	$AnimationPlayer.play("levitate")
	air_state = AirState.LEVITATING
	await get_tree().create_timer(2, false).timeout
	
	#boss_state = BossState.STAFF_SHOTS
	boss_state = BossState.AROUND_SHOTS
	last_attack = BossState.AROUND_SHOTS
	last_hittable_attack = BossState.IDLE

func afterimage():
	if !afterimage_cooldown:
		afterimage_cooldown = 2
		var tex = afterimage_texture.instantiate()
		if long_afterimage:
			tex.fade_time = 0.5
			afterimage_cooldown = 0
			tex.sprite_alpha = 1
		tex.region_rect = $BossSprite.region_rect
		tex.position = position
		tex.scale = $BossSprite.scale
		tex.offset = $BossSprite.offset
		tex.flip_h = $BossSprite.flip_h
		tex.scale.x = $BossSprite.scale.x
		get_parent().add_child(tex)
	else:
		afterimage_cooldown -= 1

func update_aim():
	aim_pos = Vector2(player.position.x + (player.velocity.x/30.0) * same_dir_time, player.position.y)#/ (1.5 * (30.0-float(same_dir_time)))
	
	if sign(player.last_dir) == sign(player.direction) and !player.can_walljump:
		if same_dir_time < 29:
			same_dir_time += 0.5
	else:
		same_dir_time = 0
	#p.get_node("Apaolo").position = aim_pos
	
	if aim_pos.x <= 32:
		aim_pos.x = 32
	elif aim_pos.x >= 34*8:
		aim_pos.x = 34*8

func update_hit_coll():
	if player.velocity.y/20.0 > 3:
		$HitArea.scale.y = player.velocity.y/20.0
	else:
		$HitArea.scale.y = 3
	
	if player.velocity.y < 2:
		$HitArea/HitColl.disabled = true
	else:
		$HitArea/HitColl.disabled = false
		if $HitArea.overlaps_body(player):
				_hit_on_head(player)

func set_hit_mode(mode: HitMode):
	if mode == HitMode.GHOST:
		$HurtColl.set_deferred("disabled", true)
		#$DashSlashHurtColl.set_deferred("disabled", true)
		$HitArea/HitColl.set_deferred("disabled", true)
	else:
		$HurtColl.set_deferred("disabled", false)
		#$DashSlashHurtColl.set_deferred("disabled", false)
		$HitArea/HitColl.set_deferred("disabled", false)
	
	hit_mode = mode

func play_sfx(sfx_name: String):
	AudioManager.play_audio(sfxs.get_sfx(sfx_name))

func set_tween(tween: Tween, t: int, e: int):
	tween.set_trans(t)
	tween.set_ease(e)

func tween_prop(tween: Tween, t: int, e: int, target, prop: String, val, t_time: float, parallel = false):
	#tween = self.create_tween()
	set_tween(tween, t, e)
	if parallel:
		tween.parallel().tween_property(target, prop, val, t_time)
	else:
		tween.tween_property(target, prop, val, t_time)

func _hit_on_head(body):
	if hit_mode == HitMode.HIT:
		set_hit_mode(HitMode.GHOST)
		long_afterimage = false
		boss_state = BossState.IDLE
		body.bounce(body.jump_vel)
		cam.shake(4, 0.03, 3)
		enable_wallspikes(false)
		if tween1:
			tween1.kill()
		teleportTween.kill()
		
		#glass shield stuff
		$GlassShield.modulate.a = 0.8
		self.create_tween().tween_property($GlassShield, "modulate:a", 0, 0.6)
		if health%3 == 0:
			AudioManager.play_audio(sfxs.get_sfx("glass_echo"))
			#$GlassShield.visible = true
			#$GlassShield.region_rect.position.x = 0
			$GlassShield.play("crack")
			#print($GlassShield.get_playing_speed())
			tween1 = create_tween()
			set_tween(tween1, Tween.TRANS_QUART, Tween.EASE_OUT)
			tween1.tween_property($GlassShield, "position:y", 9, 0.25)
			set_tween(tween1, Tween.TRANS_QUART, Tween.EASE_IN_OUT)
			tween1.tween_property($GlassShield, "position:y", 5, 0.25)
			#await get_tree().create_timer(0.05, false).timeout
			#$GlassShield.region_rect.position.x = 48
		elif health%3 == 2:
			$GlassShield.play("break")
			#$GlassShield.region_rect.position.x = 96
			player.paused = true
			paused = true
			#await get_tree().create_timer(0.1, false).timeout
			#$GlassShield.region_rect.position.x = 144
			await get_tree().create_timer(0.2, false).timeout
			$GlassBreakParticles.emitting = true
			AudioManager.play_audio(sfxs.get_sfx("glass_break"))
			player.paused = false
			paused = false
			#$GlassShield.region_rect.position.x = 144
			#await get_tree().create_timer(0.2, false).timeout
			#$GlassShield.visible = false
		else:
			$BossSprite.material.set_shader_parameter("strength", 1)
			if air_state == AirState.GROUNDED:
				$BossSprite.region_rect = Rect2(136, 136, 40, 40)
				$BossSprite.offset = Vector2(-5, 0)
			player.paused = true
			paused = true
			await get_tree().create_timer(0.2, false).timeout
			$BossSprite.material.set_shader_parameter("strength", 0)
			cam.invert_color(1, 0.3)
			AudioManager.play_audio(sfxs.get_sfx("hit"))
			player.paused = false
			paused = false
			
		health -= 1
		
		if health == 0:
			die()
			return
		
		if air_state == AirState.LEVITATING:
			var t = self.create_tween()
			t.set_ease(Tween.EASE_OUT)
			t.set_trans(Tween.TRANS_QUART)
			t.tween_property(self, "lev_origin:y", lev_origin.y + 8 + ((health+1)%3)*8, 0.2)
			#if (health+1)%3 > 0:
			#	t.tween_property(self, "lev_origin:y", lev_origin.y+32, 0.2)
			#else:
			#	t.tween_property(self, "lev_origin:y", lev_origin.y+8, 0.2)
		
		await get_tree().create_timer(0.3, false).timeout
		if health == 3:
			attack_count = 0
			attack_state = 0
			attack_sub_state = 0
			attack_cooldown = 0
			boss_state = BossState.FAKEOUT
		elif health%3 == 0:
			attack_count = 0
			attack_state = 0
			attack_sub_state = 0
			attack_cooldown = 0
			boss_state = BossState.REPAIR_SHIELD
		else:
			teleport(Vector2(-100, -100), true, 0.1)
			await get_tree().create_timer(0.2, false).timeout
			boss_state = BossState.CHOOSE_ATTACK

func die():
	#cam.flash(1, 0, 0.1, 0.2)
	player.velocity = Vector2(0, 0)
	player.disable_movement(true)
	player.visible = false
	player.paused = true
	player.position.y = 20*8
	p.get_node("BlackCover").modulate.a = 1
	set_hit_mode(HitMode.GHOST)
	AudioManager.stop_song()
	boss_state = BossState.IDLE
	get_node("/root/World").secret_boss_beaten = true
	#get_node("/root/World").save_room_state(Vector2(168, 148))
	player.bubble_invincibility_time = 0.3
	SteamManager.get_achivement("HermitBoss")
	get_node("/root/World").add_to_completion_percentage("Hermit")
	
	air_state = AirState.GROUNDED
	position = Vector2(152, 96)
	cam.zoom_camera(1.4, 0)
	#position = Vector2(152, 72)
	#if position != Vector2(152, 72):
	#	teleport(Vector2(152, 72), true)
	#	await get_tree().create_timer(0.42, false).timeout
	
	$AnimationPlayer.play("implode")
	AudioManager.play_audio(sfxs.get_sfx("explode_charge"), 1.543, 1, self)
	await get_tree().create_timer(3.5, false).timeout
	cam.invert_color(1, 0.2)
	AudioManager.play_audio(sfxs.get_sfx("hit"))
	AudioManager.play_audio(sfxs.get_sfx("death_explosion"))
	
	$BossSprite.visible = false
	$RingExplosionParticles.emitting = true
	$PixelExplosionParticles.emitting = true
	await get_tree().create_timer(0.1, false).timeout
	
	AudioManager.play_audio(sfxs.get_sfx("scream"), 1, 1.5)
	p.get_node("HermitFleeSprite").position = position
	p.get_node("HermitFleeSprite").modulate.a = 0.6
	hermit_flee = true
	time = 0
	
	await get_tree().create_timer(2.2, false).timeout
	p.get_node("HermitFleeSprite").modulate.a = 0
	p.create_tween().tween_property(p.get_node("BlackCover"), "modulate:a", 0, 1)
	cam.zoom_camera(1, 1)
	player.visible = true
	player.paused = false
	player.disable_movement(false)
	afterimage_active = false
	$BossSprite.material.set_shader_parameter("strength", 0)
	p.get_node("Gate").open()
	p.get_node("Gate2").open()
	cam.hide_ui(true)
	AudioManager.resume_previous_song()
	call_deferred("queue_free")

func _on_water_touched(body_rid, body, _body_shape_index, _local_shape_index):
	if body is TileMap:
		var tile_coords = body.get_coords_for_body_rid(body_rid)
		var tile_data = body.get_cell_tile_data(0, tile_coords)
		if tile_data != null:
			var custom_data = tile_data.get_custom_data("Functional Tiles")
			if custom_data == "Water":
				body.erase_cell(0, tile_coords)
				body.set_cell(1, tile_coords, 0, Vector2i(43, 4), 0)
