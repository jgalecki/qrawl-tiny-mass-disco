extends Node

# The main logic class for the game. Handles state management and time travel*
# *Time travel allows the game to update monster / trap moves on exactly on 
# the beat, but still allow the player to have input slightly later than the
# beat but still within the valid input envelope. That post-beat input will
# apply to the game state from before the beat update, and it would be as if
# it was applied in time.

@export var conductor:Conductor
@export var display:DisplayArray
@export var qr_picture:TextureRect
@export var qr_tmg:Texture2D
@export var qr_badc:Texture2D
@export var qr_neongarten:Texture2D
@export var qr_wadc:Texture2D

@export var map_reader:MapReader
@export var map_display:MapDisplay
@export var ui_display:UIDisplay
@export var beat_display:BeatDisplay
@export var sound_player:SoundPlayer

var player_controller:PlayerController

var game_state:GameState
var previous_game_state:GameState

# Lots of vars to manage state after the game is over. Win? Lose? Show gold? QR code pullback?
var game_over:bool
var game_over_show_text:bool
var victory:bool
var victory_show_text:bool
var after_game_beat_count:int
var after_game_allow_reset:bool
var after_victory_qr_started_on_beat:int
var after_victory_qr_shown:bool
var after_game_show_gold:bool

# Are we potentially waiting for player input for time travel? Set to true
# after a beat hits and the player has an input of NONE (not EARLY)
var wait_for_player_move:bool

var game_over_delay_timer:float

func _ready() -> void:
	game_state = GameState.new()
	# The web player doesn't like reading files.
	#game_state.map = map_reader.read_map("res://maps/tmg_map.txt")
	game_state.map = map_reader.read_map_web()
	game_state.qr_map = map_reader.qr_map
	game_state.map_size = map_reader.map_size * 2	# QR map size is doubled from actual QR code.
	previous_game_state = GameState.new()
	previous_game_state.player = Player.new()
	player_controller = PlayerController.new()
	player_controller.conductor = conductor
	player_controller.map_display = map_display
	player_controller.sound_player = sound_player
	player_controller.health_pickup.connect(ui_display.flash_health_pickup)
	
	# Create all monsters, traps, amulets, pickups.
	game_state.init()
	# Connect signal to make UI flash red on player hit from (instantiated) monsters
	for monster in game_state.monsters:
		monster.player_hit.connect(beat_display.flash_player_hit)
	# (Side note: I kind of mix using signals and using direct calls for things
	# like player hit. I'm pretty meh about that decision.)
	
	conductor.start_music()
	map_display.crotchet = conductor.crotchet
	ui_display.crotchet = conductor.crotchet
	
	# Post game variable management
	game_over = false
	game_over_show_text = false
	game_over_delay_timer = 0	
	victory = false
	victory_show_text = false	
	after_game_allow_reset = false
	after_game_show_gold = false
	after_game_beat_count = 0
	after_victory_qr_started_on_beat = 0
	after_victory_qr_shown = false
	
	wait_for_player_move = false
	
	# Quick testing of victory process
	#game_state.player.amulets = 3
	#game_state.amulets.append(Vector2i(game_state.map_size - 3, game_state.map_size - 3))

