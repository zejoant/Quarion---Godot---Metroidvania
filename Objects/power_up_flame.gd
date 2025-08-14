extends Area2D

@export var sfxs : AudioLibrary
@export_enum("SkyfishAura", "SpiderGauntlets", "SwiftwindAmulet", "PegasusBoots", "FreezewakeCharm", "PhantomFlame") var type = "SkyfishAura"

@onready var cam = get_node("/root/World/Camera")
@onready var world = get_node("/root/World")

var palette

func _ready():
	for pos in get_node("/root/World").get_room_state():
		if Vector2i(position/8) == Vector2i(pos): #check if boss has been defeated
			queue_free()
			return
	$FlameSprite.play(type)

func _on_collected_by_player(body):
	if type == "SkyfishAura":
		body.has_blue_blocks = true
		world.add_to_completion_percentage("PowerUp")
		palette = 1
	elif type == "SpiderGauntlets":
		body.has_wallclimb = true
		world.add_to_completion_percentage("PowerUp")
		palette = 2
	elif type == "SwiftwindAmulet":
		body.has_dash = true
		world.add_to_completion_percentage("PowerUp")
		palette = 3
	elif type == "PegasusBoots":
		body.has_double_jump = true
		world.add_to_completion_percentage("DoubleJump")
		palette = 4
	elif type == "FreezewakeCharm":
		body.has_freeze = true
		world.get_tilemap().change_water_tiles()
		world.add_to_completion_percentage("Freeze")
		palette = 5
	elif type == "PhantomFlame":
		body.has_phantom_dash = true
		palette = 6
	
	play_animation(body)

func play_animation(body):
	$CollisionShape2D.set_deferred("disabled", true)
	body.disable_movement(true)
	body.paused = true
	AudioManager.pause_song()
	body.position = position
	$FlameSprite.visible = false
	$PowerUpParticles/ExplosionParticles.emitting = true
	$PowerUpParticles/RedRingParticles.emitting = true
	
	if body.get_node("AnimationPlayer").current_animation == "Land":
		body.get_node("AnimationPlayer").play("Jump")
	
	cam.invert_color(0.5, 0.2)
	cam.zoom_camera(2, 0, position)
	cam.rotation = PI/56.0
	AudioManager.play_audio(sfxs.get_sfx("power_up"))
	AudioManager.play_audio(sfxs.get_sfx("fire_burst"))
	AudioManager.play_audio(sfxs.get_sfx("explode"))
	world.save_room_state(position/8, true)
	if world.get_node("WorldMap").open:
		world.get_node("WorldMap").open_or_close()
	body.get_node("AnimationPlayer").stop()
	
	await get_tree().create_timer(1, false).timeout
	$PowerUpParticles/ChargeUpParticles.emitting = true
	AudioManager.play_audio(sfxs.get_sfx("charge"))
	
	await get_tree().create_timer(4, false).timeout
	cam.zoom_camera(1, 0)
	cam.rotation = 0
	body.update_palette(palette)
	AudioManager.play_audio(sfxs.get_sfx("p_up_finish"))
	cam.flash(1, 0, 0.1, 0.4)
	if type == "SkyfishAura":
		world.get_tilemap().check_for_functional_tiles()
	body.disable_movement(false)
	body.paused = false
	body.bubble_action(false, false)
	SteamManager.get_achivement(type)
	AudioManager.resume_song()
	await get_tree().create_timer(0.3, false).timeout
	
	cam.open_p_up_window(type)
	queue_free()
