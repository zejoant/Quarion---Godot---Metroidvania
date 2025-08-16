extends CharacterBody2D

#region
@export_group("Properties")
@export var sfxs : AudioLibrary
@export var jump_vel = -235.0
@export var gravity = 13.0 / (1.0/60.0)
@export var fall_limiter = 230
@export var x_speed = 110.0

var coyote = 0
var buffer = 0
var jump_queued: bool = false
var can_jump = false
var can_drop: bool = true
var can_quick_respawn: bool = true

var direction
var last_dir = 1

const dash_lim = 9
var dash_timer = dash_lim
var dash_cooldown = 0
var dashing = false
var can_dash = true

var can_walljump = false
var walljumping = false
#var walljump_timer = 0
var walljump_coyote = 0
var walljump_dir = 1

var can_double_jump = false

var bubble_popped = true
var bubble_invincibility_time = 0.3
var affecting_force: int = 0

var update_animations = false
var can_move = true
var is_dead = false
var can_die = true
var can_die_from_water = true
var paused = false

var death_count: int = 0
var jump_count: int = 0

@export_group("Power-Ups")
@export var has_dash = false
@export var has_wallclimb = false
@export var has_double_jump = false
@export var has_freeze = false
@export var has_blue_blocks = false
@export var has_phantom_dash = false

@export_group("Items")
@export_enum("uncollected", "collected", "used") var green_key_state = "uncollected"
@export_enum("uncollected", "collected", "used") var red_key_state = "uncollected"
@export_range(0, 5) var amulet_pieces: int = 0
@export var has_item_map = false
@export var has_bubble = false
@export_range(0, 9999) var apple_count : int = 0
var apple_count_saved: int = 0
var apple_count_total

var respawn_tween: Tween
var idle_timer: int = 0

var last_jump_vel: float
var can_head_push: bool = true

var current_palette: int = 0

@onready var world_map = get_parent().get_node("WorldMap")
#endregion

func _ready():
	velocity.y = 200
	
	await Engine.get_main_loop().process_frame
	update_animations = true
	
	if get_parent().new_game:
		$ParticleComps.visible = false
		$AnimationPlayer.play("Lie Down")
		disable_movement(true)
		update_animations = false
	
	if has_freeze:
		var tilemap = load("res://tile_map.tscn").instantiate()
		tilemap.change_water_tiles()
		tilemap = null
	
	update_palette(current_palette)
	
	if !can_move:
		await get_tree().create_timer(2, false).timeout
		$AnimationPlayer.play("Kneel")
		$ParticleComps.visible = true
		await get_tree().create_timer(0.5, false).timeout
		update_animations = true
		disable_movement(false)
	
#runs every frame
func _physics_process(delta):
	if !is_dead and !paused:
		if is_on_floor():
			#if jump_queued:
				#jump()
				#jump_queued = false
			coyote = 5
			can_dash = true
			can_double_jump = true
		else: #applies gravity if in air
			if world_map.open:
				world_map.open_or_close()
			velocity.y += gravity * delta
			coyote -= 1
			if velocity.y > fall_limiter:
				velocity.y = fall_limiter
			
			if is_on_ceiling() and walljump_coyote <= 0 and can_head_push:
				if !%RCenter.is_colliding() or (%RCenter.get_collider() is TileMap and %RCenter.get_collider().is_tile_one_way(%RCenter.get_collider_rid())):
					position.x = int(position.x/8.0) * 8 + 4
					velocity.y = last_jump_vel
					can_head_push = false
		
		if is_on_wall():
			affecting_force = 0
			$LedgeArea.scale.x = last_dir
			if !$LedgeArea.has_overlapping_bodies() and velocity.y >= 0:
				position.y -= 1
		
		#cooldown for dash
		if dash_cooldown != 0:
				dash_cooldown += 1
				if dash_cooldown == 30:
					dash_cooldown = 0
		#enables jumping
		if !dashing and buffer == 0 and (is_on_floor() or (coyote >= 0 and velocity.y >= 0)):
			can_jump = true
		#disables jumping
		elif coyote < 0:
			can_jump = false
		
		check_inputs()
		animate_player()
		wallslide_check()
		move_and_slide()
	elif is_dead:
		check_inputs(true)

