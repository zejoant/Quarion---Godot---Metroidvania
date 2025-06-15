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

#var in_interact_area = false
var after_red_boss: bool = false
var update_animations = true
var can_move = true
var is_dead = false
var can_die = true
var paused = false

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
#endregion

func _ready():
	velocity.y = 200
	
	await Engine.get_main_loop().process_frame
	if has_blue_blocks:
		$Sprite2D.material.set_shader_parameter("palette_choice", 1)
	if has_dash:
		$Sprite2D.material.set_shader_parameter("palette_choice", 2)
	if has_wallclimb:
		$Sprite2D.material.set_shader_parameter("palette_choice", 3)
	if has_double_jump:
		$Sprite2D.material.set_shader_parameter("palette_choice", 4)
	if has_freeze:
		$Sprite2D.material.set_shader_parameter("palette_choice", 5)
	else:
		$Sprite2D.material.set_shader_parameter("palette_choice", 0)
	
#runs every frame
func _physics_process(_delta):
	if !is_dead and !paused:
		if is_on_floor():
			coyote = 5
			can_dash = true
			can_double_jump = true
			if $CollissionRays/CeilingRay.is_colliding():
				if !($CollissionRays/CeilingRay.get_collider() is TileMap):
					respawn()
				elif !$CollissionRays/CeilingRay.get_collider().is_tile_one_way($CollissionRays/CeilingRay.get_collider_rid()):
					respawn()
		elif !is_on_floor():#applies gravity if in air
			if get_parent().get_node("WorldMap").open:
				get_parent().get_node("WorldMap").open_or_close()
			velocity.y += gravity
			coyote -= 1
			if velocity.y > fall_limiter:
				velocity.y = fall_limiter
		
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
		wallslide_check()
		check_inputs()
		move_and_slide()

#checks all player inputs
func check_inputs():
	if Input.is_action_just_pressed("Quick Respawn") and can_move and !after_red_boss:
		respawn()
	if Input.is_action_just_pressed("Debug"):
		has_dash = true
		has_blue_blocks = true
		has_double_jump = true
		has_freeze = true
		has_wallclimb = true
		update_apple_count(9999, true)
		has_item_map = true
		get_parent().get_node("WorldMap/MapComps/ItemMap").visible = true
		#green_key_state = "collected"
		#red_key_state = "collected"
	
	if !can_move:
		return
	if Input.is_action_just_released("Jump"):
		buffer = 0 #reset jump buffer
		if velocity.y <= jump_vel / 4.0:
			velocity.y = jump_vel / 4.0
	if Input.is_action_just_pressed("Jump") and can_double_jump and has_double_jump and coyote < 0 and !can_walljump:
		can_double_jump = false
		jump()
	if Input.is_action_pressed("Jump") and can_jump:
		jump()
	if (Input.is_action_just_pressed("Jump") and can_walljump) or walljumping:
		walljump()
	if Input.is_action_just_pressed("Drop"):
		drop()
	if Input.is_action_just_pressed("Dash") and can_dash and !dash_cooldown and !can_walljump and has_dash:
		dash()
	if dashing:
		process_dash()
	elif !walljumping:
		walk()
	if Input.is_action_just_pressed("Map") and is_on_floor():
		#get_parent().get_node("Camera").alternate_map()
		get_parent().get_node("WorldMap").open_or_close()

#handles all sprite animations of the player
func animate_player():
	if !update_animations:
		return
	if !dashing:
		if is_on_floor():
			if $AnimationPlayer.current_animation == "Fall" and $AnimationPlayer.current_animation != "Land":
				$ParticleComps/LandParticles.restart()
				$AnimationPlayer.play("Land")
				AudioManager.play_audio(sfxs.get_sfx("land"))
			elif $AnimationPlayer.current_animation != "Land":
				if (velocity.x == 0 or is_on_wall()) and $AnimationPlayer.current_animation != "Idle":
					$AnimationPlayer.play("Idle")
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

