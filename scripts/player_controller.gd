extends Node
class_name PlayerController

# Class deals with player input - rating timing, validating, and resolving

var conductor:Conductor
var map_display:MapDisplay
var sound_player:SoundPlayer

# These are all percentages of the beat rather than absolute timings
var great_hit_time = 0.06
var good_hit_time = 0.12
var okay_hit_time = 0.18

signal health_pickup

func handle_input(game_state:GameState):
	var has_input = false
	var good_input = false
	var direction:Vector2i = Vector2i.ZERO
	if Input.is_action_just_pressed("move_east"):
		has_input = true
		direction = Vector2i(1, 0)
	elif Input.is_action_just_pressed("move_northeast"):
		has_input = true
		direction = Vector2i(1, -1)
	elif Input.is_action_just_pressed("move_north"):
		has_input = true
		direction = Vector2i(0, -1)
	elif Input.is_action_just_pressed("move_northwest"):
		has_input = true
		direction = Vector2i(-1, -1)
	elif Input.is_action_just_pressed("move_west"):
		has_input = true
		direction = Vector2i(-1, 0)
	elif Input.is_action_just_pressed("move_southwest"):
		has_input = true
		direction = Vector2i(-1, 1)			
	elif Input.is_action_just_pressed("move_south"):
		has_input = true
		direction = Vector2i(0, 1)
	elif Input.is_action_just_pressed("move_southeast"):
		has_input = true
		direction = Vector2i(1, 1)
		
	# IF there is input, then we'll go through the following steps
	# 1) Is this a valid time for input? (Close enough to the beat)
	# 	2) Does this input attack an enemy monster?
	#           (This removes monster health as a side effect)
	# 	3) Can the player move into that space?
	# 	4) If there wasn't a legal attack and there was a legal move option
	#      then move the player to the new position
	# 5) If the input wasn't close enough to the beat, or the provided input 
	#    can neither attack or move (e.g., player tries to move into a wall
	#    without any digs), then the player loses their combo.
		
	if has_input:
		game_state.player_moved = true
		var valid_time = valid_time_for_input(game_state)
		if valid_time:
			var valid_attack = valid_attack(game_state, direction)
			var valid_move = valid_space_for_input(game_state, direction) 
			if valid_attack || valid_move:
				good_input = true
				rate_input(game_state)
					
				# Attack logic takes place in valid_attack(). valid_space_for_input() only checks the map instead of 
				# enemy positions, so most often enemy positions are valid spaces for the player to move on to. The
				# player shouldn't move into an enemy square if they just attacked it.
				#
				# That's why we check for 'if NOT valid_attack' here rather than the expected 'if valid_move'
				if !valid_attack:
					#var current_pos = game_state.player.position
					#game_state.map[current_pos.y][current_pos.x] = 4 if game_state.map[current_pos.y][current_pos.x] == 0 else 5
					game_state.player.position += direction
					pickup_ground_stuff(game_state, direction)
				
			
		if not good_input:
			game_state.player.combo = 0
			game_state.player.keeping_beat_combo = 0
			
func valid_time_for_input(game_state:GameState) -> bool:
	if game_state.player_hit_state == GameState.HitState.Failed: 
		return false
	if game_state.player_hit_state != GameState.HitState.None:
		return false
	
	var sub_beat = conductor.song_position_sub_beat()
	var on_time = sub_beat <= okay_hit_time || sub_beat >= 1 - okay_hit_time
	
	if not on_time:
		if sub_beat < 0.25:
			game_state.player_hit_state = GameState.HitState.Late
			if game_state.player.keeping_beat_combo > 0:
				sound_player.player_sfx(SoundPlayer.Sfxs.BadHit)
		else:
			if (game_state.player_hit_state == GameState.HitState.Early):
				return false
			game_state.player_hit_state = GameState.HitState.Early
			if game_state.player.keeping_beat_combo > 0:
				sound_player.player_sfx(SoundPlayer.Sfxs.BadHit)
	
	return on_time
	
func valid_attack(game_state:GameState, direction:Vector2i) -> bool:
	var attack_positions = get_attack_pattern(game_state.player.position, direction, game_state.player.weapon_type)
	var successful_attack:bool = false
	for monster in game_state.monsters:
		for attack_position in attack_positions:
			if monster.position == attack_position:
				monster.health -= 1
				sound_player.player_sfx(SoundPlayer.Sfxs.PlayerAttack)
				successful_attack = true
				
	if successful_attack:
		flash_attack_pattern(game_state.player.position, direction, game_state.player.weapon_type)
			
	return successful_attack
		
		
			
	
func valid_space_for_input(game_state:GameState, direction:Vector2i) -> bool:
	var new_position = game_state.player.position + direction
	var out_of_bounds = new_position.x < 0 || new_position.x >= game_state.map[0].size() \
	   	|| new_position.y < 0 || new_position.y >= game_state.map.size()
	if  out_of_bounds || game_state.map[new_position.y][new_position.x] == 1:
		if not out_of_bounds && (game_state.player.digs > 0 || game_state.player.shovel_beats > 0):
			if game_state.player.shovel_beats == 0:
				game_state.player.digs -= 1
			sound_player.player_sfx(SoundPlayer.Sfxs.WallDig)
			game_state.map[new_position.y][new_position.x] = 2
			map_display.add_flash(new_position, Color.hex(0xfbb954ff))
			
		else:
			game_state.flash_map_walls = true
			game_state.flash_wall_extra = new_position
			game_state.player_hit_state = GameState.HitState.Failed
			sound_player.player_sfx(SoundPlayer.Sfxs.WallBump)
			return false
	
	return true	
	