#func _unhandled_input(event):
	#if !can_move:
		#return
	#if event.is_action_released("Jump"): #release jump
		#jump_queued = false
		#buffer = 0 #reset jump buffer
		#if velocity.y <= jump_vel / 4.0:
				#velocity.y = jump_vel / 4.0
	#elif event.is_action_pressed("Jump"):
		#if can_double_jump and has_double_jump and !can_jump and !buffer: #double jump
			#jump(true)
		#elif can_jump: #normal jump
			#jump()
		#elif can_walljump or walljumping: #walljump
			#walljump()
		#else:
			#jump_queued = true
	#
	#if event.is_action_pressed("Drop") and can_drop:
		#drop()
	#elif event.is_action_released("Drop"):
		#can_drop = true

#checks all player inputs
func check_inputs(dead_input: bool = false):
	if Input.is_action_just_pressed("Quick Respawn") and (can_move or is_dead) and (!get_parent().red_boss_beaten or get_parent().secret_boss_beaten) and can_quick_respawn and !get_parent().no_death_mode:
		die(true)
	if !dead_input:
		if Input.is_action_just_pressed("Debug"):
			AudioManager.play_audio(sfxs.get_sfx("jump"))
			#get_parent().secret_boss_beaten = true
			#get_parent().red_boss_beaten = true
			#has_blue_blocks = true
			has_dash = true
			has_wallclimb = true
			has_double_jump = true
			#has_freeze = true
			#get_parent().get_tilemap().change_water_tiles()
			#bubble_action(true, false)
			update_apple_count(50, true)
			get_parent().apple_total = 50
			#get_parent().completion_percentage = 99
			#has_item_map = true
			#get_parent().get_node("WorldMap/MapComps/ItemMap").visible = true
			#green_key_state = "collected"
			#red_key_state = "collected"
			#get_parent().get_node("Camera").enable_amulet_pieces(4)
		if Input.is_action_just_pressed("Debug Checkpoint") and is_on_floor():
			AudioManager.play_audio(sfxs.get_sfx("jump"))
			get_parent().save_checkpoint_room(position)
		if Input.is_action_just_pressed("Debug Map"):
			AudioManager.play_audio(sfxs.get_sfx("jump"))
			get_parent().get_node("WorldMap").debug_all_rooms()
		if !can_move:
			return
			
		if Input.is_action_just_released("Jump"): #release jump
			buffer = 0 #reset jump buffer
			if velocity.y <= jump_vel / 4.0:
				velocity.y = jump_vel / 4.0
		elif Input.is_action_pressed("Jump") and can_double_jump and has_double_jump and coyote < 0 and !can_walljump and !dashing and !buffer: #double jump
			jump(true)
		elif Input.is_action_pressed("Jump") and can_jump: #not just_pressed cause buffer needs to work
			jump()
		elif (Input.is_action_just_pressed("Jump") and can_walljump) or walljumping:
			walljump()
		
		
		if Input.is_action_pressed("Drop") and can_drop:
			drop()
		elif Input.is_action_just_released("Drop"):
			can_drop = true
		
		if Input.is_action_just_pressed("Dash") and can_dash and !dash_cooldown and has_dash: #and !can_walljump:
			if is_on_wall() and can_walljump:
				dash(walljump_dir*-1)
			else:
				dash()
				
		if !walljumping and (dash_timer < 0 or dash_timer == dash_lim):
			walk()
			if !dashing:
				affect_with_force()
		if dashing:
			process_dash()
		if Input.is_action_just_pressed("Map") and is_on_floor():
			get_parent().get_node("WorldMap").open_or_close()
		
		last_jump_vel = velocity.y

