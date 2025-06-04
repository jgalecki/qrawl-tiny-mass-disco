extends Node
class_name TitleScreen

# UI is simple enough that instead of buttons, I just use three sprites.
# Lol.

@export var conductor:Conductor
@export var sound_player:SoundPlayer

@export var title_1:Texture2D
@export var title_2:Texture2D

# Tutorials are also sprites. Just a sequence of some thirty of them.

@export var tutorial_1:Texture2D
@export var tutorial_2:Texture2D
@export var tutorial_3:Texture2D
@export var tutorial_4:Texture2D
@export var tutorial_5:Texture2D
@export var tutorial_6:Texture2D
@export var tutorial_7:Texture2D
@export var tutorial_8:Texture2D
@export var tutorial_9:Texture2D
@export var tutorial_10:Texture2D
@export var tutorial_11:Texture2D
@export var tutorial_12:Texture2D
@export var tutorial_13:Texture2D
@export var tutorial_14:Texture2D
@export var tutorial_15:Texture2D
@export var tutorial_16:Texture2D
@export var tutorial_17:Texture2D
@export var tutorial_18:Texture2D
@export var tutorial_19:Texture2D
@export var tutorial_20:Texture2D
@export var tutorial_21:Texture2D
@export var tutorial_22:Texture2D
@export var tutorial_23:Texture2D
@export var tutorial_24:Texture2D
@export var tutorial_25:Texture2D
@export var tutorial_26:Texture2D
@export var tutorial_27:Texture2D
@export var tutorial_28:Texture2D
@export var tutorial_29:Texture2D
@export var tutorial_30:Texture2D
@export var tutorial_31:Texture2D
@export var tutorial_32:Texture2D
@export var tutorial_33:Texture2D
@export var tutorial_34:Texture2D
@export var tutorial_35:Texture2D
@export var tutorial_36:Texture2D
@export var tutorial_37:Texture2D
@export var tutorial_38:Texture2D
@export var tutorial_39:Texture2D
@export var tutorial_40:Texture2D
@export var tutorial_41:Texture2D

@export var credits:Texture

@export var screen:TextureRect

var title_index:int
var showing_tutorial:bool
var tutorial_index:int
var tutorial_pictures:Array[Texture2D]

func _ready():
	conductor.start_tutorial_music()
	title_index = 0
	showing_tutorial = false
	tutorial_index = 0
	tutorial_pictures = [ tutorial_1, tutorial_2, tutorial_3, tutorial_4,
		tutorial_5, tutorial_6, tutorial_7, tutorial_8, tutorial_9, tutorial_10,
		tutorial_11, tutorial_12, tutorial_13, tutorial_14, tutorial_15,
		tutorial_16, tutorial_17, tutorial_18, tutorial_19, tutorial_20,
		tutorial_21, tutorial_22, tutorial_23, tutorial_24, tutorial_25,
		tutorial_26, tutorial_27, tutorial_28, tutorial_29, tutorial_30,
		tutorial_31, tutorial_32, tutorial_33, tutorial_34, tutorial_35,
		tutorial_36, tutorial_37, tutorial_38, tutorial_39, tutorial_40,
		tutorial_41  ]

func _process(delta: float) -> void:
	if showing_tutorial:
		if tutorial_index >= 38:
			var beat_fraction = conductor.song_position_sub_beat()
			if (beat_fraction >= 0 && beat_fraction < 0.25):
				screen.texture = tutorial_pictures[37]
			elif (beat_fraction >= 0.25 && beat_fraction < 0.5):
				screen.texture = tutorial_pictures[38]
			elif (beat_fraction >= 0.5 && beat_fraction < 0.75):
				screen.texture = tutorial_pictures[39]
			elif (beat_fraction >= 0.75 && beat_fraction < 1):
				screen.texture = tutorial_pictures[40]
		return
	
	var changed:bool = false
	if Input.is_action_just_pressed("move_north") \
		|| Input.is_action_just_pressed("move_northeast") \
		|| Input.is_action_just_pressed("move_northwest") \
		|| Input.is_action_just_pressed("move_west"):
			
		if title_index > 0:
			title_index -= 1
			sound_player.play_confirm()
			changed = true
		else:
			sound_player.play_fail()
			
	elif Input.is_action_just_pressed("move_south") \
		|| Input.is_action_just_pressed("move_southeast") \
		|| Input.is_action_just_pressed("move_southwest") \
		|| Input.is_action_just_pressed("move_east"):
		
		if title_index < 2:
			title_index += 1
			sound_player.play_confirm()
			changed = true
		else:
			sound_player.play_fail()
	
	if changed:
		match title_index:
			0: 
				screen.texture = title_1
			1:
				screen.texture = title_2
			2:
				screen.texture = credits
			
	if title_index == 0 && Input.is_action_just_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		sound_player.play_confirm()
	
	if title_index == 1 && Input.is_action_just_pressed("ui_accept"):
		showing_tutorial = true
		tutorial_index = 0
		sound_player.play_confirm()

	if title_index == 2 && Input.is_action_just_pressed("ui_accept"):
		screen.texture = title_1
		title_index = 0
		sound_player.play_confirm()
		

func _on_conductor_on_beat() -> void:
	if not showing_tutorial:
		return	
	if tutorial_index < 38:
		screen.texture = tutorial_pictures[tutorial_index]
	if tutorial_index > 50:
		showing_tutorial = false
		screen.texture = title_2
		
	
	tutorial_index += 1