func rate_input(game_state:GameState):
	var sub_beat = conductor.song_position_sub_beat()
	if sub_beat <= great_hit_time || sub_beat >= 1 - great_hit_time:
		game_state.player_hit_state = GameState.HitState.Great	
		game_state.player.keeping_beat_combo += 1
	elif sub_beat <= good_hit_time || sub_beat >= 1 - good_hit_time:
		game_state.player_hit_state = GameState.HitState.Good
		game_state.player.keeping_beat_combo += 1
	elif sub_beat <= okay_hit_time || sub_beat >= 1 - okay_hit_time:
		game_state.player_hit_state = GameState.HitState.Okay
		game_state.player.keeping_beat_combo += 1
	else:
		print("rate_input() called on an invalid player hit")
		assert(false)
	
func pickup_ground_stuff(game_state:GameState, direction:Vector2i):
	var sound_to_play:int = 0
	var i = 0
	while i < game_state.gold.size():
		if game_state.gold[i].position == game_state.player.position:
			game_state.player.gold += game_state.gold[i].amount * game_state.player.combo
			game_state.gold.remove_at(i)
			i -= 1
			sound_to_play = 1
		i += 1
		
	while i < game_state.health_potions.size():
		if game_state.health_potions[i] == game_state.player.position:
			game_state.player.health = min(3, game_state.player.health + 1)
			health_pickup.emit()
			game_state.health_potions.remove_at(i)
			i -= 1
			sound_to_play = 2
		i += 1
			
	i = 0
	while i < game_state.weapon_positions.size():
		if game_state.weapon_positions[i] == game_state.player.position:
			game_state.player.weapon_type = game_state.weapon_types[i]
			game_state.weapon_positions.remove_at(i)
			game_state.weapon_types.remove_at(i)
			i -= 1
			sound_to_play = 3
			flash_attack_pattern(game_state.player.position, direction, game_state.player.weapon_type)
			
		i += 1
		
	i = 0
	while i < game_state.armor_positions.size():
		if game_state.armor_positions[i] == game_state.player.position:
			game_state.player.armor += 1
			game_state.armor_positions.remove_at(i)
			i -= 1
			sound_to_play = 3
		i += 1
		
	i = 0
	while i < game_state.shovel_positions.size():
		if game_state.shovel_positions[i] == game_state.player.position:
			# 16 + 1 'bonus' beat. Counter is decremented on beat closeout, including immediately after pickup
			game_state.player.shovel_beats += 17		
			game_state.shovel_positions.remove_at(i)
			i -= 1
			sound_to_play = 3
		i += 1
			
	i = 0
	while i < game_state.amulets.size():
		if i >= game_state.amulets.size():
			break
		if game_state.amulets[i] == game_state.player.position:
			game_state.player.amulets += 1
			game_state.amulets.remove_at(i)
			i -= 1
			if game_state.player.amulets == 3:
				game_state.is_collapsing = true
				game_state.amulets.append(Vector2i(game_state.map_size - 2, game_state.map_size - 2))
			sound_to_play = 4
		i += 1
		
	match sound_to_play:
		#0: 0 is skipped, no sound
		1:
			sound_player.player_sfx(SoundPlayer.Sfxs.GoldPickup)
		2:
			sound_player.player_sfx(SoundPlayer.Sfxs.HealthPickup)
		3:
			sound_player.player_sfx(SoundPlayer.Sfxs.GearPickup)
		4:
			sound_player.player_sfx(SoundPlayer.Sfxs.AmuletPickup)

func get_attack_pattern(player_position:Vector2i, direction:Vector2i, weapon_type:int) -> Array[Vector2i]:
	var attack_positions:Array[Vector2i] = [ player_position + direction ]
	if weapon_type == 1:
		attack_positions.append(player_position + 2 * direction)
	elif weapon_type == 2:
		# if orthogonal directions.
		if direction.x == 0:
			attack_positions.append(player_position + (direction + Vector2i(-1, 0)))
			attack_positions.append(player_position + (direction + Vector2i(1, 0)))
		elif direction.y == 0:
			attack_positions.append(player_position + (direction + Vector2i(0, -1)))
			attack_positions.append(player_position + (direction + Vector2i(0, 1)))
		#if diagonal directions
		else:
			if direction.x < 0:
				attack_positions.append(player_position + (direction + Vector2i(1, 0)))
			else:
				attack_positions.append(player_position + (direction + Vector2i(-1, 0)))
			if direction.y < 0:
				attack_positions.append(player_position + (direction + Vector2i(0, 1)))
			else:
				attack_positions.append(player_position + (direction + Vector2i(0, -1)))
				
	return attack_positions
	
func flash_attack_pattern(player_position:Vector2i, direction:Vector2i, weapon_type:int):
	var attack_positions = get_attack_pattern(player_position, direction, weapon_type)				
	for attack_position in attack_positions:
		map_display.add_player_attack_flash(attack_position)