func _process(delta: float) -> void:
	# Time travel check - use the previous game state if we are a certain amount of
	# time after the beat hits and the player hasn't input anything yet.
	# They might!
	var forgiving_game_state = previous_game_state if wait_for_player_move else game_state
	
	if not (game_over || victory):
		player_controller.handle_input(forgiving_game_state)
		
		if wait_for_player_move && forgiving_game_state.player_moved:	
			# Activate TIME TRAVEL!
			wait_for_player_move = false
			# Track player health and health potions on the map in order
			# to detect a situation where the player was damaged in the old
			# state but not damaged in the forgiving / time travel state.
			# If that happens, we'll throw out a 'dodge' SFX
			var old_health = game_state.player.health
			var old_potion_count = game_state.health_potions.size()
			previous_game_state.copy_to(game_state)
			update_monsters()
			update_collapse()	
			var new_health = game_state.player.health
			var new_potion_count = game_state.health_potions.size()
			
			# Play a dodge sound effect if the player's post-beat input 
			# prevented damage from occuring. (Attack SFX already fired.)
			var picked_up_potion = old_potion_count < new_potion_count
			if new_health > old_health && not picked_up_potion:
				sound_player.player_sfx(SoundPlayer.Sfxs.Dodge)
			
	map_display.update(game_state, delta, conductor.song_position)
	beat_display.update(game_state, delta)
	ui_display.update(game_state, delta)
	
	if game_over && game_over_delay_timer > conductor.crotchet * 2:
		map_display.game_over(game_over_show_text, after_game_show_gold, game_state.player.gold)  
	if victory:
		map_display.victory(victory_show_text, after_game_show_gold, game_state.player.gold)#, conductor.song_position_beat)
	
	# Give the player a chance to escape death with post-beat input, before the measure closes out.
	if game_state.player.health <= 0 && conductor.song_position_sub_beat() > 0.18:
		game_over = true
		game_over_delay_timer += delta
		
	if game_state.player.amulets == 4:
		victory = true
	
	if (game_over && game_over_show_text) || (victory && victory_show_text):
		if after_game_beat_count > 4:
			after_game_show_gold = true
		if Input.is_anything_pressed() && after_game_beat_count > 12:
			match map_reader.map_pick:
				0: 
					qr_picture.texture = qr_tmg
					var tween = get_tree().create_tween()
					tween.set_parallel()
					tween.tween_property(qr_picture, "scale", Vector2(0.175, 0.175), 3).set_ease(Tween.EASE_IN)
					tween.tween_property(qr_picture, "position", Vector2(-416, -456), 3)
				1: 
					qr_picture.texture = qr_badc
					var tween = get_tree().create_tween()
					tween.set_parallel()
					tween.tween_property(qr_picture, "position", Vector2(-400, -456), 3)
					tween.tween_property(qr_picture, "scale", Vector2(0.15, 0.15), 3).set_ease(Tween.EASE_IN)
				2: 
					qr_picture.texture = qr_neongarten
					var tween = get_tree().create_tween()
					tween.set_parallel()
					tween.tween_property(qr_picture, "position", Vector2(-400, -456), 3)
					tween.tween_property(qr_picture, "scale", Vector2(0.15, 0.15), 3).set_ease(Tween.EASE_IN)
				3: 
					qr_picture.texture = qr_wadc
					var tween = get_tree().create_tween()
					tween.set_parallel()
					tween.tween_property(qr_picture, "position", Vector2(-400, -456), 3)
					tween.tween_property(qr_picture, "scale", Vector2(0.15, 0.15), 3).set_ease(Tween.EASE_IN)
				
			display.visible = false
			# QR Code pullback tween
			after_victory_qr_started_on_beat = after_game_beat_count
		
		var is_two_seconds_after_qr_pullback = after_game_beat_count > after_victory_qr_started_on_beat + conductor.beats_per_minute / 30
		if after_victory_qr_started_on_beat != 0 && is_two_seconds_after_qr_pullback:
			after_victory_qr_shown = true
	
	if after_game_allow_reset:
		if Input.is_anything_pressed():
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		return
		
		
	# Remove dead monsters, drop gold and such
	for i in range(game_state.monsters.size()):
		if i >= game_state.monsters.size():
			break
			
		if game_state.monsters[i].health <= 0:
			var gold = Gold.new()
			gold.amount = (game_state.monsters[i].gold * (1 + game_state.player.combo))
			gold.position = game_state.monsters[i].position
			game_state.gold.append(gold)
			
			if game_state.monsters[i].health_drop >= randi_range(0, 100):
				game_state.health_potions.append(game_state.monsters[i].position)
				
			game_state.player.combo = min(game_state.player.combo + 1, 4)
			game_state.player.digs = min(game_state.player.digs + 1, 4)
			game_state.monsters.remove_at(i)
			i -= 1
			sound_player.player_sfx(SoundPlayer.Sfxs.MonsterDeath)

