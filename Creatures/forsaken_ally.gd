extends Area2D

var player
@onready var boss = $ForsakenAlly

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_node("/root/World/Player")
	var room_states = get_node("/root/World").get_room_state()
	for pos in room_states:
		if Vector2i($ActivateBossColl.position) == Vector2i(pos): #check if boss has been defeated
			queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	if boss.position.x > player.position.x:
		boss.scale.x = 1
	else:
		boss.scale.x = -1
	
	if player.position.x > boss.position.x-8 and player.position.x < boss.position.x+8 and player.position.y < boss.position.y-6:
		$ForsakenAlly/HurtColl.disabled = true
	else:
		$ForsakenAlly/HurtColl.disabled = false


#start boss
func _on_body_entered(_body):
	pass # Replace with function body.

#damage boss
func _on_hit_area_body_entered(body):
	body.bounce(body.jump_vel)
