#@tool
extends Node2D

@export_enum("green", "blue", "pink", "yellow") var color = "green"
@export_range(0, 5) var start_raise : float = 0
static var killed_suns = 0
var sprite_sheet : Texture2D
var boss : CharacterBody2D
var start_pos : Vector2
var boss_state = -2
var player

var activated = false

var idle_dir : Vector2
var init_move = true
var lunge_state = 0

var x_loop = true
var y_loop = true
var mod = 0.01
var lunge_dir

var tween1
var tween2
var tween3

var time : float = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	#player = get_node("/root/World/Player")
	boss = $StarlightGuardian
	boss.visible = false
	$StarlightGuardian/Aim.modulate.a = 0
	$StarlightGuardian/DamageColl.disabled = true
	param_setup()
	
	
	await self.create_tween().tween_interval(2).finished
	boss_state = -1
	
	await self.create_tween().tween_interval(4).finished
	boss_state = 1
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if activated:
		
		if boss_state == -1: #boss start animations
			boss_state = 0
			
		if mod > 0 and boss_state >= 0: #idle animation
			#idle_loop()
			idle_movement()
			
		if boss_state == 1: #lunge attack
			lunge(delta)
		
func idle_movement():
	boss.position.y = start_pos.y - sin(time)*12.0
	boss.position.x = start_pos.x + sin(time/2.0)*50.0
	
	
	time += 0.08 * mod #progression along the sine wave
	if mod < 1 and boss_state == 0: #ease in movement
		mod += 0.01

#func idle_loop():
	#
	#if mod < 1 and boss_state == 0:
		#mod += 0.01
	#
	#if x_loop:
		#x_loop = false
		#tween1 = self.create_tween()
		#
		#tween1.set_trans(Tween.TRANS_QUAD)
		#tween1.set_ease(Tween.EASE_OUT)
		#tween1.tween_method(idle_move_x,  boss.position.x, boss.position.x+70, 1)
		#tween1.set_ease(Tween.EASE_IN)
		#tween1.tween_method(idle_move_x, boss.position.x, boss.position.x-70, 1)
		#tween1.set_ease(Tween.EASE_OUT)
		#tween1.tween_method(idle_move_x,  boss.position.x, boss.position.x-70, 1)
		#tween1.set_ease(Tween.EASE_IN)
		#await tween1.tween_method(idle_move_x,  boss.position.x, boss.position.x+70, 1).finished
		#x_loop = true
	
	#if y_loop:
		#y_loop = false
		#tween2 = self.create_tween()
		#
		#tween2.set_trans(Tween.TRANS_QUAD)
		#tween2.set_ease(Tween.EASE_OUT)
		#tween2.tween_method(idle_move_y,  start_pos.y, start_pos.y - 20, 0.5)
		#tween2.set_ease(Tween.EASE_IN_OUT)
		#tween2.tween_method(idle_move_y, start_pos.y - 20, start_pos.y + 20, 1)
		#tween2.set_ease(Tween.EASE_IN)
		#await tween2.tween_method(idle_move_y, start_pos.y + 20, start_pos.y, 0.5).finished
		#y_loop = true

#func idle_move_y(destination):
	#boss.position.y += (destination-boss.position.y) * mod
#func idle_move_x(destination):
	#boss.position.x += (destination-boss.position.x) * mod

func lunge(_delta):
	if mod > 0: #ease out idle movement
		mod -= 0.01
	#if mod <= 0: #stop tweens
	#	tween1.kill()
	#	tween2.kill()
	
	if !lunge_state:
		lunge_state = 1
		lunge_dir = player.position.direction_to(boss.position)
		
		tween3 = self.create_tween()
		tween3.parallel().tween_property(boss.get_node("Aim"), "modulate:a", 1, 1)
		tween3.parallel().tween_property(boss, "modulate", Color(0.8, 0.3, 0.3, 1), 1.5)
		#tween3.parallel().tween_property(boss, "position", boss.position + lunge_dir, 1.5)
		#await get_tree().create_timer(1.5).timeout
		#lunge_state = 2
		#lunge_dir = player.position.direction_to(boss.position)*224
		#tween3.stop()
		#tween3.play()
		#tween3.tween_property(boss, "position", boss.position - lunge_dir, 0.8)
	
	
	boss.get_node("Aim").rotation = (player.position - boss.position).angle() - PI/2
	#if lunge_state == 1:
	#	boss.position += lunge_dir
	#
	

func param_setup():
	boss.position.y -= start_raise*8
	start_pos = boss.position
	#start_pos.y -= start_raise*8
	
	
	if color == "green":
		sprite_sheet = load("res://Assets/Sun Boss Green.png")
	elif color == "blue":
		sprite_sheet = load("res://Assets/Sun Boss Blue.png")
	elif color == "pink":
		sprite_sheet = load("res://Assets/Sun Boss Pink.png")
	elif color == "yellow":
		sprite_sheet = load("res://Assets/Sun Boss Yellow.png")
	
	boss.get_node("Base").texture = sprite_sheet
	boss.get_node("Spikes").texture = sprite_sheet
	boss.get_node("Face").texture = sprite_sheet


func _on_body_entered(body):
	$ActivateBossColl.set_deferred("disabled", true)
	boss.get_node("DamageColl").set_deferred("disabled", false)
	
	player = body
	boss.visible = true
	activated = true
	
	$Gate.close()
	$Gate2.close()
	
