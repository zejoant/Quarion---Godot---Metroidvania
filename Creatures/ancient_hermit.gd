extends Node2D

static var has_seen_intro = false
@onready var player = get_node("/root/World/Player")
@onready var cam = get_node("/root/World/Camera")
@onready var p = get_parent()

var lev_origin = Vector2(152, 60)

enum BossState {IDLE, LEVITATE}
var boss_state: BossState = BossState.IDLE

var time = 0

var afterimage_texture = preload("res://hermit_afterimage.tscn")
var afterimage_cooldown = 0
var afterimage_active: bool = true

func _ready():
	intro_sequence()

func _physics_process(_delta):
	if boss_state == BossState.LEVITATE:
		position.y = lev_origin.y + cos(float(time)/40.0)*10#*2
		position.x = lev_origin.x + cos(float(time)/32.0)*10#*2
	
	
	if afterimage_active:
		afterimage()
	time += 1

func intro_sequence():
	AudioManager.stop_song()
	player.disable_movement(true)
	$BossSprite.scale.x = -1
	if !has_seen_intro:
		player.paused = true
		cam.fade("000000", 1, 0, 0.2, 0.5)
		has_seen_intro = true
		player.position = Vector2(1, 19*8)
		player.position.x = 1
		player.visible = false
		await get_tree().create_timer(2, false).timeout
		
		player.visible = true
		player.get_node("ParticleComps/DashParticles").lifetime = 0.01
		
		player.paused = false
		player.position.y = 20*8
	
	
	player.position.x = 1
	player.velocity = Vector2(player.x_speed, 0)
	await get_tree().create_timer(0.5, false).timeout
	
	player.velocity.x = 0
	$BossSprite.scale.x = 1
	await get_tree().create_timer(0.8, false).timeout
	#$BossSprite.play("point staff")
	$AnimationPlayer.play("point_staff")
	await get_tree().create_timer(1, false).timeout
	
	$AnimationPlayer.play("teleport_out")
	await get_tree().create_timer(0.21, false).timeout
	
	player.disable_movement(false)
	player.get_node("ParticleComps/DashParticles").lifetime = 3
	p.get_node("Gate").close()
	p.get_node("Gate2").close()
	AudioManager.resume_song()
	AudioManager.play_song(load("res://Music/Everhood_The_Final_Battle.mp3"))
	
	position = lev_origin
	$AnimationPlayer.play("teleport_in")
	await get_tree().create_timer(0.2, false).timeout
	$AnimationPlayer.play("levitate")
	#$BossSprite.play("levitate")
	boss_state = BossState.LEVITATE

func afterimage():
	if !afterimage_cooldown:
		afterimage_cooldown = 2
		var tex = afterimage_texture.instantiate()
		tex.region_rect = $BossSprite.region_rect
		tex.position = position
		tex.scale = $BossSprite.scale
		tex.offset = $BossSprite.offset
		get_parent().add_child(tex)
	else:
		afterimage_cooldown -= 1