#handles all sprite animations of the player
func animate_player():
	if !update_animations:
		return
	if !dashing:
		if is_on_floor():
			if ($AnimationPlayer.current_animation == "Fall" or $AnimationPlayer.current_animation == "WallSlide") and $AnimationPlayer.current_animation != "Land":
				$ParticleComps/LandParticles.restart()
				$AnimationPlayer.play("Land")
				AudioManager.play_audio(sfxs.get_sfx("land"))
			elif $AnimationPlayer.current_animation != "Land":
				if (velocity.x == 0 or is_on_wall()) and $AnimationPlayer.current_animation != "Idle" and idle_timer < 1200:
					$AnimationPlayer.play("Idle")
				elif velocity.x == 0 and $AnimationPlayer.current_animation != "Sit" and idle_timer >= 1200 and idle_timer < 2400:
					$AnimationPlayer.play("Sit")
				elif velocity.x == 0 and $AnimationPlayer.current_animation != "Rest" and idle_timer >= 2400:
					$AnimationPlayer.play("Rest")
				elif velocity.x != 0 and $AnimationPlayer.current_animation != "Walk" and !is_on_wall():
					$AnimationPlayer.play("Walk")
		else:
			if !can_walljump:
				if velocity.y < 0 and $AnimationPlayer.current_animation != "Jump":
					$AnimationPlayer.play("Jump")
				elif velocity.y >= 0 and $AnimationPlayer.current_animation != "Fall":
					$AnimationPlayer.play("Fall")
			elif can_walljump and $AnimationPlayer.current_animation != "WallSlide":
				$AnimationPlayer.play("WallSlide")
	elif $AnimationPlayer.current_animation != "Dash":
		$AnimationPlayer.play("Dash")
	
	if !bubble_popped:
		$BubbleSprite.position.x = sin(float(Engine.get_frames_drawn())/50.0)/1.5
		$BubbleSprite.position.y = cos(float(Engine.get_frames_drawn())/40.0)/1.5
		$BubbleSprite.modulate.a = abs(cos(float(Engine.get_frames_drawn())/50.0)/2.0)
	
	if ($AnimationPlayer.current_animation == "Idle" or $AnimationPlayer.current_animation == "Sit" or $AnimationPlayer.current_animation == "Rest") and can_move and !get_parent().get_node("WorldMap").open:
		idle_timer += 1
	else:
		$Zzzzzz.visible = false
		idle_timer = 0

#death and respawning
func die(quick_respawn: bool = false, ignore_can_die: bool = false):
	if !has_bubble or bubble_popped or quick_respawn:
		var world = get_node("/root/World")
		if !is_dead and (can_die or ignore_can_die):
			death_count += 1
			AudioManager.pause_song()
			is_dead = true
			if !bubble_popped:
				bubble_action(false, true, false)
			
			update_palette(7, false)
			update_animations = false
			$AnimationPlayer.play("Damage")
			world.get_node("Camera").invert_color(1, 0.3)
			world.get_node("Camera").shake(5, 0.05, 3)
			AudioManager.play_audio(sfxs.get_sfx("death"))
			
			respawn_tween = self.create_tween()
			await respawn_tween.tween_interval(0.5).finished
			$Sprite2D.visible = false
			$Area2D/EnemyColl.position.x = 0
			$ParticleComps/DeathParticles/RingExplosionParticles.restart()  
			$ParticleComps/DeathParticles/PixelExplosionParticles.restart() 
			$ParticleComps/DeathParticles/RingExplosionParticles.emitting = true
			$ParticleComps/DeathParticles/PixelExplosionParticles.emitting = true
			AudioManager.play_audio(sfxs.get_sfx("explode"))
			
			respawn_tween = self.create_tween()
			await respawn_tween.tween_interval(1.4).finished
			respawn_at_checkpoint()
		elif is_dead and quick_respawn:
			respawn_at_checkpoint()
			
	elif can_die:
		bubble_action(false, true)

