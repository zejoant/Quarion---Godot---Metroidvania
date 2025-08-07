extends StaticBody2D

@export var sfxs : AudioLibrary
@export_range(0, 304) var distance: int = 64
@export_range(0, 1) var start_pos: float = 0.5
@export_enum("horizontal", "vertical") var axis = "vertical"
@export_enum("back", "forward") var start_dir = "forward"
@export var time: float = 2
@export_range(-1, 1) var rotation_type: int = 1

var state = 0
var tween1
var dir: Vector2
var origin: Vector2

var last_pos: Vector2

func _ready():
	origin = position
	last_pos = position
	
	if start_dir == "back":
		if axis == "vertical":
			dir = Vector2(0, -1)
		else:
			dir = Vector2(-1, 0)
		if start_pos == 1:
			dir *= -1
	else:
		if axis == "vertical":
			dir = Vector2(0, 1)
		else:
			dir = Vector2(1, 0)
		if start_pos == 0:
			dir *= -1
	
	position = origin + abs(dir) * (distance*start_pos - distance/2.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	if axis == "vertical":
		rotation_degrees += 10 * (last_pos.distance_to(position)) * dir.y * rotation_type
	else:
		rotation_degrees += 10 * (last_pos.distance_to(position)) * dir.x * rotation_type
	last_pos = position
	
	if state == 0:
		state = -1
		if start_pos != 1 and start_pos != 0:
			tween1 = self.create_tween()
			tween1.set_ease(Tween.EASE_OUT)
			tween1.set_trans(Tween.TRANS_SINE)
			if start_dir == "back":
				AudioManager.play_audio(sfxs.get_sfx("spin"), 1/(time*start_pos), 0.7, self)
				await tween1.tween_property(self, "position", origin+dir*distance/2.0, time*start_pos).finished
			else:
				AudioManager.play_audio(sfxs.get_sfx("spin"), 1/(time*(1.0-start_pos)), 0.7, self)
				await tween1.tween_property(self, "position", origin+dir*distance/2.0, time*(1.0-start_pos)).finished
		dir *= -1
		state = 1
	
	if state == 1:
		state = -1
		tween1 = self.create_tween()
		tween1.set_ease(Tween.EASE_IN_OUT)
		tween1.set_trans(Tween.TRANS_SINE)
		AudioManager.play_audio(sfxs.get_sfx("spin"), 1/time, 0.7, self)
		await tween1.tween_property(self, "position", origin + dir * distance/2.0, time).finished
		dir *= -1
		state = 1
		
