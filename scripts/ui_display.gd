extends Node
class_name UIDisplay

# Handles display of the two leftmost and two rightmost columns, which are 
# reserved for the UI. (Health, beats, digs, gear, and amulets.)

@export var display:DisplayArray

var crotchet:float = 1

var flash_positions:Array[Vector2i]
var flash_colors:Array[Color]
var flash_timers:Array[float]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	flash_positions = []
	flash_timers = []
	flash_colors = []


func update(game_state:GameState, delta: float) -> void:
	
	var has_heart_color = Color.hex(0xb33831ff) 
	var no_heart_color = Color.hex(0x6e2727ff)
	var black = Color.hex(0x2e222fff)
	var has_armor_color = Color.hex(0x657b84ff)
	
	var color1 = has_armor_color if game_state.player.armor >= 1 else (has_heart_color if game_state.player.health >= 1 else no_heart_color)
	var color2 = has_armor_color if game_state.player.armor >= 2 else (has_heart_color if game_state.player.health >= 2 else no_heart_color)
	var color3 = has_armor_color if game_state.player.armor >= 3 else (has_heart_color if game_state.player.health >= 3 else no_heart_color)
	var color4 = has_armor_color if game_state.player.armor >= 4 else black
	
	display.set_color(1, 0, color1)
	display.set_color(1, 1, color2)
	display.set_color(1, 2, color3)
	display.set_color(1, 3, color4)
	
	
	var has_shovel_color = Color.hex(0xe8cca2ff)
	var has_dig_color = Color.hex(0xfbb954ff) 
	var no_dig_color = Color.hex(0x7a3045ff) 
	color1 = has_shovel_color if game_state.player.shovel_beats > 0 else (has_dig_color if game_state.player.digs >= 1 else no_dig_color)
	color2 = has_shovel_color if game_state.player.shovel_beats > 0 else (has_dig_color if game_state.player.digs >= 2 else no_dig_color)
	color3 = has_shovel_color if game_state.player.shovel_beats > 0 else (has_dig_color if game_state.player.digs >= 3 else no_dig_color)
	color4 = has_shovel_color if game_state.player.shovel_beats > 0 else (has_dig_color if game_state.player.digs >= 4 else no_dig_color)
	
	display.set_color(1, 8, color1)
	display.set_color(1, 7, color2)
	display.set_color(1, 6, color3)
	display.set_color(1, 5, color4)


	var combo_color = Color.hex(0xfdcbb0ff)
	var keeping_beat_color = Color.hex(0xf04f78ff)
	var no_beat_color = Color.hex(0x831c5dff)
	
	var weapon_color = Color.hex(0x9db4bdff) if game_state.player.weapon_type != 0 else black
	var armor_color = Color.hex(0x657b84ff) if game_state.player.armor > 0 else black
	var shovel_color = has_shovel_color if game_state.player.shovel_beats > 0 else black
	
	display.set_color(14, 0, weapon_color)
	display.set_color(14, 1, armor_color)
	display.set_color(14, 2, shovel_color)
	display.set_color(14, 3, black)

	# Gold display? Maybe later
	var amulet_color = Color.hex(0x8fd3ffff)
	var no_amulet_color = Color.hex(0x484a77ff)
	
	display.set_color(14, 8, amulet_color if game_state.player.amulets >= 1 else no_amulet_color)
	display.set_color(14, 7, amulet_color if game_state.player.amulets >= 2 else no_amulet_color)
	display.set_color(14, 6, amulet_color if game_state.player.amulets >= 3 else no_amulet_color)
	display.set_color(14, 5, black)


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

func flash_health_pickup():
	add_flash(Vector2i(1, 0), Color.hex(0xde7670ff))
	add_flash(Vector2i(1, 1), Color.hex(0xde7670ff))
	add_flash(Vector2i(1, 2), Color.hex(0xde7670ff))
	add_flash(Vector2i(1, 3), Color.hex(0xde7670ff))

func add_flash(tile:Vector2i, color:Color):
	var need_to_add = true
	for i in range(flash_positions.size()):
		if flash_positions[i] == tile:
			flash_timers[i] = crotchet / 2.0
			flash_colors[i] = color
			need_to_add = false
	if need_to_add:
		flash_positions.append(tile)
		flash_timers.append(crotchet / 2.0)
		flash_colors.append(color)
	
func add_short_flash(tile:Vector2i, color:Color):
	var need_to_add = true
	for i in range(flash_positions.size()):
		if flash_positions[i] == tile:
			flash_timers[i] = crotchet / 4.0
			flash_colors[i] = color
			need_to_add = false
	if need_to_add:
		flash_positions.append(tile)
		flash_timers.append(crotchet / 4.0)
		flash_colors.append(color)
