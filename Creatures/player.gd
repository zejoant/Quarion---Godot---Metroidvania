extends CharacterBody2D

#region
@export_group("Properties")
@export var sfxs : AudioLibrary
@export var jump_vel = -235.0
@export var gravity = 13.0 #ProjectSettings.get_setting("physics/2d/default_gravity")
@export var fall_limiter = 230
@export var x_speed = 110.0

var coyote = 0
var buffer = 0
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

#var in_interact_area = false
var has_opened_map: bool = false
var update_animations = true
var can_move = true
var is_dead = false
var can_die = true
var paused = false

var death_count: int = 0
var jump_count: int = 0

@export_group("Power-Ups")
@export var has_dash = false
@export var has_wallclimb = false
@export var has_double_jump = false
@export var has_freeze = false
@export var has_blue_blocks = false

@export_group("Items")
@export_enum("uncollected", "collected", "used") var green_key_state = "uncollected"
@export_enum("uncollected", "collected", "used") var red_key_state = "uncollected"
@export_range(0, 5) var amulet_pieces: int = 0
@export var has_shop_fast_travel = false
@export var has_item_map = false
@export var has_bubble = false
@export_range(0, 9999) var apple_count : int = 0
var apple_count_saved: int = 0

var respawn_tween: Tween
var idle_timer: int = 0
#endregion

func _ready():
	velocity.y = 200
	
	#await get_parent().ready
	await Engine.get_main_loop().process_frame
	#await get_parent().get_tilemap().ready
	
	if get_parent().new_game:
		$ParticleComps.visible = false
		$AnimationPlayer.play("Lie Down")
		disable_movement(true)
		update_animations = false
	
	if has_blue_blocks:
		$Sprite2D.material.set_shader_parameter("palette_choice", 1)
	if has_dash:
		$Sprite2D.material.set_shader_parameter("palette_choice", 2)
	if has_wallclimb:
		$Sprite2D.material.set_shader_parameter("palette_choice", 3)
	if has_double_jump:
		$Sprite2D.material.set_shader_parameter("palette_choice", 4)
	if has_freeze:
		var tilemap = load("res://tile_map.tscn").instantiate()
		tilemap.change_water_tiles()
		tilemap = null
		$Sprite2D.material.set_shader_parameter("palette_choice", 5)
	elif !has_blue_blocks and !has_dash and !has_wallclimb and !has_double_jump:
		$Sprite2D.material.set_shader_parameter("palette_choice", 0)
	
	if !can_move:
		await get_tree().create_timer(2, false).timeout
		$AnimationPlayer.play("Kneel")
		$ParticleComps.visible = true
		await get_tree().create_timer(0.5, false).timeout
		update_animations = true
		disable_movement(false)
	
#runs every frame
func _physics_process(_delta):
	if !is_dead and !paused:
		if is_on_floor():
			if !Input.is_action_pressed("Jump"):
				buffer = 0
			coyote = 5
			can_dash = true
			can_double_jump = true
		elif !is_on_floor():#applies gravity if in air
			if get_parent().get_node("WorldMap").open:
				get_parent().get_node("WorldMap").open_or_close()
			velocity.y += gravity
			coyote -= 1
			if velocity.y > fall_limiter:
				velocity.y = fall_limiter
		
		if is_on_wall():
			affecting_force = 0
			
		#if $CollissionRays/RightRay.is_colliding() and $CollissionRays/LeftRay.is_colliding():
		#	respawn(true)
		
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
		
		animate_player()
		check_inputs()
		move_and_slide()
		wallslide_check()
	elif is_dead:
		check_inputs(true)

#checks all player inputs
func check_inputs(dead_input: bool = false):
	if Input.is_action_just_pressed("Quick Respawn") and (can_move or is_dead) and (!get_parent().red_boss_beaten or get_parent().secret_boss_beaten) and can_quick_respawn:
		respawn(true)
	if !dead_input:
		if Input.is_action_just_pressed("Debug"):
			AudioManager.play_audio(sfxs.get_sfx("p_up_finish"))
			#get_parent().secret_boss_beaten = true
			#get_parent().red_boss_beaten = true
			#has_blue_blocks = true
			has_dash = true
			has_wallclimb = true
			has_double_jump = true
			has_freeze = true
			get_parent().get_tilemap().change_water_tiles()
			#bubble_action(true, false)
			update_apple_count(9999, true)
			has_item_map = true
			get_parent().get_node("WorldMap/MapComps/ItemMap").visible = true
			#green_key_state = "used"
			red_key_state = "collected"
			get_parent().get_node("Camera").enable_amulet_pieces(4)
		if Input.is_action_just_pressed("Debug Checkpoint") and is_on_floor():
			AudioManager.play_audio(sfxs.get_sfx("p_up_finish"))
			get_parent().save_checkpoint_room(position)
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
				
		if !walljumping and !dashing:
			walk()
			affect_with_force()
		if dashing:
			process_dash()
		if Input.is_action_just_pressed("Map") and is_on_floor():
			get_parent().get_node("WorldMap").open_or_close()

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
				if (velocity.x == 0 or is_on_wall()) and $AnimationPlayer.current_animation != "Idle" and idle_timer < 600:
					$AnimationPlayer.play("Idle")
				elif velocity.x == 0 and $AnimationPlayer.current_animation != "Sit" and idle_timer >= 600 and idle_timer < 1200:
					$AnimationPlayer.play("Sit")
				elif velocity.x == 0 and $AnimationPlayer.current_animation != "Rest" and idle_timer >= 1200:
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
		#$BubbleSprite.rotation_degrees += 0.1
	
	if $AnimationPlayer.current_animation == "Idle" or $AnimationPlayer.current_animation == "Sit" or $AnimationPlayer.current_animation == "Rest":
		idle_timer += 1
	else:
		$Zzzzzz.visible = false
		idle_timer = 0

