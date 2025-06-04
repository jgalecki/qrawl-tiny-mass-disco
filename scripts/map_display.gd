extends Node
class_name MapDisplay

# MapDisplay handles logic for displaying the game world in the portion of
# pixels alloted to it. It also handles some post-game displays (like
# WIN, DEAD, and GOLD #
# Handles pixel columns 2 - 13. 0-1 and 14-15 are handled by UIDisplay

@export var display:DisplayArray
var flash_positions:Array[Vector2i]
var flash_colors:Array[Color]
var flash_timers:Array[float]

var player_offset:Vector2i = Vector2i(8, 4)
var crotchet:float = 1

func _ready() -> void:
	flash_positions = []
	flash_timers = []
	flash_colors = []

func update(game_state:GameState, delta: float, time:float) -> void:
	
	# First, display walls and floors
	
	var wall_color = Color.hex(0x9e4539ff) if not game_state.flash_map_walls else Color.hex(0x7a3045ff)
	var floor_color = Color.hex(0xe6904eff)
	
	for i in range(12):
		var dx = i - player_offset.x + 2
		for j in range(9):
			var dy = j - player_offset.y
			
			var x = game_state.player.position.x + dx
			var y = game_state.player.position.y + dy
			
			var this_wall_color = wall_color
			if game_state.flash_map_walls \
				&& game_state.flash_wall_extra.x == x && game_state.flash_wall_extra.y == y:
				this_wall_color = Color.hex(0x831c5dff)
			elif not game_state.flash_map_walls:
				var time_offset = x * 5 + y * 13
				var lerp_value = (sin((time_offset + time)) + 1) / 2
				this_wall_color = Color.hex(0x9e4539ff).lerp(Color.hex(0x88382dff), lerp_value)
					
				
			
			var black = Color.hex(0x2e222fff)
			if x < 0 || x >= game_state.map[0].size():
				display.set_color(i + 2, j, black)
			elif y < 0 || y >= game_state.map[0].size():
				display.set_color(i + 2, j, black	)
			else:
				var this_floor_color = floor_color
				if game_state.map[y][x] == 2:
					this_floor_color = Color.hex(0xc26b44ff)
				if game_state.map[y][x] == 4:
					this_floor_color = Color.hex(0xffffffff)
				elif game_state.map[y][x] == 5:
					this_wall_color = Color.hex(0x000000ff)
				
				var is_wall = game_state.map[y][x] == 1 || game_state.map[y][x] == 5
				display.set_color(i + 2, j, this_wall_color if is_wall else this_floor_color)
	
	if game_state.player.health > 0:
		display.set_color(8, 4, Color.hex(0x239063ff))
	else:
		display.set_color(8, 4, Color.hex(0x136342ff))
						
	for gold in game_state.gold:
		var display_position = get_display_position(gold.position, game_state)
		if is_display_position_on_screen(display_position) && is_world_position_not_qr(game_state, gold.position):
			var time_offset = gold.position.x * 7 + gold.position.y * 3
			var lerp_value = (sin((time_offset + time) * 5) + 1) / 2
			var shiny_gold = Color.hex(0xf9c22bff).lerp(Color.hex(0xffdc7cff), lerp_value)
			display.set_color(display_position.x, display_position.y, shiny_gold)
	
	for potion in game_state.health_potions:
		var display_position = get_display_position(potion, game_state)
		if is_display_position_on_screen(display_position) && is_world_position_not_qr(game_state, potion):
			var time_offset = potion.x * 7 + potion.y * 3
			var lerp_value = (sin((time_offset + time) * 8) + 1) / 2
			var shiny_potion = Color.hex(0x9c2626ff).lerp(Color.hex(0xb33831ff), lerp_value)
			display.set_color(display_position.x, display_position.y, shiny_potion)
			
	for weapon in game_state.weapon_positions:
		var display_position = get_display_position(weapon, game_state)
		if is_display_position_on_screen(display_position) && is_world_position_not_qr(game_state, weapon):
			var time_offset = weapon.x * 7 + weapon.y * 3
			var lerp_value = (sin((time_offset + time) * 7) + 1) / 2
			var shiny_weapon = Color.hex(0x9db4bdff).lerp(Color.hex(0xc7d3d8ff), lerp_value)
			display.set_color(display_position.x, display_position.y, shiny_weapon)
		
	for armor in game_state.armor_positions:
		var display_position = get_display_position(armor, game_state)
		if is_display_position_on_screen(display_position) && is_world_position_not_qr(game_state, armor):
			var time_offset = armor.x * 7 + armor.y * 3
			var lerp_value = (sin((time_offset + time) * 6) + 1) / 2
			var shiny_armor = Color.hex(0x657b84ff).lerp(Color.hex(0x8b9ca2ff), lerp_value)
			display.set_color(display_position.x, display_position.y, shiny_armor)
		
	for shovel in game_state.shovel_positions:
		var display_position = get_display_position(shovel, game_state)
		if is_display_position_on_screen(display_position) && is_world_position_not_qr(game_state, shovel):
			var time_offset = shovel.x * 7 + shovel.y * 3
			var lerp_value = (sin((time_offset + time) * 5) + 1) / 2
			var shiny_shovel = Color.hex(0xcaa164ff).lerp(Color.hex(0xc7ca64ff), lerp_value)
			display.set_color(display_position.x, display_position.y, shiny_shovel)
	
	for amulet_pos in game_state.amulets:
		var display_position = get_display_position(amulet_pos, game_state)
		if is_display_position_on_screen(display_position) && is_world_position_not_qr(game_state, amulet_pos):
			var time_offset = amulet_pos.x * 7 + amulet_pos.y * 3
			var lerp_value = (sin((time_offset + time) * 8) + 1) / 2
			var shiny_amulet = Color.hex(0x8fd3ffff).lerp(Color.hex(0xe0f3ffff), lerp_value)
			display.set_color(display_position.x, display_position.y, shiny_amulet)
		
	
	for monster in game_state.monsters:
		var positon = monster.next_beat_position if monster.next_beat_position != game_state.player.position else monster.position
		var display_position = get_display_position(positon, game_state)
		if is_display_position_on_screen(display_position) && is_world_position_not_qr(game_state, positon):
			display.set_color(display_position.x, display_position.y, monster.color)	
	
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
			var display_position = get_display_position(flash_positions[i], game_state) 
			if is_display_position_on_screen(display_position) && is_world_position_not_qr(game_state, flash_positions[i]):
				display.set_color(display_position.x, display_position.y, flash_colors[i])
	assert(flash_timers.size() == flash_colors.size())
	assert(flash_timers.size() == flash_positions.size())
	