func _on_conductor_on_beat() -> void:		
	if game_over && not game_over_show_text:
		game_over_show_text = true
		sound_player.player_sfx(SoundPlayer.Sfxs.GameOver)
		
	if victory && not victory_show_text:
		victory_show_text = true
		sound_player.player_sfx(SoundPlayer.Sfxs.Victory)
		
	if victory || game_over:
		after_game_beat_count += 1
		
	var allow_reset_game_over = game_over && after_game_show_gold
	var allow_reset_victory = victory && after_victory_qr_shown
	if allow_reset_game_over || allow_reset_victory:
		after_game_allow_reset = true

	if game_over || victory: 
		return

	forecast_monsters()
	
	if game_state.player_hit_state == GameState.HitState.None:
		wait_for_player_move = true
		game_state.copy_to(previous_game_state)

	update_monsters()
	update_collapse()
	
	## flash an escape "radar" square on every beat when the player is escaping the collapsing dungeon
	if game_state.player.amulets == 3:
		for amulet_pos in game_state.amulets:
			var display_position = map_display.get_display_position(amulet_pos, game_state)
			if not map_display.is_display_position_on_screen(display_position):
				var radar_pos = map_display.get_border_point(amulet_pos, game_state)
				var radar_display_pos = map_display.get_display_position(radar_pos, game_state)
				ui_display.add_flash(radar_display_pos, Color.hex(0x8fd3ffff))
	
	ui_display.add_short_flash(Vector2i(8, 4), Color.hex(0x2e9c6fff))
		
# After grabbing all three amulets, the dungeon starts collapsing
# and the player must make a break for the entrance
func update_collapse():		
	if game_state.is_collapsing:
		if game_state.collapsing_timer < 4:
			game_state.collapsing_timer += 1
		else:
			var abyss_roll = randi_range(0, 8)
			# Rate at which dungeon expands (right now, 66% of beats, 6 of 9)
			if abyss_roll >= 3:
				game_state.collapsing_timer += 1
		if game_state.collapsing_timer > 4:		# 1 measure of waiting
			var distance = game_state.collapsing_timer - 4
			for amulet_pos in game_state.amulet_positions:
				for dy in range(-1 * distance, distance + 1):
					for dx in range(-1 * distance, distance + 1):
						if abs(dy) + abs(dx) > distance:
							continue
						var cur_pos = amulet_pos + Vector2i(dx, dy)
						if cur_pos.y < 0 || cur_pos.y >= game_state.map_size \
						   || cur_pos.x < 0 || cur_pos.x >= game_state.map_size:
							continue
						var cur_tile = game_state.map[cur_pos.y][cur_pos.x]
						if cur_tile == 4 || cur_tile == 5:
							continue
						game_state.map[cur_pos.y][cur_pos.x] = 4 if cur_tile == 0 else 5
						if game_state.player.position == cur_pos:
							game_state.player.health = 0
		
func _on_conductor_close_out_beat() -> void:
	if game_over || victory: 
		return
		
	game_state.prev_hit_state = game_state.player_hit_state
	if game_state.prev_hit_state == GameState.HitState.None:
		game_state.prev_hit_state = GameState.HitState.Missed
		wait_for_player_move = false	
		
		if game_state.player.keeping_beat_combo > 0:
			sound_player.player_sfx(SoundPlayer.Sfxs.MissedHit)
		game_state.player.keeping_beat_combo = 0
		game_state.player.combo = 0
		game_state.flash_map_walls = false
	
	if game_state.player.shovel_beats > 0:
		game_state.player.shovel_beats -= 1
	
	game_state.player_hit_state = GameState.HitState.None
	game_state.player_moved = false
	
func forecast_monsters():
	# Don't forecast normal monster moves with flashes to where they are moving.
	# Players are reading these as monster attacks.
	# Could try something else later.
	pass
	#for monster in game_state.monsters:
		#if monster.turn_timer - 2 == 0:
			#if monster.type == Monster.MonsterType.QuickSlime \
			 	#|| monster.type == Monster.MonsterType.SlowSlime:
					#
				#var direction = monster.direction if monster.position == monster.home_position else monster.direction * -1
				#
				#map_display.add_flash(monster.position + direction, Color.hex(0xfbb954ff))
		
	
