extends StaticBody2D

@export var sfxs : AudioLibrary
@export var id : int
var opened_doors

#next free id is 8

# Called when the node enters the scene tree for the first time.
func _ready():
	opened_doors = get_node("/root/World").opened_doors
	if opened_doors[id]:
		$ButtonSprite.region_rect = Rect2(32, 104, 16, 8)
		$ClickArea/ButtonClickColl.disabled = true

func _on_click_area_body_entered(_body):
	$AnimationPlayer.play("ButtonClick")
	AudioManager.play_audio(sfxs.get_sfx("click"))
	opened_doors[id] = true
	
	for node in get_parent().get_children():
		if node.name.contains("ButtonDoor") and id == node.id:
			node.open()