#death and respawning
func respawn():
	if !is_dead and can_die:
		var world = get_node("/root/World")
		get_node("/root/World/MusicPlayer").stop()
		is_dead = true
		modulate.g = 0.4
		$AnimationPlayer.play("Damage")
		world.get_node("Camera").invert_color(1, 0.3)
		world.get_node("Camera").shake(5, 0.05, 3)
		AudioManager.play_audio(sfxs.get_sfx("death"))
		
		await get_tree().create_timer(0.5, false).timeout
		$Sprite2D.visible = false
		modulate.g = 1
		$ParticleComps/DeathParticles/RingExplosionParticles.emitting = true
		$ParticleComps/DeathParticles/PixelExplosionParticles.emitting = true
		AudioManager.play_audio(sfxs.get_sfx("explode"))
		
		await get_tree().create_timer(1.4, false).timeout
		world.get_node("Camera").flash(1, 0, 0.2, 0.3)
		velocity = Vector2(0, 0)
		dashing = false
		dash_timer = dash_lim
		world.resume_respawn_music()
		world.return_to_checkpoint()
		$Sprite2D.visible = true
		is_dead = false
		can_jump = true
		can_move = true

#bounce on certain enemies
func bounce(strength):
	if !is_dead:
		can_dash = true
		velocity.y = strength
		move_and_slide()
		can_jump = false
		#$AnimationPlayer.play("Jump")

#Handle the jump
func jump():
	velocity.y = jump_vel
	buffer = 1
	can_jump = false
	#$AnimationPlayer.play("Jump")
	AudioManager.play_audio(sfxs.get_sfx("jump"))

# Gets the input direction and handles the movement.
func walk():
	direction = Input.get_axis("Left", "Right")
	if direction:
		if last_dir * direction < 0:
			scale.x = -1
		if abs(direction) < 0.5:
			direction = sign(direction) * 0.5
		last_dir = direction
		velocity.x = direction * x_speed
		if is_on_floor() and !Input.is_action_pressed("Jump") and $AnimationPlayer.current_animation != "Land":
			$AnimationPlayer.speed_scale = abs(direction)
			#$AnimationPlayer.play("Walk")
		else:
			$AnimationPlayer.speed_scale = 1
	else:
		$AnimationPlayer.speed_scale = 1
		velocity.x = 0
		#velocity.x = move_toward(velocity.x, 0, x_speed/4.0)
		#if is_on_floor() and !Input.is_action_pressed("Jump") and $AnimationPlayer.current_animation != "Land":
		#	$AnimationPlayer.play("Idle")

#drop through platforms
func drop():
	if is_on_floor(): #remove for fun speedrun strats ig
		position.y += 1

#activates the dash ability
func dash():
	dash_timer = 0
	dash_cooldown += 1
	can_dash = false
	can_jump = false
	dashing = true
	#$WaterDetector/DashColl.disabled = false
	
	$ParticleComps/DashParticles.restart()
	$ParticleComps/DashParticles.emitting = true
	get_parent().get_node("Camera").flash(0.3, 0, 0, 0.4)
	get_parent().get_node("Camera").radial_blur()
	AudioManager.play_audio(sfxs.get_sfx("dash"))
	
	if is_on_floor() or coyote >= 0:
		position.y -= 4
	
	#velocity = Vector2(sign(last_dir)*950/(dash_timer+1), 0)
	#var tween = self.create_tween()
	#tween.set_ease(Tween.EASE_OUT)
	#tween.set_trans(Tween.TRANS_EXPO)
	#await tween.tween_property(self, "position:x", position.x + sign(last_dir)*8*6, 0.2).finished
	#await get_tree().create_timer(9.0/60.0, false).timeout
	#$ParticleComps/DashParticles.emitting = false
	#dashing = false

#hanlde the dashing after a dash is activated
func process_dash():
	if dash_timer < dash_lim: #perform dash
		velocity.x = sign(last_dir)*990.0/(dash_timer+1.0)
		velocity.y = 0
		dash_timer += 1
	if is_on_wall():
		dash_timer = dash_lim
	if dash_timer == dash_lim:
		$ParticleComps/DashParticles.emitting = false
		dashing = false

#checks if you are against a wall
func wallslide_check():
	if %WallRay.is_colliding() and has_wallclimb and (direction != 0 or can_walljump) and !is_on_floor() and velocity.y >= 0:
		if (%WallRay.get_collider() is TileMap and !%WallRay.get_collider().is_tile_one_way(%WallRay.get_collider_rid())) or !(%WallRay.get_collider() is TileMap):
			if !can_walljump:
				walljump_dir = direction
				walljump_coyote = 5
			can_walljump = true
			can_dash = true
			can_double_jump = true
			#$AnimationPlayer.play("WallSlide")
			if velocity.y >= 50:
				velocity.y = 40
	
	if (!%WallRay.is_colliding() or velocity.y <= 0) and can_walljump:
		if walljump_coyote <= 0:
			can_walljump = false
		walljump_coyote -= 1