func respawn_at_checkpoint():
	if get_parent().no_death_mode:
		get_parent().return_to_main_menu()
		return
	if respawn_tween:
				respawn_tween.kill()
	#$Sprite2D.material.set_shader_parameter("palette_choice", current_palette)
	update_palette(current_palette)
	$AnimationPlayer.play("RESET")
	$ParticleComps/DeathParticles/RingExplosionParticles.amount = 1
	$ParticleComps/DeathParticles/PixelExplosionParticles.amount = 1
	$ParticleComps/DeathParticles/RingExplosionParticles.amount = 50
	$ParticleComps/DeathParticles/PixelExplosionParticles.amount = 70
	
	can_quick_respawn = false
	get_node("/root/World/Camera").flash(1, 0, 0.2, 0.3)
	velocity = Vector2(0, 0)
	dashing = false
	dash_timer = dash_lim
	affecting_force = 0
	AudioManager.resume_respawn_song()
	get_parent().revert_temporary_actions()
	get_parent().return_to_checkpoint()
	$Sprite2D.visible = true
	is_dead = false
	can_jump = true
	can_move = true
	buffer = 0
	update_animations = true
	bubble_action(false, false)
	get_node("/root/World/Camera").hide_ui(true)
	respawn_tween = self.create_tween()
	await respawn_tween.tween_interval(1).finished
	can_quick_respawn = true

func bubble_action(enable: bool = false, pop: bool = false, pop_effect: bool = true):
	if has_bubble:
		if pop:
			bubble_popped = true
			if pop_effect:
				$BubbleSprite.modulate.a = 1
				if velocity.y >= 0:
					velocity.y = jump_vel
				else:
					velocity.y = -velocity.y#jump_vel/10 #sign(velocity.y) * jump_vel
				affecting_force = -sign(velocity.x) * 300
				dash_timer = dash_lim
				can_die = false
				can_die_from_water = false
				get_parent().get_node("Camera").invert_color(1, 0.3)
				get_parent().get_node("Camera").shake(2, 0.05, 3)
				AudioManager.play_audio(sfxs.get_sfx("bubble pop"))
				$BubbleSprite.play("pop")
				paused = true
				await get_tree().create_timer(0.1, false).timeout
				paused = false
				await get_tree().create_timer(bubble_invincibility_time*0.5, false).timeout
				can_die_from_water = true
				await get_tree().create_timer(bubble_invincibility_time*0.5, false).timeout
				can_die = true
			else:
				$BubbleSprite.modulate.a = 0
		else:
			bubble_popped = false
			bubble_invincibility_time = 0.3
			$BubbleSprite.play("default")
			affecting_force = 0
			
	if enable:
		has_bubble = true
		$BubbleSprite.visible = true
		bubble_popped = false

#bounce on certain enemies
func bounce(strength):
	if !is_dead:
		can_dash = true
		velocity.y = strength
		#move_and_slide()
		can_jump = false
		#$AnimationPlayer.play("Jump")

#Handle the jump
func jump(double_jump: bool = false):
	if double_jump:
		can_double_jump = false
		$ParticleComps/DoubleJumpParticles.direction = Vector2(-velocity.x/4.0, 110).normalized()
		$ParticleComps/DoubleJumpParticles.emitting = true
	jump_count += 1
	can_head_push = true
	velocity.y = jump_vel
	buffer = 1
	can_jump = false
	AudioManager.play_audio(sfxs.get_sfx("jump"))
	
	#if dashing and dash_timer > 2:
		#can_dash = true
		#affecting_force = sign(last_dir) * 300
		#if dash_timer > 4:
			#affecting_force = sign(last_dir) * 320
		#dash_timer = dash_lim
		#dash_cooldown = 0
	
	#if dashing:
		#if dash_timer < 3:
			#affecting_force = sign(last_dir) * 200
		#else:
			#can_dash = true
			#affecting_force = sign(last_dir) * 300
			#if dash_timer > 4:
				#affecting_force = sign(last_dir) * 320
		#dash_timer = dash_lim
		#dash_cooldown = 0

