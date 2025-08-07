extends Node

var audioPlayer

var previous_song
var previous_song_pos

var respawn_song
var respawn_song_pos

func _ready():
	audioPlayer = AudioStreamPlayer.new()
	audioPlayer.bus = "Music"
	audioPlayer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(audioPlayer)

func play_audio(stream: AudioStream, speed: float = 1, volume: float = 1, parent = self):
	var sfxPlayer = AudioStreamPlayer.new()
	sfxPlayer.volume_db = volume*40-40
	sfxPlayer.pitch_scale = speed
	sfxPlayer.bus = "Sfx"
	sfxPlayer.stream = stream
	sfxPlayer.finished.connect(remove_audio_player.bind(sfxPlayer))
	parent.call_deferred("add_child", sfxPlayer)
	await Engine.get_main_loop().process_frame
	sfxPlayer.play()

func play_song(stream: AudioStream, playback_pos: float = 0.0):
	#if !audioPlayer:
		#audioPlayer = AudioStreamPlayer.new()
		#audioPlayer.bus = "Music"
		#audioPlayer.process_mode = Node.PROCESS_MODE_ALWAYS
		#add_child(audioPlayer)
		
	if audioPlayer.has_stream_playback():
		previous_song = audioPlayer.stream.resource_path
		previous_song_pos = audioPlayer.get_playback_position()
		audioPlayer.stop()
		
	audioPlayer.stream = stream
	audioPlayer.play(playback_pos)

func remove_audio_player(instance: AudioStreamPlayer):
	instance.queue_free()

func pause_song():
	if audioPlayer and audioPlayer.has_stream_playback():
		audioPlayer.stream_paused = true

func resume_song():
	if audioPlayer and audioPlayer.has_stream_playback():
		audioPlayer.stream_paused = false

func stop_song():
	audioPlayer.stop()

func resume_previous_song():
	play_song(load(previous_song), previous_song_pos)

func resume_respawn_song():
	audioPlayer.stream = load(respawn_song)
	audioPlayer.play(respawn_song_pos)

func save_respawn_song():
	respawn_song = audioPlayer.stream.resource_path
	respawn_song_pos = audioPlayer.get_playback_position()

func set_speed(speed: float):
	audioPlayer.pitch_scale = speed

func fade_out_song(time: float = 0.3):
	self.create_tween().tween_property(audioPlayer, "volume_db", -40, time)

func fade_in_song(time: float = 0.3):
	self.create_tween().tween_property(audioPlayer, "volume_db", 0, time)
	