func update_monsters():	
	for monster in game_state.monsters:
		monster.turn_timer -= 1
		if monster.turn_timer > 0:
			continue
		if monster.health <= 0:
			continue				# Dead monster clean up occurs outside of and after update_monster()
		
		monster.turn_timer = monster.beats_per_turn
		if monster.type == Monster.MonsterType.QuickSlime \
		 	|| monster.type == Monster.MonsterType.SlowSlime:
				
			var direction = monster.direction if monster.position == monster.home_position else monster.direction * -1
			monster.move_onto(game_state, monster.position + direction, map_display, sound_player)
		
		if monster.type == Monster.MonsterType.Skeleton:
			var next_position = monster.position + monster.direction
			if next_position.x < 0 || next_position.x >= game_state.map_size \
				|| next_position.y < 0 || next_position.y >= game_state.map_size \
				|| game_state.map[next_position.y][next_position.x] == 1 \
				|| game_state.monsters.any(func(m): return m.position == next_position):
				monster.direction = -1 * monster.direction
			else:
				monster.move_onto(game_state, next_position, map_display, sound_player)
	
		if monster.type == Monster.MonsterType.Ghost:
			var player_diff = game_state.player.position - monster.position
			if player_diff.length() <= 5:
				monster.aggro = true
			if monster.aggro:
				# This way, the ghost gets on an orthogonal path when approaching the player
				var next_direction = player_diff
				if next_direction.x != 0:
					next_direction.x = next_direction.x / abs(next_direction.x)
				if next_direction.y != 0:
					next_direction.y = next_direction.y / abs(next_direction.y)
				monster.move_onto(game_state, monster.position + next_direction, map_display, sound_player)
		
		
func _on_conductor_half_beat() -> void:
	if game_state.prev_hit_state == GameState.HitState.Failed:
		game_state.flash_map_walls = false
		

func _on_conductor_on_new_measure() -> void:

	if game_over || victory: 
		return
		
	for trap in game_state.traps:
		if trap.fire_on_1:
			fire_on(trap.position)
		if trap.fireball_on_1:
			fire_on(trap.position + Vector2i(0, 0), true, true)
			fire_on(trap.position + Vector2i(1, 0), false, true)
			fire_on(trap.position + Vector2i(-1, 0), false, true)
			fire_on(trap.position + Vector2i(0, 1), false, true)
			fire_on(trap.position + Vector2i(0, -1), false, true)
		
			
func _on_conductor_on_beat_3() -> void:
	
	if game_over || victory: 
		return
		
	for trap in game_state.traps:
		if trap.fire_on_3:
			fire_on(trap.position)	
		if trap.fireball_on_1:
			fire_on(trap.position + Vector2i(3, 0), false, true)
			fire_on(trap.position + Vector2i(-3, 0), false, true)
			fire_on(trap.position + Vector2i(0, 3), false, true)
			fire_on(trap.position + Vector2i(0, -3), false, true)

	## flash a "radar" square on beat 3
	if game_state.player.amulets < 3:
		for amulet_pos in game_state.amulets:
			var display_position = map_display.get_display_position(amulet_pos, game_state)
			if not map_display.is_display_position_on_screen(display_position):
				var radar_pos = map_display.get_border_point(amulet_pos, game_state)
				var radar_display_pos = map_display.get_display_position(radar_pos, game_state)
				ui_display.add_flash(radar_display_pos, Color.hex(0x8fd3ffff))

func _on_conductor_on_beat_2() -> void:

	if game_over || victory: 
		return
		
	for trap in game_state.traps:	
		if trap.fireball_on_1:
			fire_on(trap.position + Vector2i(2, 0), false, true)
			fire_on(trap.position + Vector2i(-2, 0), false, true)
			fire_on(trap.position + Vector2i(0, 2), false, true)
			fire_on(trap.position + Vector2i(0, -2), false, true)


func _on_conductor_on_beat_4() -> void:

	if game_over || victory: 
		return
	
	## flash a "radar" square on beat 4	
	if game_state.player.amulets < 3:
		for amulet_pos in game_state.amulets:
			var display_position = map_display.get_display_position(amulet_pos, game_state)
			if not map_display.is_display_position_on_screen(display_position):
				var radar_pos = map_display.get_border_point(amulet_pos, game_state)
				var radar_display_pos = map_display.get_display_position(radar_pos, game_state)
				ui_display.add_flash(radar_display_pos, Color.hex(0x8fd3ffff))

# Trap function, damanges player if they are where the trap is
func fire_on(position:Vector2i, extra_bright:bool = false, extra_long:bool = false):
	var flash_color = Color.hex(0xfb451dff) if extra_bright else Color.hex(0xf33838ff)
	if extra_long:
		map_display.add_long_flash(position, flash_color)
	else:
		map_display.add_flash(position, flash_color)
	if position == game_state.player.position:
		game_state.player.health -= 1
		sound_player.player_sfx(SoundPlayer.Sfxs.FireTrapHit)
		beat_display.flash_player_hit()