func add_player_attack_flash(tile:Vector2i):
	add_short_flash(tile, Color.hex(0xc7dcd0ff))
	
func add_short_flash(tile:Vector2i, color:Color):
	add_timed_flash(tile, color, crotchet / 4.0)

func add_long_flash(tile:Vector2i, color:Color):
	add_timed_flash(tile, color, crotchet)
	
func add_flash(tile:Vector2i, color:Color):
	add_timed_flash(tile, color, crotchet / 2.0)
	
func add_timed_flash(tile:Vector2i, color:Color, length:float):
	var need_to_add = true
	for i in range(flash_positions.size()):
		if flash_positions[i] == tile:
			flash_timers[i] = length
			flash_colors[i] = color
			need_to_add = false
	if need_to_add:
		flash_positions.append(tile)
		flash_timers.append(length)
		flash_colors.append(color)
	
func is_display_position_on_screen(display_position:Vector2i) -> bool:
	return display_position.x >= 2 && display_position.x < 14 \
			&& display_position.y >= 0 && display_position.y < 9

func is_world_position_not_qr(game_state:GameState, position:Vector2i) -> bool:
	if position.x < 0 || position.x >= game_state.map_size || position.y < 0 || position.y >= game_state.map_size:
		return false
	return game_state.map[position.y][position.x] != 4 && game_state.map[position.y][position.x] != 5
				
func get_display_position(world_position:Vector2i, game_state:GameState) -> Vector2i:
	return player_offset + world_position - game_state.player.position
	
