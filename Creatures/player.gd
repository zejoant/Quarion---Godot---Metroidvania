extends CharacterBody2D

@export_group("Movement Properties")
@export var jump_vel = -235.0
@export var gravity = 13.0 #ProjectSettings.get_setting("physics/2d/default_gravity")
@export var fall_limiter = 230
var coyote = 0
var buffer = 0
var can_jump = false

@export var x_speed = 110.0
var direction
var last_dir = 1

const dash_lim = 9
var dash_timer = dash_lim
var dash_cooldown = 0
var dashing = false
var can_dash = true

var can_walljump = false
var walljumping = false
var walljump_timer = 0
var walljump_coyote = 0
var walljump_dir = 1

var can_double_jump = false

@export_group("Power-Ups")
@export var has_dash = false
@export var has_wallclimb = false
@export var has_double_jump = false
@export var has_freeze = false
@export var has_blue_blocks = false

@export_group("Items")
@export var has_green_key = false
@export var has_red_key = false
@export_enum("0", "1", "2", "3") var amulet_pieces = "0"
@export var has_shop_fast_travel = false
@export var has_item_map = false
@export var has_bubble = false


@onready var audio_player = $PolyphonicAudioPlayer

func _ready():
	velocity.y = 200
	
func _physics_process(_delta):
	if is_on_floor():
		if $AnimationPlayer.is_playing() and ($AnimationPlayer.current_animation == "Fall" or $AnimationPlayer.current_animation == ""):
			$AnimationPlayer.play("Land")
			audio_player.play_sound_effect("land")
		velocity.y = 0
		coyote = 5
		can_dash = true
		can_double_jump = true
	
	#applies gravity if in air
	elif !is_on_floor():
		get_parent().get_node("Camera").close_map()
		velocity.y += gravity
		coyote -= 1
		if velocity.y > fall_limiter:
			velocity.y = fall_limiter
		if velocity.y >= 0 and dash_timer == dash_lim and !can_walljump:
			$AnimationPlayer.play("Fall")
	
	
	#enables jumping
	if (!dashing and buffer == 0) and (is_on_floor() or (coyote >= 0 and velocity.y >= 0)):
		can_jump = true
	
	#disables jumping
	elif coyote < 0:
		can_jump = false
	
	#cooldown for dash
	if dash_cooldown != 0:
			dash_cooldown += 1
			if dash_cooldown == 30:
				dash_cooldown = 0
	
	
	wallslide_check()
	
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
		get_parent().get_node("Camera").alternate_map()
	if Input.is_action_just_pressed("Quick Respawn"):
		get_parent().respawn_player()
	
	move_and_slide()
	
	#if get_slide_collision(0) != null:
	#	print(get_slide_collision(0).get_collider())
	
	if Input.is_action_just_pressed("Debug"):
		has_dash = true
		has_blue_blocks = true
		has_double_jump = true
		has_freeze = true
		has_wallclimb = true


#Handle the jump
func jump():
	velocity.y = jump_vel
	buffer = 1
	can_jump = false
	$AnimationPlayer.play("Jump")
	audio_player.play_sound_effect("jump")


# Gets the input direction and handles the movement.
func walk():
	direction = Input.get_axis("Left", "Right")
	if direction:
		if last_dir != direction:
			scale.x = -1
		last_dir = direction
		velocity.x = direction * x_speed
		if is_on_floor() and !Input.is_action_pressed("Jump") and $AnimationPlayer.current_animation != "Land":
			$AnimationPlayer.play("Walk")
	
	else:
		velocity.x = move_toward(velocity.x, 0, x_speed)
		if is_on_floor() and !Input.is_action_pressed("Jump") and $AnimationPlayer.current_animation != "Land":
			$AnimationPlayer.play("Idle")


#drop through platforms
func drop():
	self.position = Vector2(position.x, position.y + 1)


