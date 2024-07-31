#@tool
extends Node2D

@export_enum("green", "blue", "pink", "yellow") var color = "green"
@export_range(0, 5) var start_raise : float = 0
static var killed_suns = 0
var sprite_sheet : Texture2D
var boss : CharacterBody2D
var start_pos : Vector2
var boss_state = 0
var player

var activated = false

var x_loop = true
var y_loop = true

var lunging = false
var speed = 0.3
var old_pos

var tween1
var tween2


# Called when the node enters the scene tree for the first time.
func _ready():
	#player = get_node("/root/World/Player")
	#boss = $BossBody
	boss = $Path2D/PathFollow2D/BossBody
	boss.visible = false
	boss.get_node("Aim").modulate.a = 0
	boss.get_node("DamageColl").disabled = true
	#$BossBody/Aim.modulate.a = 0
	#$BossBody/DamageColl.disabled = true
	param_setup()
	
	
	await self.create_tween().tween_interval(5).finished
	boss_state = 1
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if activated:
		
		if boss_state == 0:
			#idle_movement()
			follow_path(delta)
		elif boss_state == 1:
			lunge(delta)
		
func follow_path(delta):
	$Path2D/PathFollow2D.progress_ratio += delta * 0.3
	
func idle_movement():
	old_pos = boss.position
	
	if x_loop:
		x_loop = false
		tween1 = self.create_tween()
		
		tween1.set_ease(Tween.EASE_IN_OUT)
		tween1.set_trans(Tween.TRANS_QUAD)
		tween1.tween_property(boss, "position:x", start_pos.x+70, 2)
		await tween1.tween_property(boss, "position:x", start_pos.x-70, 2).finished
		x_loop = true
	
	if y_loop:
		y_loop = false
		tween2 = self.create_tween()
		
		tween2.set_trans(Tween.TRANS_QUAD)
		tween2.set_ease(Tween.EASE_OUT)
		tween2.tween_property(boss, "position:y", start_pos.y - 20, 0.5)
		tween2.set_ease(Tween.EASE_IN_OUT)
		tween2.tween_property(boss, "position:y", start_pos.y + 20, 1)
		tween2.set_ease(Tween.EASE_IN)
		await tween2.tween_property(boss, "position:y", start_pos.y, 0.5).finished
		y_loop = true

func lunge(delta):
	if !lunging:
		#velocity = boss.position - old_pos
		#velocity = PhysicsServer2D.body_get_state(boss.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY)
		#print(velocity)
		#print(velocity/abs(velocity))
		lunging = true
		#tween1.stop()
		#tween2.stop()
		tween1 = self.create_tween()
		tween1.parallel().tween_property(boss.get_node("Aim"), "modulate:a", 1, 1)
		var dir = player.position - boss.position
		dir = dir/abs(dir)
		#tween1.parallel().tween_property($Path2D, "position", boss.position - dir*32, 2)
		tween1.parallel().tween_property(boss, "modulate", Color(0.8, 0.3, 0.3, 1), 2)
		
	boss.get_node("Aim").rotation = (player.global_position - boss.global_position).angle() - PI/2
	#boss.position += velocity# - velocity/abs(velocity)
	#velocity -= velocity/abs(velocity)*2
	if speed > 0:
		$Path2D/PathFollow2D.progress_ratio += delta * speed
		speed -= 0.003
	else:
		speed = 0
	

func param_setup():
	start_pos = boss.position
	start_pos.y -= start_raise*8
	
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
	
