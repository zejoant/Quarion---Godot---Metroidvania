extends Node

var audioPlayer: AudioStreamPlayer

var previous_song
var previous_song_pos

var respawn_song
var respawn_song_pos

var song_fade_tween: Tween

func _ready():
	audioPlayer = AudioStreamPlayer.new()
	audioPlayer.bus = "Music"
	audioPlayer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(audioPlayer)

func play_audio(stream: AudioStream, speed: float = 1, volume: float = 1, parent = self, start_pos = 0.0, fade_in: = 0.0):
	var sfxPlayer = AudioStreamPlayer.new()
	#sfxPlayer.bus = bus
	sfxPlayer.volume_db = volume*40-40
	sfxPlayer.pitch_scale = speed
	sfxPlayer.bus = "Sfx"
	sfxPlayer.stream = stream
	sfxPlayer.finished.connect(remove_audio_player.bind(sfxPlayer))
	parent.call_deferred("add_child", sfxPlayer)
	#await Engine.get_main_loop().process_frame
	await sfxPlayer.tree_entered
	if parent:
		sfxPlayer.play(start_pos)
		
		if fade_in:
			sfxPlayer.volume_db = -40
			self.create_tween().tween_property(sfxPlayer, "volume_db", volume*40-40, fade_in)

func play_song(stream: AudioStream, playback_pos: float = 0.0, volume: float = 1.0, fade_in: float = 0.0, save_as_prev = true):
	if song_fade_tween:
		song_fade_tween.kill()
	if fade_in:
		audioPlayer.volume_db = linear_to_db(0.001)
		song_fade_tween = self.create_tween()
		song_fade_tween.tween_property(audioPlayer, "volume_db", linear_to_db(volume), fade_in)
	else:
		audioPlayer.volume_db = linear_to_db(volume)
		
	if audioPlayer.has_stream_playback():
		if save_as_prev:
			previous_song = audioPlayer.stream.resource_path
			previous_song_pos = audioPlayer.get_playback_position()
		audioPlayer.stop()
	
	if previous_song == respawn_song: #save respawn song pos if song is changed
		respawn_song_pos = previous_song_pos
		
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

func stop_song(fade: float = 0):
	if fade:
		song_fade_tween = self.create_tween()
		await song_fade_tween.tween_property(audioPlayer, "volume_db", linear_to_db(0.001), fade).finished
	audioPlayer.stop()
	audioPlayer.volume_db = linear_to_db(1)

func resume_previous_song():
	play_song(load(previous_song), previous_song_pos)

func resume_respawn_song():
	if audioPlayer.stream.resource_path == respawn_song:
		respawn_song_pos = audioPlayer.get_playback_position()
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
	