# Gets the input direction and handles the movement.
func walk():
	if direction:
		last_dir = direction
	direction = Input.get_axis("Left", "Right")
	if !direction:
		if Input.is_action_pressed("Left") and Input.is_action_just_pressed("Right"):
			direction = 1
		elif Input.is_action_pressed("Right") and Input.is_action_just_pressed("Left"):
			direction = -1
		elif Input.is_action_pressed("Right") and Input.is_action_pressed("Left"):
			direction = last_dir
	if direction:
		if direction > 0:
			$Sprite2D.scale.x = 1
		elif direction < 0:
			$Sprite2D.scale.x = -1
		if abs(direction) < 0.5:
			direction = sign(direction) * 0.5
		
		if !dashing:
			velocity.x = direction * x_speed# + affecting_force
		
		if $AnimationPlayer.current_animation == "Walk":
			$AnimationPlayer.speed_scale = abs(direction)
		else:
			$AnimationPlayer.speed_scale = 1
	else:
		$AnimationPlayer.speed_scale = 1
		velocity.x = 0

func affect_with_force():
	if direction:
		velocity.x += affecting_force
		if affecting_force != 0:
			affecting_force -= sign(affecting_force) * 10
			if abs(velocity.x) > abs(affecting_force) and abs(affecting_force) > x_speed:
				velocity.x = affecting_force
			if abs(affecting_force) <= x_speed and abs(velocity.x) > x_speed:
				velocity.x = sign(velocity.x) * x_speed
	else:
		velocity.x = affecting_force
		if affecting_force != 0:
			affecting_force -= sign(affecting_force) * 10

#drop through platforms
func drop():
	if is_on_floor():
		can_drop = false
		position.y += 1

#activates the dash ability
func dash(dir: int = 0):
	dash_timer = -3
	dash_cooldown += 1
	can_dash = false
	can_jump = false
	dashing = true
	velocity.x = 0
	#$Area2D/EnemyColl.scale.x = 1.75
	
	if dir:
		dash_timer = 0
		$Sprite2D.scale.x = dir
	

	if is_on_floor() or coyote >= 0:
		position.y -= 4
	
	#dash_cooldown = true
	#await get_tree().create_timer(0.5, false).timeout
	#dash_cooldown = false
	
	var c = load("res://Particles/speed_circle.tscn").instantiate()
	c.position = position
	c.scale.x = $Sprite2D.scale.x
	get_parent().get_room().add_child(c)

#hanlde the dashing after a dash is activated
func process_dash():
	#if is_on_wall() and dash_timer:
	#	dash_timer = dash_lim
	if dash_timer == 0:
		var p = load("res://Particles/dash_particles.tscn").instantiate()
		p.position = position
		p.scale.x = $Sprite2D.scale.x
		p.get_node("Particles").emitting = true
		get_parent().get_room().add_child(p)
		
		get_parent().get_node("Camera").shake(1.5, 0.04, 3)
		get_parent().get_node("Camera").radial_blur(0.02)
		AudioManager.play_audio(sfxs.get_sfx("dash"))
	
	if dash_timer < dash_lim: #perform dash
		if dash_timer >= 0:
			velocity.x = sign($Sprite2D.scale.x)*990.0/(dash_timer+1.0)
		velocity.y = 0
		dash_timer += 1
		
	if dash_timer == dash_lim:
		$Area2D/EnemyColl.position.x = 0
		#$Area2D/EnemyColl.scale.x = 1
		$ParticleComps/DashParticles.emitting = false
		dashing = false
	
	if dash_timer == 1:
		$Area2D/EnemyColl.position.x = -5 * $Sprite2D.scale.x
	
	if dash_timer == 2:
		var c = load("res://Particles/speed_circle.tscn").instantiate()
		c.position = position
		c.scale.x = $Sprite2D.scale.x
		c.scale *= 0.5
		get_parent().get_room().add_child(c)

