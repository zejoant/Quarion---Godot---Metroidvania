extends AnimatedSprite2D

func _ready():
	animation_finished.connect(delete_self)
	self.create_tween().tween_property(self, "modulate:a", 0, 0.6)
	var t = self.create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.tween_property(self, "position:x", position.x - 16*scale.x, 1)

func delete_self():
	queue_free()
