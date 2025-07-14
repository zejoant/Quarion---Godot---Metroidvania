extends Node

var audioPlayer

var previous_song
var previous_song_pos

var respawn_song
var respawn_song_pos

func play_audio(stream: AudioStream, speed: float = 1):
	var sfxPlayer = AudioStreamPlayer.new()
	sfxPlayer.pitch_scale = speed
	sfxPlayer.bus = "Sfx"
	sfxPlayer.stream = stream
	sfxPlayer.finished.connect(remove_audio_player.bind(sfxPlayer))
	add_child(sfxPlayer)
	sfxPlayer.play()

#func play_song(stream: AudioStream):
	#var audioPlayer = AudioStreamPlayer.new()
	#audioPlayer.bus = "Music"
	#audioPlayer.stream = stream
	#audioPlayer.finished.connect(remove_audio_player.bind(audioPlayer))
	#add_child(audioPlayer)
	#audioPlayer.play()

func play_song(stream: AudioStream, playback_pos: float = 0.0):
	if !audioPlayer:
		audioPlayer = AudioStreamPlayer.new()
		audioPlayer.bus = "Music"
		add_child(audioPlayer)
		
	if audioPlayer.has_stream_playback():
		previous_song = audioPlayer.stream.resource_path
		previous_song_pos = audioPlayer.get_playback_position()
		audioPlayer.stop()
		
	audioPlayer.stream = stream
	#audioPlayer.finished.connect(remove_audio_player.bind(audioPlayer))
	audioPlayer.play(playback_pos)

func remove_audio_player(instance: AudioStreamPlayer):
	instance.queue_free()

func pause_song():
	if audioPlayer.has_stream_playback():
		audioPlayer.stream_paused = true

func resume_song():
	if audioPlayer.has_stream_playback():
		audioPlayer.stream_paused = false

func stop_song():
	audioPlayer.stop()

func resume_previous_song():
	play_song(load(previous_song), previous_song_pos)
	#var temp_path = audioPlayer.stream.resource_path
	#var temp_pos = audioPlayer.get_playback_position()
	#
	#audioPlayer.stream = load(previous_song)
	#audioPlayer.play(previous_song_pos)
	#
	#previous_song = temp_path
	#previous_song_pos = temp_pos

func resume_respawn_song():
	audioPlayer.stream = load(respawn_song)
	audioPlayer.play(respawn_song_pos)

func save_respawn_song():
	respawn_song = audioPlayer.stream.resource_path
	respawn_song_pos = audioPlayer.get_playback_position()
	