func get_border_point(world_pos_i:Vector2i, game_state:GameState):
	var world_pos = Vector2(world_pos_i.x, world_pos_i.y)
	var player_pos = game_state.player.position
	var left_border_x = player_pos.x - 6
	var right_border_x = player_pos.x + 5
	var top_border_y = player_pos.y - 4
	var bottom_border_y = player_pos.y + 4
		
	var intersections = []
		
	if world_pos.x != player_pos.x:
		var t_l = (left_border_x - player_pos.x) / (1.0 * world_pos.x - player_pos.x)		
		var left_border_intersect = player_pos.y + t_l * (world_pos.y - player_pos.y)
		if  top_border_y <= left_border_intersect && left_border_intersect <= bottom_border_y:
			var intersect_point = Vector2(left_border_x, left_border_intersect)
			intersections.append({"point": Vector2(left_border_x, left_border_intersect), "m": (world_pos - intersect_point).length() })
		
		var t_r = (right_border_x - player_pos.x) / (1.0 *world_pos.x - player_pos.x)		
		var right_border_intersect = player_pos.y + t_r * (world_pos.y - player_pos.y)
		if top_border_y <= right_border_intersect && right_border_intersect <= bottom_border_y:
			var intersect_point = Vector2(right_border_x, right_border_intersect)
			intersections.append({"point": Vector2(right_border_x, right_border_intersect), "m": (world_pos - intersect_point).length() })
				
	if world_pos.y != player_pos.y:
		var t_u = (top_border_y - player_pos.y) / (1.0 *world_pos.y - player_pos.y)
		var top_border_intersect = player_pos.x + t_u * (world_pos.x - player_pos.x)
		if left_border_x <= top_border_intersect && top_border_intersect <= right_border_x:
			var intersect_point = Vector2(top_border_intersect, top_border_y)
			intersections.append({"point": Vector2(top_border_intersect, top_border_y), "m": (world_pos - intersect_point).length()})
			
		var t_b = (bottom_border_y - player_pos.y) / (1.0 * world_pos.y - player_pos.y)
		var bottom_border_intersect = player_pos.x + t_b * (world_pos.x - player_pos.x)
		if left_border_x <= bottom_border_intersect && bottom_border_intersect <= right_border_x:
			var intersect_point = Vector2(bottom_border_intersect, bottom_border_y)
			intersections.append({"point": Vector2(bottom_border_intersect, bottom_border_y), "m": (world_pos - intersect_point).length()})
	
	assert(intersections.size() > 0)
	intersections.sort_custom(func(a, b): return a["m"] < b["m"])
	return intersections[0]["point"]
	
func game_over(showText:bool, show_gold:bool, gold_count:int):
	var black = Color.hex(0x2e222fff)
	for i in range(14):
		for j in range(9):
			display.set_color(i + 1, j, black)
			
	if not showText: 
		return
		
	if show_gold:	
		gold_display(gold_count)
		return
	
	var has_heart_color = Color.hex(0xb33831ff) 
	
	display.set_color(1, 2, has_heart_color)
	display.set_color(1, 3, has_heart_color)
	display.set_color(1, 4, has_heart_color)
	display.set_color(1, 5, has_heart_color)
	display.set_color(1, 6, has_heart_color)
			
	display.set_color(2, 2, has_heart_color)
	display.set_color(2, 6, has_heart_color)
	
	display.set_color(3, 3, has_heart_color)
	display.set_color(3, 4, has_heart_color)
	display.set_color(3, 5, has_heart_color)
	
	display.set_color(5, 2, has_heart_color)
	display.set_color(5, 3, has_heart_color)
	display.set_color(5, 4, has_heart_color)
	display.set_color(5, 5, has_heart_color)
	display.set_color(5, 6, has_heart_color)
	
	display.set_color(6, 2, has_heart_color)
	display.set_color(6, 4, has_heart_color)
	display.set_color(6, 6, has_heart_color)
	
	display.set_color(8, 2, has_heart_color)
	display.set_color(8, 3, has_heart_color)
	display.set_color(8, 4, has_heart_color)
	display.set_color(8, 5, has_heart_color)
	display.set_color(8, 6, has_heart_color)
	
	display.set_color(9, 2, has_heart_color)
	display.set_color(9, 4, has_heart_color)
	
	display.set_color(10, 3, has_heart_color)
	display.set_color(10, 4, has_heart_color)
	display.set_color(10, 5, has_heart_color)
	display.set_color(10, 6, has_heart_color)
	
	display.set_color(12, 2, has_heart_color)
	display.set_color(12, 3, has_heart_color)
	display.set_color(12, 4, has_heart_color)
	display.set_color(12, 5, has_heart_color)
	display.set_color(12, 6, has_heart_color)
	
	display.set_color(13, 2, has_heart_color)
	display.set_color(13, 6, has_heart_color)
	
	display.set_color(14, 3, has_heart_color)
	display.set_color(14, 4, has_heart_color)
	display.set_color(14, 5, has_heart_color)
	

