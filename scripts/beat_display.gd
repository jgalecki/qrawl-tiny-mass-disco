extends Node
class_name BeatDisplay

# Beat Display handles display of the beat meter in the main game.
# The beat meter takes the left and right most columns of the 16 x 9 game
# (plus the middle square of the adjacent columns) and uses them to display 
# beat information - when the beat hits, and whether a player's input is 
# properly timed.
# It also will flash red when the player is hurt.

# (The flash pattern (_positions, _colors, _timers, and the logic for it) 
# reappears across several classes and could likely be abstracted. Such 
# concerns are gleefully ignored when you only have two months to make a game.)

@export var conductor:Conductor
@export var display:DisplayArray

var flash_positions:Array[Vector2i]
var flash_colors:Array[Color]
var flash_timers:Array[float]

func _ready() -> void:
	
	flash_positions = []
	flash_timers = []
	flash_colors = []
	
	var empty_color = Color.hex(0x8ff8e2ff)
	display.set_color(0, 0, empty_color)
	display.set_color(0, 1, empty_color)
	display.set_color(0, 2, empty_color)
	display.set_color(0, 3, empty_color)
	display.set_color(0, 4, empty_color)
	display.set_color(0, 5, empty_color)
	display.set_color(0, 6, empty_color)
	display.set_color(0, 7, empty_color)
	display.set_color(0, 8, empty_color)
	
	
	display.set_color(15, 0, empty_color)
	display.set_color(15, 1, empty_color)
	display.set_color(15, 2, empty_color)
	display.set_color(15, 3, empty_color)
	display.set_color(15, 4, empty_color)
	display.set_color(15, 5, empty_color)
	display.set_color(15, 6, empty_color)
	display.set_color(15, 7, empty_color)
	display.set_color(15, 8, empty_color)


func update(game_state:GameState, delta: float) -> void:
	var beat_fraction = conductor.song_position_sub_beat()
	if (beat_fraction >= 0 && beat_fraction < 0.25):
		display_beat(game_state, 0)
	elif (beat_fraction >= 0.25 && beat_fraction < 0.5):
		display_beat(game_state, 1)
	elif (beat_fraction >= 0.5 && beat_fraction < 0.75):
		display_beat(game_state, 2)
	elif (beat_fraction >= 0.75 && beat_fraction < 1):
		display_beat(game_state, 3)
	else:
		print("WHOOOOOOOOOOPS")

	# remove old flashes
	for i in range(flash_timers.size()):
		if i >= flash_timers.size():
			break
		flash_timers[i] -= delta
		if flash_timers[i] <= 0:
			flash_timers.remove_at(i)
			flash_colors.remove_at(i)
			flash_positions.remove_at(i)
			i -= 1
		else:
			display.set_color(flash_positions[i].x, flash_positions[i].y, flash_colors[i])
	assert(flash_timers.size() == flash_colors.size())
	assert(flash_timers.size() == flash_positions.size())
	
func display_beat(game_state:GameState, sub_beat:int) -> void:
	var beat_color = Color.hex(0x0eaf9bff) # if hit state is None
	var new_beat_color = Color.hex(0x0eaf9bff) 
	var beat_fade_color = Color.hex(0x0b8a8fff)
	var empty_color = Color.hex(0xb5e65ff)
	
	if game_state.player_hit_state == GameState.HitState.Early \
		|| game_state.player_hit_state == GameState.HitState.Late:
		beat_color = Color.hex(0xf04f78ff)
	elif game_state.player_hit_state == GameState.HitState.Okay:
		beat_color = Color.hex(0xf9c22bff)
	elif game_state.player_hit_state == GameState.HitState.Good:
		beat_color = Color.hex(0x239063ff)
	elif game_state.player_hit_state == GameState.HitState.Great:
		beat_color = Color.hex(0x91db69ff)
	
	
	display.set_color(0, 0, new_beat_color if sub_beat == 0 else empty_color)
	display.set_color(0, 1, beat_color if sub_beat == 1 else empty_color)
	display.set_color(0, 2, beat_color if sub_beat == 2 else empty_color)
	display.set_color(0, 3, beat_color if sub_beat == 3 else empty_color)
	display.set_color(0, 4, beat_color if sub_beat == 0 else (beat_fade_color if sub_beat == 1 else empty_color))
	display.set_color(0, 5, beat_color if sub_beat == 3 else empty_color)
	display.set_color(0, 6, beat_color if sub_beat == 2 else empty_color)
	display.set_color(0, 7, beat_color if sub_beat == 1 else empty_color)
	display.set_color(0, 8, new_beat_color if sub_beat == 0 else empty_color)	
	
	display.set_color(15, 0, new_beat_color if sub_beat == 0 else empty_color)
	display.set_color(15, 1, beat_color if sub_beat == 1 else empty_color)
	display.set_color(15, 2, beat_color if sub_beat == 2 else empty_color)
	display.set_color(15, 3, beat_color if sub_beat == 3 else empty_color)
	display.set_color(15, 4, beat_color if sub_beat == 0 else (beat_fade_color if sub_beat == 1 else empty_color))
	display.set_color(15, 5, beat_color if sub_beat == 3 else empty_color)
	display.set_color(15, 6, beat_color if sub_beat == 2 else empty_color)
	display.set_color(15, 7, beat_color if sub_beat == 1 else empty_color)
	display.set_color(15, 8, new_beat_color if sub_beat == 0 else empty_color)
	
	display.set_color(1, 4, beat_color if sub_beat == 0 else (beat_fade_color if sub_beat == 1 else empty_color))
	display.set_color(14, 4, beat_color if sub_beat == 0 else (beat_fade_color if sub_beat == 1 else empty_color))
	


func add_flash(tile:Vector2i, color:Color):
	var need_to_add = true
	for i in range(flash_positions.size()):
		if flash_positions[i] == tile:
			flash_timers[i] = 0.2
			flash_colors[i] = color
			need_to_add = false
	if need_to_add:
		flash_positions.append(tile)
		flash_timers.append(0.2)
		flash_colors.append(color)
		
func flash_player_hit():
	var heart_color = Color.hex(0xb33831ff) 
	add_flash(Vector2i(0, 0), heart_color)
	add_flash(Vector2i(0, 1), heart_color)
	add_flash(Vector2i(0, 2), heart_color)
	add_flash(Vector2i(0, 3), heart_color)
	add_flash(Vector2i(0, 4), heart_color)
	add_flash(Vector2i(1, 4), heart_color)
	add_flash(Vector2i(0, 5), heart_color)
	add_flash(Vector2i(0, 6), heart_color)
	add_flash(Vector2i(0, 7), heart_color)
	add_flash(Vector2i(0, 8), heart_color)
	
	add_flash(Vector2i(15, 0), heart_color)
	add_flash(Vector2i(15, 1), heart_color)
	add_flash(Vector2i(15, 2), heart_color)
	add_flash(Vector2i(15, 3), heart_color)
	add_flash(Vector2i(15, 4), heart_color)
	add_flash(Vector2i(14, 4), heart_color)
	add_flash(Vector2i(15, 5), heart_color)
	add_flash(Vector2i(15, 6), heart_color)
	add_flash(Vector2i(15, 7), heart_color)
	add_flash(Vector2i(15, 8), heart_color)
	
