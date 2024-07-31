extends AudioStreamPlayer2D

@export var audio_library: AudioLibrary
@export var max_streams: int = 32

# Called when the node enters the scene tree for the first time.
func _ready():
	stream = AudioStreamPolyphonic.new()
	stream.polyphony = max_streams

func play_sound_effect(_tag: String) -> void:
	if _tag:
		var audio_stream = audio_library.get_audio_stream(_tag)
		
		if !playing:
			self.play()
		
		var polyphonic_stream_playback := self.get_stream_playback()
		polyphonic_stream_playback.play_stream(audio_stream)
	else:
		printerr("no tag found")
			