func victory(showText:bool, show_gold:bool, gold_count:int):
	var black = Color.hex(0x2e222fff)
	for i in range(14):
		for j in range(9):
			display.set_color(i + 1, j, black)
			
	if not showText: 
		return
		
	if show_gold:	
		gold_display(gold_count)
		return
		
	var amulet_color = Color.hex(0x8fd3ffff)
		
	display.set_color(2, 2, amulet_color)
	display.set_color(2, 3, amulet_color)
	display.set_color(2, 4, amulet_color)
	display.set_color(2, 5, amulet_color)
	display.set_color(2, 6, amulet_color)
	
	display.set_color(3, 6, amulet_color)
	
	display.set_color(4, 2, amulet_color)
	display.set_color(4, 3, amulet_color)
	display.set_color(4, 4, amulet_color)
	display.set_color(4, 5, amulet_color)
	display.set_color(4, 6, amulet_color)
	
	display.set_color(5, 6, amulet_color)
	
	display.set_color(6, 2, amulet_color)
	display.set_color(6, 3, amulet_color)
	display.set_color(6, 4, amulet_color)
	display.set_color(6, 5, amulet_color)
	display.set_color(6, 6, amulet_color)

	display.set_color(8, 2, amulet_color)
	display.set_color(8, 3, amulet_color)
	display.set_color(8, 4, amulet_color)
	display.set_color(8, 5, amulet_color)
	display.set_color(8, 6, amulet_color)
	
	display.set_color(10, 2, amulet_color)
	display.set_color(10, 3, amulet_color)
	display.set_color(10, 4, amulet_color)
	display.set_color(10, 5, amulet_color)
	display.set_color(10, 6, amulet_color)

	display.set_color(11, 3, amulet_color)
	display.set_color(12, 4, amulet_color)
	display.set_color(12, 5, amulet_color)
	
	display.set_color(13, 2, amulet_color)
	display.set_color(13, 3, amulet_color)
	display.set_color(13, 4, amulet_color)
	display.set_color(13, 5, amulet_color)
	display.set_color(13, 6, amulet_color)

func gold_display(gold_count:int):
	var gold = Color.hex(0xf9c22bff)
	var black = Color.hex(0x2e222fff)
	for i in range(16):
		for j in range(9):
			display.set_color(i, j, black)
			
	display.set_color(2, 0, gold)
	display.set_color(3, 0, gold)
	display.set_color(1, 1, gold)
	display.set_color(1, 2, gold)
	display.set_color(3, 2, gold)
	display.set_color(1, 3, gold)
	display.set_color(2, 3, gold)
	display.set_color(3, 3, gold)
	
	display.set_color(5, 0, gold)
	display.set_color(6, 0, gold)
	display.set_color(7, 0, gold)
	display.set_color(5, 1, gold)
	display.set_color(7, 1, gold)
	display.set_color(5, 2, gold)
	display.set_color(7, 2, gold)
	display.set_color(5, 3, gold)
	display.set_color(6, 3, gold)
	display.set_color(7, 3, gold)
	
	display.set_color(9, 0, gold)
	display.set_color(9, 1, gold)
	display.set_color(9, 2, gold)
	display.set_color(9, 3, gold)
	display.set_color(10, 3, gold)
	
	display.set_color(12, 0, gold)
	display.set_color(13, 0, gold)
	display.set_color(12, 1, gold)
	display.set_color(14, 1, gold)
	display.set_color(12, 2, gold)
	display.set_color(14, 2, gold)
	display.set_color(12, 3, gold)
	display.set_color(13, 3, gold)

	var thousands = gold_count / 1000
	var hundreds = (gold_count - thousands * 1000) / 100
	var tens  = (gold_count - thousands * 1000 - hundreds * 100) / 10
	var ones = gold_count % 10

	gold_print(thousands, 0)
	gold_print(hundreds, 4)
	gold_print(tens, 8)
	gold_print(ones, 12)
	