#jump on walls
func walljump():
	if !walljumping:
		walljumping = true
		can_walljump = false
		#walljump_timer = 0
		velocity.x = x_speed * -walljump_dir
		jump()
		await get_tree().create_timer(7.0/60.0, false).timeout
		walljumping = false
	#elif walljumping and walljump_timer < 7:
		#velocity.x = x_speed * -walljump_dir
		#walljump_timer += 1
	#
	#if walljump_timer == 7:
		#walljumping = false

#activates if player enters a body. Also provieds the body_rid which can give you the tile coords of the body
func _on_area_2d_body_shape_entered(body_rid, body, _body_shape_index, _local_shape_index):
	if body.is_in_group("Enemy"):#kills player
		respawn()
	elif body.is_in_group("Checkpoint"):
		body.activate()
		get_parent().save_game()
	elif body.is_in_group("Collectable"):
		body.collect()
	elif body.is_in_group("MovingPlatform"):
		print("lol")
	elif body is TileMap:
		custom_data_action(body, body.get_custom_data_with_rid(body_rid), body.get_coords_for_body_rid(body_rid))

#does action based on the custom data of a tile
func custom_data_action(body: TileMap, custom_data: String, tile_coords: Vector2):
		if custom_data == "Spike" or custom_data == "Water":
			respawn()
		elif custom_data == "PBlueBlocks":
			has_blue_blocks = true
		elif custom_data == "PWallClimb":
			has_wallclimb = true
		elif custom_data == "PDash":
			has_dash = true
		elif custom_data == "PDoubleJump":
			has_double_jump = true
		
		if custom_data.begins_with("P"):
			can_move = false
			paused = true
			get_node("/root/World/MusicPlayer").stream_paused = true
			self.position = Vector2(tile_coords.x*8+8, tile_coords.y*8+20)
			$ParticleComps/PowerUpParticles.emitting = true
			AudioManager.play_audio(sfxs.get_sfx("power_up"))
			AudioManager.play_audio(sfxs.get_sfx("fire_burst"))
			get_parent().save_room_state(tile_coords)
			body.erase_cell(0, tile_coords)
			if get_parent().get_node("WorldMap").open:
				get_parent().get_node("WorldMap").open_or_close()
			$AnimationPlayer.stop()
			#get_node("/root/World/WorldMap").remove_item()
			
			await create_tween().tween_interval(2).finished
			$Sprite2D.material.set_shader_parameter("palette_choice", $Sprite2D.material.get_shader_parameter("palette_choice")+1)
			AudioManager.play_audio(sfxs.get_sfx("p_up_finish"))
			get_node("/root/World/Camera").flash(1, 0, 0.1, 0.4)
			if custom_data == "PBlueBlocks":
				get_parent().change_room(get_parent().room_coords)
			can_move = true
			paused = false
			get_node("/root/World/MusicPlayer").stream_paused = false

#fade in foreground
func on_foreground_enter(_area):
	var tilemap = get_parent().get_tilemap()
	while tilemap == null:
		await Engine.get_main_loop().process_frame
	tilemap.fade_foreground(true)

#fade out foreground
func on_foreground_exit(_area):
	var tilemap = get_parent().get_tilemap()
	while tilemap == null:
		await Engine.get_main_loop().process_frame
	tilemap.fade_foreground(false)

#replaces water with ice if you have the freeze power up
func _on_water_detector_body_shape_entered(body_rid, body, _body_shape_index, _local_shape_index):
	if body is TileMap and has_freeze:
		var tile_coords = body.get_coords_for_body_rid(body_rid)
		var tile_data = body.get_cell_tile_data(0, tile_coords)
		if tile_data != null:
			var custom_data = tile_data.get_custom_data("Functional Tiles")
			if custom_data == "Water":
				if dashing: #avoids getting stuck inside the ice
					position.x = tile_coords.x*8 - 16*last_dir
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
		dash_timer = dash_lim
		can_move = !disable
		velocity = Vector2(0, 0)
		#if is_on_floor() and !Input.is_action_pressed("Jump") and $AnimationPlayer.current_animation != "Land":
		#	$AnimationPlayer.play("Idle")
	else:
		can_move = !disable

#updates apple count when collecting apples and buying from shop
func update_apple_count(value: int, override: bool = false):
	if override:
		apple_count = value
	else:
		apple_count += value
	get_node("/root/World/Camera").update_apple_count(apple_count)
