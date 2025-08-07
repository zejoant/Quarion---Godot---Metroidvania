extends Label

var timer: float = 0.0
var stopped: bool = false

var hours
var minutes
var seconds
var milli

func _process(delta):
	if !stopped:
		timer += delta #time in seconds, with 3 decimal places
	if OptionsMenu.speedrun_timer:
		update_time()
		if !visible:
			visible = true
	elif visible:
		visible = false

func update_time():
	hours = timer/3600
	minutes = fmod(timer/60, 60)
	seconds = fmod(timer, 60)
	milli = fmod(timer, 1) * 1000
	
	text = "%02d:%02d:%02d.%03d" % [hours, minutes, seconds, milli]

func stop():
	stopped = true

func resume():
	stopped = false
	
