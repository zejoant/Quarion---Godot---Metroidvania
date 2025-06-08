#@tool
extends StaticBody2D

@export var jump_height : int = 5
@export var start_delay : float = 0
var jumping = true
var tween
var top_pos
var start_pos

# Called when the node enters the scene tree for the first time.
func _ready():
	#position = Vector2(0, 0)
	top_pos = position.y-jump_height*8
	start_pos = position.y
	await get_tree().create_timer(start_delay, false).timeout
	jumping = false
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if !jumping:
		jumping = true
		scale.y = 1
		
		tween = self.create_tween() #jump up
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_EXPO)
		tween.tween_property(self, "position:y", top_pos, 1)
		
		tween.set_trans(Tween.TRANS_SINE) #flutter
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(self, "position:y", top_pos+4, 0.8)
		await tween.tween_property(self, "position:y", top_pos, 0.8).finished
		
		scale.y = -1
		tween = self.create_tween()
		tween.set_trans(Tween.TRANS_SINE) #fall down
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(self, "position:y", start_pos, 0.5)
		
		await tween.tween_interval(3).finished
		jumping = false

func is_tile_one_way(_rid: RID) -> bool:
	return false
