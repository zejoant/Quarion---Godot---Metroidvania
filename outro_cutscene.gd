extends Node2D

var jump_count: int = 0
var death_count: int = 0
var completion_time: float = 0
var completion_percentage: float = 0

func _ready():
	$CreditsComp/JumpCount.text = str(jump_count)
	$CreditsComp/DeathCount.text = str(death_count)
	$CreditsComp/CompletionTime.text = time_convert(completion_time)
	$CreditsComp/CompletionPercentage.text = str(int(completion_percentage), "%")
	
	$Camera/LensCircle.follow_player = false
	$Camera/LensCircle.position = Vector2(152, 96)
	#$Camera/LensCircle.size = 8
	$Camera.fade("000000", 1, 0, 0.5, 0.5)
	await get_tree().create_timer(0.5, false).timeout
	$AnimationPlayer.play("Default")

func time_convert(time):
	@warning_ignore("integer_division")
	var hours = (int(time)/60)/60
	@warning_ignore("integer_division")
	var minutes = (int(time)/60)%60
	@warning_ignore("integer_division")
	var seconds = int(time)%60
	var milli = int((time - int(time)) * 1000)
	
	
	#returns a string with the format "HH:MM:SS"
	return "%02d:%02d:%02d.%03d" % [hours, minutes, seconds, milli]