#death and respawning
func respawn(quick_respawn: bool = false):
	if !has_bubble or bubble_popped or quick_respawn:
		var world = get_node("/root/World")
		var currentPalette
		if !is_dead and can_die:
			currentPalette = $Sprite2D.material.get_shader_parameter("palette_choice")
			death_count += 1
			AudioManager.pause_song()
			is_dead = true
			if !bubble_popped:
				bubble_action(false, true, false)
			
			$Sprite2D.material.set_shader_parameter("palette_choice", 6)
			$AnimationPlayer.play("Damage")
			world.get_node("Camera").invert_color(1, 0.3)
			world.get_node("Camera").shake(5, 0.05, 3)
			AudioManager.play_audio(sfxs.get_sfx("death"))
			
			respawn_tween = self.create_tween()
			await respawn_tween.tween_interval(0.5).finished
			#await get_tree().create_timer(0.5, false).timeout
			$Sprite2D.visible = false
			$Sprite2D.material.set_shader_parameter("palette_choice", currentPalette)
			$ParticleComps/DeathParticles/RingExplosionParticles.restart()  
			$ParticleComps/DeathParticles/PixelExplosionParticles.restart() 
			$ParticleComps/DeathParticles/RingExplosionParticles.emitting = true
			$ParticleComps/DeathParticles/PixelExplosionParticles.emitting = true
			AudioManager.play_audio(sfxs.get_sfx("explode"))
			
			respawn_tween = self.create_tween()
			await respawn_tween.tween_interval(1.4).finished
			can_quick_respawn = false
			#await get_tree().create_timer(1.4, false).timeout
			world.get_node("Camera").flash(1, 0, 0.2, 0.3)
			velocity = Vector2(0, 0)
			dashing = false
			dash_timer = dash_lim
			affecting_force = 0
			AudioManager.resume_respawn_song()
			world.revert_temporary_actions()
			world.return_to_checkpoint()
			$Sprite2D.visible = true
			is_dead = false
			can_jump = true
			can_move = true
			bubble_action(false, false)
			respawn_tween = self.create_tween()
			await respawn_tween.tween_interval(1).finished
			can_quick_respawn = true
		elif is_dead and quick_respawn:
			can_quick_respawn = false
			if respawn_tween:
				respawn_tween.kill()
			$Sprite2D.material.set_shader_parameter("palette_choice", currentPalette)
			$AnimationPlayer.play("RESET")
			world.get_node("Camera").flash(1, 0, 0.2, 0.3)
			velocity = Vector2(0, 0)
			dashing = false
			dash_timer = dash_lim
			affecting_force = 0
			AudioManager.resume_respawn_song()
			world.revert_temporary_actions()
			world.return_to_checkpoint()
			$Sprite2D.visible = true
			is_dead = false
			can_jump = true
			can_move = true
			bubble_action(false, false)
			respawn_tween = self.create_tween()
			await respawn_tween.tween_interval(1).finished
			can_quick_respawn = true
	elif can_die:
		bubble_action(false, true)

func bubble_action(enable: bool = false, pop: bool = false, pop_effect: bool = true):
	if has_bubble:
		if pop:
			bubble_popped = true
			#$BubbleSprite.visible = false
			if pop_effect:
				$BubbleSprite.modulate.a = 1
				if velocity.y >= 0:
					velocity.y = jump_vel
				else:
					velocity.y = -jump_vel/10 #sign(velocity.y) * jump_vel
				affecting_force = -sign(velocity.x) * 300
				dash_timer = dash_lim
				can_die = false
				get_parent().get_node("Camera").invert_color(1, 0.3)
				get_parent().get_node("Camera").shake(2, 0.05, 3)
				AudioManager.play_audio(sfxs.get_sfx("bubble pop"))
				$BubbleSprite.play("pop")
				paused = true
				await get_tree().create_timer(0.1, false).timeout
				paused = false
				await get_tree().create_timer(bubble_invincibility_time, false).timeout
				can_die = true
			else:
				$BubbleSprite.modulate.a = 0
		else:
			bubble_popped = false
			bubble_invincibility_time = 0.3
			#$BubbleSprite.visible = true
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
		move_and_slide()
		can_jump = false
		#$AnimationPlayer.play("Jump")