func gold_print(digit:int, x_offset:int):
	var gold = Color.hex(0xf9c22bff)
	match digit:
		0: 
			display.set_color(x_offset, 5, gold)
			display.set_color(x_offset + 1, 5, gold)
			display.set_color(x_offset + 2, 5, gold)
			display.set_color(x_offset, 6, gold)
			display.set_color(x_offset + 2, 6, gold)
			display.set_color(x_offset, 7, gold)
			display.set_color(x_offset + 2, 7, gold)
			display.set_color(x_offset, 8, gold)
			display.set_color(x_offset + 1, 8, gold)
			display.set_color(x_offset + 2, 8, gold)
		1:
			display.set_color(x_offset + 1, 5, gold)
			display.set_color(x_offset + 2, 5, gold)
			display.set_color(x_offset + 2, 6, gold)
			display.set_color(x_offset + 2, 7, gold)
			display.set_color(x_offset + 2, 8, gold)
		2:
			display.set_color(x_offset, 5, gold)
			display.set_color(x_offset + 1, 5, gold)
			display.set_color(x_offset + 2, 5, gold)
			display.set_color(x_offset + 2, 6, gold)
			display.set_color(x_offset + 1, 7, gold)
			display.set_color(x_offset, 8, gold)
			display.set_color(x_offset + 1, 8, gold)
			display.set_color(x_offset + 2, 8, gold)
		3:
			display.set_color(x_offset, 5, gold)
			display.set_color(x_offset + 1, 5, gold)
			display.set_color(x_offset + 2, 5, gold)
			display.set_color(x_offset + 2, 6, gold)
			display.set_color(x_offset + 1, 7, gold)
			display.set_color(x_offset + 2, 7, gold)
			display.set_color(x_offset, 8, gold)
			display.set_color(x_offset + 1, 8, gold)
			display.set_color(x_offset + 2, 8, gold)
		4:
			display.set_color(x_offset, 5, gold)
			display.set_color(x_offset + 2, 5, gold)
			display.set_color(x_offset, 6, gold)
			display.set_color(x_offset + 1, 6, gold)
			display.set_color(x_offset + 2, 6, gold)
			display.set_color(x_offset + 2, 7, gold)
			display.set_color(x_offset + 2, 8, gold)
		5:
			display.set_color(x_offset, 5, gold)
			display.set_color(x_offset + 1, 5, gold)
			display.set_color(x_offset + 2, 5, gold)
			display.set_color(x_offset, 6, gold)
			display.set_color(x_offset + 1, 7, gold)
			display.set_color(x_offset + 2, 7, gold)
			display.set_color(x_offset, 8, gold)
			display.set_color(x_offset + 1, 8, gold)
			display.set_color(x_offset + 2, 8, gold)
		6:
			display.set_color(x_offset, 5, gold)
			display.set_color(x_offset, 6, gold)
			display.set_color(x_offset + 1, 6, gold)
			display.set_color(x_offset + 2, 6, gold)
			display.set_color(x_offset, 7, gold)
			display.set_color(x_offset + 2, 7, gold)
			display.set_color(x_offset, 8, gold)
			display.set_color(x_offset + 1, 8, gold)
			display.set_color(x_offset + 2, 8, gold)
		7:
			display.set_color(x_offset, 5, gold)
			display.set_color(x_offset + 1, 5, gold)
			display.set_color(x_offset + 2, 5, gold)
			display.set_color(x_offset + 2, 6, gold)
			display.set_color(x_offset + 1, 7, gold)
			display.set_color(x_offset + 1, 8, gold)
		8:
			display.set_color(x_offset, 5, gold)
			display.set_color(x_offset + 1, 5, gold)
			display.set_color(x_offset + 2, 5, gold)
			display.set_color(x_offset, 6, gold)
			display.set_color(x_offset + 2, 6, gold)
			display.set_color(x_offset, 7, gold)
			display.set_color(x_offset + 1, 7, gold)
			display.set_color(x_offset + 2, 7, gold)
			display.set_color(x_offset, 8, gold)
			display.set_color(x_offset + 1, 8, gold)
			display.set_color(x_offset + 2, 8, gold)
		9:
			display.set_color(x_offset, 5, gold)
			display.set_color(x_offset + 1, 5, gold)
			display.set_color(x_offset + 2, 5, gold)
			display.set_color(x_offset, 6, gold)
			display.set_color(x_offset + 2, 6, gold)
			display.set_color(x_offset, 7, gold)
			display.set_color(x_offset + 1, 7, gold)
			display.set_color(x_offset + 2, 7, gold)
			display.set_color(x_offset + 2, 8, gold)
		_:
			assert(false)
