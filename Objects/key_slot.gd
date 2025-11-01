extends Area2D

@export_enum("green", "red", "blue") var color = "green"
@export var sfxs : AudioLibrary
var player
var cam
@onready var world = get_node("/root/World")

var player_in_area: bool = false

var doors_in_room: Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_node("/root/World/Player")
	cam = get_node("/root/World/Camera")
	setup()
	
	for pos in world.get_room_state():
		if Vector2i(position) == Vector2i(pos): #check if door has already been opened
			$Key.visible = true
			$Key.rotation_degrees = 90


func _input(event):
	if player_in_area and event.is_action_pressed("Interact") and !$Key.visible:
		if color == "green" and player.green_key_state == "collected":
			player.green_key_state = "used"
			cam.remove_collected_item(cam.CollectedItem.GREEN_KEY)
			AudioManager.play_audio(sfxs.get_sfx("click"))
			unlock()
		elif color == "red" and player.red_key_state == "collected":
			player.red_key_state = "used"
			cam.remove_collected_item(cam.CollectedItem.RED_KEY)
			AudioManager.play_audio(sfxs.get_sfx("click"))
			unlock()
		elif color == "blue" and player.blue_key_state == "collected":
			player.blue_key_state = "used"
			cam.remove_collected_item(cam.CollectedItem.BLUE_KEY)
			AudioManager.play_audio(sfxs.get_sfx("click"))
			unlock()


func unlock():
	world.save_room_state(position, true) #save state of key slot
	world.temporary_actions_to_permanent()
	
	for node in get_parent().get_children():
		if node.name.contains("KeyDoor") and color == node.color:
			doors_in_room.append(node)
			node.glow()
	
	var tween = self.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	$Key.visible = true
	$Key.scale *= 2
	tween.tween_property($Key, "scale", Vector2(1, 1), 0.1)
	tween.tween_interval(0.2)
	await tween.tween_property($Key, "rotation_degrees", 90, 0.1).finished
	
	for door in doors_in_room:
		door.open()
	#for node in get_parent().get_children():
		#if node.name.contains("KeyDoor") and color == node.color:
			#node.open()

func setup():
	if color == "red":
		$Base.region_rect.position = Vector2(32, 112)
		$Key.region_rect.position.x += 8
	elif color == "blue":
		$Base.region_rect.position.x += 16
		$Key.region_rect.position.x += 16

func _on_body_entered(body):
	if body is CharacterBody2D:
		if color == "green" and body.green_key_state == "collected":
			player_in_area = true
			$InputIndicator.visible = true
		elif color == "red" and body.red_key_state == "collected":
			player_in_area = true
			$InputIndicator.visible = true
		elif color == "blue" and body.blue_key_state == "collected":
			player_in_area = true
			$InputIndicator.visible = true

func _on_body_exited(body):
	if body is CharacterBody2D:
		player_in_area = false
		$InputIndicator.visible = false