#Handle the jump
func jump(double_jump: bool = false):
	if double_jump:
		can_double_jump = false
		$ParticleComps/DoubleJumpParticles.direction = Vector2(-velocity.x/4.0, 110).normalized()
		$ParticleComps/DoubleJumpParticles.emitting = true
	jump_count += 1
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
		
		velocity.x = direction * x_speed# + affecting_force
		#if affecting_force != 0:
			#affecting_force -= sign(affecting_force) * 10
			#if abs(velocity.x) > abs(affecting_force) and abs(affecting_force) > x_speed:
				#velocity.x = affecting_force
			#if abs(affecting_force) <= x_speed and abs(velocity.x) > x_speed:
				#velocity.x = sign(velocity.x) * x_speed
				##velocity.x = sign(velocity.x) * abs(affecting_force)
			
		if is_on_floor() and !Input.is_action_pressed("Jump") and $AnimationPlayer.current_animation != "Land":
			$AnimationPlayer.speed_scale = abs(direction)
		else:
			$AnimationPlayer.speed_scale = 1
	else:
		$AnimationPlayer.speed_scale = 1
		#velocity.x = affecting_force
		#if affecting_force != 0:
			#affecting_force -= sign(affecting_force) * 10
		#velocity.x = move_toward(velocity.x, 0, x_speed/4.0)
		#if is_on_floor() and !Input.is_action_pressed("Jump") and $AnimationPlayer.current_animation != "Land":
		#	$AnimationPlayer.play("Idle")

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
	if is_on_floor(): #remove for fun speedrun strats ig
		can_drop = false
		position.y += 1

#activates the dash ability
func dash(dir: int = last_dir):
	dash_timer = 0
	dash_cooldown += 1
	can_dash = false
	can_jump = false
	dashing = true
	
	if last_dir != dir and dir:
		last_dir = dir
		$Sprite2D.scale.x *= -1
	
	var p = load("res://Particles/dash_particles.tscn").instantiate()
	p.position = position
	p.scale.x = $Sprite2D.scale.x
	p.get_node("Particles").emitting = true
	get_parent().get_room().add_child(p)
	
	get_parent().get_node("Camera").shake(1.5, 0.04, 3)
	get_parent().get_node("Camera").radial_blur(0.02)
	AudioManager.play_audio(sfxs.get_sfx("dash"))
	
	if is_on_floor() or coyote >= 0:
		position.y -= 4
		#can_jump = true
	
	var c = load("res://Particles/speed_circle.tscn").instantiate()
	c.position = position
	c.scale.x = $Sprite2D.scale.x
	get_parent().get_room().add_child(c)

#hanlde the dashing after a dash is activated
func process_dash():
	#if is_on_wall() and dash_timer:
	#	dash_timer = dash_lim
	if dash_timer < dash_lim: #perform dash
		velocity.x = sign(last_dir)*990.0/(dash_timer+1.0)
		velocity.y = 0
		dash_timer += 1
		
	if dash_timer == dash_lim:
		$ParticleComps/DashParticles.emitting = false
		dashing = false
	
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
				walljump_coyote = 5
			can_walljump = true
			can_dash = true
			can_double_jump = true
			if velocity.y >= 50:
				velocity.y = 40
	
	elif can_walljump:
	#if (!is_on_wall_only() or velocity.y <= 0) and can_walljump:
		if walljump_coyote <= 0:
			can_walljump = false
		walljump_coyote -= 1

#jump on walls
func walljump():
	if !walljumping:
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
		respawn()
	elif body.is_in_group("Checkpoint"):
		body.activate()
		bubble_action(false, false)
		get_parent().save_game()
	elif body.is_in_group("Collectable"):
		body.collect()
	#elif body.is_in_group("MovingPlatform"):
	#	print("lol")
	elif body is TileMap:
		custom_data_action(body, body.get_custom_data_with_rid(body_rid), body.get_coords_for_body_rid(body_rid))

