extends Node

func play_audio(stream: AudioStream):
	var audioPlayer = AudioStreamPlayer.new()
	audioPlayer.stream = stream
	audioPlayer.finished.connect(remove_audio_player.bind(audioPlayer))
	add_child(audioPlayer)
	audioPlayer.play()

func remove_audio_player(instance: AudioStreamPlayer):
	instance.queue_free()
	