#checks if you are against a wall
func wallslide_check():
	if is_on_wall_only() and has_wallclimb and (direction != 0 or can_walljump) and velocity.y >= -50:
			if !can_walljump:
				walljump_dir = direction
				walljump_coyote = 4
			can_walljump = true
			can_dash = true
			can_double_jump = true
			if velocity.y >= 50:
				velocity.y = 40
	
	elif can_walljump:
		if walljump_coyote <= 0:
			can_walljump = false
		walljump_coyote -= 1

#jump on walls
func walljump():
	if !walljumping:
		walljump_coyote = 0
		dash_timer = dash_lim
		walljumping = true
		can_walljump = false
		#walljump_timer = 0
		velocity.x = x_speed * -walljump_dir
		jump()
		await get_tree().create_timer(7.0/60.0, false).timeout
		walljumping = false

#activates if player enters a body. Also provieds the body_rid which can give you the tile coords of the body
func _on_area_2d_body_shape_entered(body_rid, body, _body_shape_index, _local_shape_index):
	if body.is_in_group("Enemy"):#kills player
		if !has_phantom_dash or !dashing:
			die()
	elif body.is_in_group("Checkpoint"):
		body.activate()
		bubble_action(false, false)
	elif body.is_in_group("Collectable"):
		body.collect()
	elif body is TileMap:
		custom_data_action(body.get_custom_data_with_rid(body_rid))

#does action based on the custom data of a tile
func custom_data_action(custom_data: String):
	if custom_data == "Spike":
		die()
	elif !has_freeze and custom_data == "Water":
		if can_die_from_water:
			die(false, true)
		die()
	elif !has_freeze and (custom_data == "WaterFall" and (!has_phantom_dash or !dashing)):
		die()

#replaces water with ice if you have the freeze power up
func on_water_entered(body_rid, body, _body_shape_index, _local_shape_index):
	if body is TileMap and has_freeze:
		body.freeze_water_tile(body_rid)

#turn on/off player input/movement
func disable_movement(disable: bool = true):
	if disable:
		dashing = false
		dash_timer = dash_lim
		affecting_force = 0
		can_move = !disable
		velocity.x = 0 #Vector2(0, 0)
	else:
		can_move = true
		can_jump = true
		buffer = 0

#updates apple count when collecting apples and buying from shop
func update_apple_count(value: int, override: bool = false, permanent: bool = false):
	if override:
		apple_count = value
	else:
		apple_count += value
	if permanent:
		apple_count_saved = apple_count
	get_node("/root/World/Camera").update_apple_count(apple_count)

func reset_particles():
	$ParticleComps/DashParticles.amount = 1
	$ParticleComps/LandParticles.amount = 1
	$ParticleComps/DoubleJumpParticles.amount = 1
	
	$ParticleComps/DashParticles.amount = 50
	$ParticleComps/LandParticles.amount = 5
	$ParticleComps/DoubleJumpParticles.amount = 5

func update_palette(col, permanent: bool = true):
	if permanent:
		current_palette = col
	get_node("/root/World/WorldMap/MapComps/RoomMap/PlayerIcon").material.set_shader_parameter("palette_choice", col)
	$Sprite2D.material.set_shader_parameter("palette_choice", col)

#squish
func _on_inside_wall(body_rid, body, _body_shape_index, _local_shape_index):
	if (!(body is TileMap) or !body.is_tile_one_way(body_rid)) and !is_dead:
		if is_on_wall():
			pass
		else:
			$Sprite2D.region_rect = Rect2(96, 0, 16, 16)
		die(true)