#does action based on the custom data of a tile
func custom_data_action(body: TileMap, custom_data: String, tile_coords: Vector2):
	var p_up_name = "None"
	if custom_data == "Spike" or (custom_data == "Water" and !has_freeze):
		respawn()
	elif custom_data == "PBlueBlocks":
		has_blue_blocks = true
		get_parent().add_to_completion_percentage("PowerUp")
		p_up_name = "SkyfishAura"
	elif custom_data == "PWallClimb":
		has_wallclimb = true
		get_parent().add_to_completion_percentage("PowerUp")
		p_up_name = "SpiderGauntlets"
	elif custom_data == "PDash":
		has_dash = true
		get_parent().add_to_completion_percentage("PowerUp")
		p_up_name = "SwiftwindAmulet"
	elif custom_data == "PDoubleJump":
		has_double_jump = true
		get_parent().add_to_completion_percentage("DoubleJump")
		p_up_name = "PegasusBoots"
	elif custom_data == "PFreeze":
		has_freeze = true
		get_parent().get_tilemap().change_water_tiles()
		get_parent().add_to_completion_percentage("Freeze")
		p_up_name = "FreezewakeCharm"
	
	if p_up_name != "None":
		disable_movement(true)
		paused = true
		AudioManager.pause_song()
		self.position = Vector2(tile_coords.x*8+8, tile_coords.y*8+20)
		$ParticleComps/PowerUpParticles/ExplosionParticles.emitting = true
		$ParticleComps/PowerUpParticles/RedRingParticles.emitting = true
		
		get_parent().get_node("Camera").invert_color(0.5, 0.2)
		get_parent().get_node("Camera").zoom_camera(2, 0, position)
		get_parent().get_node("Camera").rotation = PI/56.0
		AudioManager.play_audio(sfxs.get_sfx("power_up"))
		AudioManager.play_audio(sfxs.get_sfx("fire_burst"))
		AudioManager.play_audio(sfxs.get_sfx("explode"))
		get_parent().save_room_state(tile_coords, true)
		body.erase_cell(0, tile_coords)
		if get_parent().get_node("WorldMap").open:
			get_parent().get_node("WorldMap").open_or_close()
		$AnimationPlayer.stop()
		#get_node("/root/World/WorldMap").remove_item()
		
		await get_tree().create_timer(1, false).timeout
		$ParticleComps/PowerUpParticles/ChargeUpParticles.emitting = true
		AudioManager.play_audio(sfxs.get_sfx("charge"))
		
		await get_tree().create_timer(4, false).timeout
		get_parent().get_node("Camera").zoom_camera(1, 0)
		get_parent().get_node("Camera").rotation = 0
		$Sprite2D.material.set_shader_parameter("palette_choice", $Sprite2D.material.get_shader_parameter("palette_choice")+1)
		AudioManager.play_audio(sfxs.get_sfx("p_up_finish"))
		get_node("/root/World/Camera").flash(1, 0, 0.1, 0.4)
		if p_up_name == "SkyfishAura":
			get_parent().change_room(get_parent().room_coords)
		disable_movement(false)
		paused = false
		bubble_action(false, false)
		AudioManager.resume_song()
		await get_tree().create_timer(0.3, false).timeout
		
		get_parent().get_node("Camera").open_p_up_window(p_up_name)

##fade in foreground
#func on_foreground_enter(_area):
	#var tilemap = get_parent().get_tilemap()
	#while tilemap == null:
		#await Engine.get_main_loop().process_frame
	#tilemap.fade_foreground(true)
#
##fade out foreground
#func on_foreground_exit(_area):
	#var tilemap = get_parent().get_tilemap()
	#while tilemap == null:
		#await Engine.get_main_loop().process_frame
	#tilemap.fade_foreground(false)

#replaces water with ice if you have the freeze power up
func on_water_entered(body_rid, body, _body_shape_index, _local_shape_index):
	if body is TileMap and has_freeze:
		var tile_coords = body.get_coords_for_body_rid(body_rid)
		var tile_data = body.get_cell_tile_data(0, tile_coords)
		if tile_data != null:
			var custom_data = tile_data.get_custom_data("Functional Tiles")
			if custom_data == "Water":
				body.erase_cell(0, tile_coords)
				body.set_cell(1, tile_coords, 0, Vector2i(43, 4), 0)
			
				#ice breaks after a short time, not sure if ill keep it in
				#await body.create_tween().tween_interval(0.2).finished
				#body.set_cell(4, tile_coords, 0, Vector2i(43, 5), 0)
				#await body.create_tween().tween_interval(0.2).finished
				#body.set_cell(4, tile_coords, 0, Vector2i(43, 6), 0)
				#await body.create_tween().tween_interval(0.2).finished
				#body.erase_cell(4, tile_coords)

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

func _on_inside_wall(body_rid, body, _body_shape_index, _local_shape_index):
	if (!(body is TileMap) or !body.is_tile_one_way(body_rid)) and !is_dead:
		if is_on_wall():
			pass
		else:
			$Sprite2D.region_rect = Rect2(96, 0, 16, 16)
		respawn(true)
