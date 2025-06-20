extends StaticBody2D

@export_enum("green", "red") var color = "green"
@export var sfxs : AudioLibrary
var player

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_node("/root/World/Player")
	setup()
	
	for pos in get_node("/root/World").get_room_state():
		if Vector2i(position) == Vector2i(pos): #check if door has already been opened
			$Key.visible = true
			$Key.rotation_degrees = 90


func _unhandled_input(event):
	if event.is_action_pressed("UI Up") and !$Key.visible:
		if player.get_node("Area2D").has_overlapping_bodies() and player.get_node("Area2D").get_overlapping_bodies().has(self):
			if color == "green" and player.green_key_state == "collected":
				player.green_key_state = "used"
				get_node("/root/World/Camera").set_keys("Green", true)
				AudioManager.play_audio(sfxs.get_sfx("click"))
				unlock()
			elif color == "red" and player.red_key_state == "collected":
				player.red_key_state = "used"
				get_node("/root/World/Camera").set_keys("Red", true)
				AudioManager.play_audio(sfxs.get_sfx("click"))
				unlock()


func unlock():
	get_node("/root/World").save_room_state(position) #save state of key slot
	var tween = self.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	$Key.visible = true
	$Key.scale *= 2
	tween.tween_property($Key, "scale", Vector2(1, 1), 0.1)
	tween.tween_interval(0.2)
	await tween.tween_property($Key, "rotation_degrees", 90, 0.1).finished
	
	for node in get_parent().get_children():
		if node.name.contains("KeyDoor") and color == node.color:
			node.open()

func setup():
	if color == "red":
		$Base.region_rect.position.x += 16
		$Key.region_rect.position.x += 16

func get_all_children(in_node, array := []):
	array.push_back(in_node)
	for child in in_node.get_children():
		array = get_all_children(child, array)
	return array

#func interactable() -> bool:
	#if color == "green" and player.green_key_state == "collected":
		#return true
	#elif color == "red" and player.red_key_state == "collected":
		#return true
	#return false