#activates the dash ability
func dash():
	dash_timer = 0
	dash_cooldown += 1
	can_dash = false
	can_jump = false
	dashing = true
	#$WaterDetector/DashColl.disabled = false
	
	$CPUParticles2D.restart()
	$CPUParticles2D.emitting = true
	get_parent().get_node("Camera").flash(0.3, 0, 0, 0.4)
	get_parent().get_node("Camera").radial_blur()
	$AnimationPlayer.play("Dash")
	audio_player.play_sound_effect("dash")
	
	if is_on_floor() or coyote >= 0:
		position.y -= 4


#hanlde the dashing after a dash is activated
func process_dash():
	if dash_timer < dash_lim: #perform dash
		velocity.x = last_dir*1900/((dash_timer+1)*2)
		velocity.y = 0
		dash_timer += 1
	if is_on_wall():
		dash_timer = dash_lim
	if dash_timer == dash_lim:
		$CPUParticles2D.emitting = false
		dashing = false

func wallslide_check():
	if $WallRay.is_colliding() and has_wallclimb and (direction != 0 or can_walljump) and !is_on_floor():
		if !can_walljump:
			walljump_dir = direction
			walljump_coyote = 5
		can_walljump = true
		can_dash = true
		can_double_jump = true
		$AnimationPlayer.play("WallSlide")
		if velocity.y >= 50:
			velocity.y = 40
			
	
	if (!$WallRay.is_colliding() or velocity.y <= 0) and can_walljump:
		if walljump_coyote <= 0:
			can_walljump = false
			#$AnimationPlayer.stop()
			#$AnimationPlayer.play("Jump")
		walljump_coyote -= 1


func walljump():
	if !walljumping:
		walljumping = true
		can_walljump = false
		walljump_timer = 0
		velocity.x = 110.0 * -walljump_dir
		jump()
	elif walljumping and walljump_timer < 7:
		velocity.x = x_speed * -walljump_dir
		walljump_timer += 1
	
	if walljump_timer == 7:
		walljumping = false


#activates if the player entered a body
func _on_area_2d_body_entered(body):
	if body.is_in_group("Enemy"):#kills player
		get_parent().respawn_player()
	elif body.is_in_group("Checkpoint"):
		body.activate()
		get_parent().save_game()
	elif body.is_in_group("Collectable"):
		body.collect()
		audio_player.play_sound_effect("collect")
	elif body.is_in_group("MovingPlatform"):
		print("lol")
	#elif body.is_in_group("Crumble"):
	#	body.crumble()

#activates if player enters a body. Also provieds the body_rid which can give you the tile coords of the body
func _on_area_2d_body_shape_entered(body_rid, body, _body_shape_index, _local_shape_index):
	if body is TileMap:
		custom_data_action(body, body.get_coords_for_body_rid(body_rid))


#does action based on the custom data of a tile
func custom_data_action(body, tile_coords):
	var tile_data = body.get_cell_tile_data(0, tile_coords)
	if tile_data is TileData:
		var custom_data = tile_data.get_custom_data("Functional Tiles")
	
		if custom_data == "Spike" or custom_data == "Water":
			get_parent().respawn_player()
		elif custom_data == "PBlueBlocks":
			#body.blue_block = true
			has_blue_blocks = true
			get_parent().save_room_state(tile_coords)
			#body.erased_cells.append(tile_coords)
			body.erase_cell(0, tile_coords)
			get_parent().change_room(get_parent().room_coords)
		elif custom_data == "PWallClimb":
			has_wallclimb = true
			get_parent().save_room_state(tile_coords)
			#body.erased_cells.append(tile_coords)
			body.erase_cell(0, tile_coords)
		elif custom_data == "PDash":
			has_dash = true
			get_parent().save_room_state(tile_coords)
			#body.erased_cells.append(tile_coords)
			body.erase_cell(0, tile_coords)
		elif custom_data == "PDoubleJump":
			has_double_jump = true
			get_parent().save_room_state(tile_coords)
			#body.erased_cells.append(tile_coords)
			body.erase_cell(0, tile_coords)
		else:
			printerr("tile function not added yet")


#fade out and out foreground
func _on_area_2d_area_entered(_area):
	get_parent().get_tilemap().fade_foreground(true)
func _on_area_2d_area_exited(_area):
	get_parent().get_tilemap().fade_foreground(false)

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
			
