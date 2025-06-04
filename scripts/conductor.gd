extends Node
class_name Conductor

# The heart of the rhythm game! Thanks to fizzd (A Dance of Ice and Fire, https://web.archive.org/web/20190317082117/http://ludumdare.com/compo/2014/09/09/an-ld48-rhythm-game-part-2/)
# and Godot docs (https://docs.godotengine.org/en/stable/tutorials/audio/sync_with_audio.html)
# for making guidance and knowledge.

# Warning: Doesn't work for web export in Godot 4.3.

@export var beats_per_minute:float
var crotchet:float = 60 / beats_per_minute
var song_position:float
var song_position_beat:float

# Copyrighted songs won't be available in the open-sourced version
#@export var easy_song_80:AudioStream
#@export var medium_song_115:AudioStream
#@export var hard_song_122:AudioStream
#@export var disco_115:AudioStream
# But you can use my tutorial song to get started.
@export var tutorial_song_120:AudioStream
@export var music_player:AudioStreamPlayer

signal on_beat 			# Fires on every beat
signal on_new_measure   # Fires every 4th beat, on the 1st beat of a measure
signal on_beat_2		# Fires every 4th beat, on the 2nd beat of a measure
signal on_beat_3		# Fires every 4th beat, on the 3rd beat of a measure
signal on_beat_4		# Fires every 4th beat, on the 4th beat of a measure
signal close_out_beat	# Fires when the game starts counting a new beat
signal half_beat		# Fires when we are halfway between beats.

# For processing player input, things "officially" move to the next beat on close_out_beat.
# That occurs when we are 25% of the way to the next beat.

### stuff related to https://github.com/godotengine/godot/issues/105397. Code by PizzaLovers007
var cached_latency:float = AudioServer.get_output_latency()
var prev_song_position:float = 0
var last_playback_time:float = 0

func _ready() -> void:
	crotchet = 60.0 / beats_per_minute

func start_tutorial_music():
	music_player.stream = tutorial_song_120
	beats_per_minute = 120
	crotchet = 60.0 / beats_per_minute
	music_player.play()
	

func start_music():
	#var song_roll = randi_range(0, 3)
	#match song_roll:
		#0:
			#music_player.stream = easy_song_80
			#beats_per_minute = 80
		#1: 
			#music_player.stream = medium_song_115
			#beats_per_minute = 115
		#2: 
			#music_player.stream = hard_song_122
			#beats_per_minute = 122
		#3:
			#music_player.stream = disco_115
			#beats_per_minute = 115
			
	# For the open-sourcing, only my music can be included.
	music_player.stream = tutorial_song_120
	beats_per_minute = 120		
	
	# Option to test things out at a slower pace
	#music_player.stream = tutorial_song_120
	#beats_per_minute = 60 or 30		
			
	crotchet = 60.0 / beats_per_minute
	music_player.play()

func _physics_process(delta: float) -> void:
	var prev_beat = song_position_beat
	var prev_sub_beat = song_position_sub_beat()
	
	song_position = music_player.get_playback_position()
	if song_position != prev_song_position:
		prev_song_position = song_position
		last_playback_time = Time.get_ticks_msec()
	song_position += (Time.get_ticks_msec() - last_playback_time) / 1000 - cached_latency
	
	# Code works for non-web builds, see issue 105397 linked above
	#song_position = music_player.get_playback_position() + AudioServer.get_time_since_last_mix()
	#song_position -= AudioServer.get_output_latency()
	
	song_position_beat = int(floor(song_position / crotchet))
	
	if song_position_beat > prev_beat:
		on_beat.emit()
		if int(song_position_beat) % 4 == 0:
			on_new_measure.emit()
		elif int(song_position_beat) % 4 == 1:
			on_beat_2.emit()
		elif int(song_position_beat) % 4 == 2:
			on_beat_3.emit()
		elif int(song_position_beat) % 4 == 3:
			on_beat_4.emit()
	
	var sub_beat = song_position_sub_beat()
	if prev_sub_beat <= 0.25 && sub_beat > 0.25:
		close_out_beat.emit()
	if prev_sub_beat <= 0.5 && sub_beat > 0.5:
		half_beat.emit()


func song_position_sub_beat() -> float:
	return (song_position / crotchet) - song_position_beat
	


func _on_music_player_finished() -> void:
	music_player.play()
	song_position = 0
	song_position_beat = 0
