extends Unit
class_name Monster

enum MonsterType { SlowSlime, QuickSlime, Ghost, Skeleton }
@export var beats_per_turn:int
@export var turn_timer:int
@export var home_position:Vector2i
@export var type:MonsterType
@export var direction:Vector2i
@export var next_beat_position:Vector2i
@export var aggro:bool
@export var gold:int
@export var health_drop:int

@export var color:Color

@export var just_hit_player:bool

signal player_hit

func move_onto(game_state:GameState, new_position:Vector2i, map_display:MapDisplay, sound_player:SoundPlayer):
	if game_state.player.position == new_position:
		map_display.add_flash(new_position, Color.hex(0xea4f36ff))
		if game_state.player.armor > 0:
			game_state.player.armor -= 1
		else:
			game_state.player.health -= 1
		print("Monster hit, player health is " + str(game_state.player.health))
		player_hit.emit()
		just_hit_player = true
		game_state.player.just_hit = true
		sound_player.player_sfx(SoundPlayer.Sfxs.MonsterHit)
		next_beat_position = position	# undo next_beat_position preview
	elif game_state.monsters.any(func(m): return m.position == new_position):
		next_beat_position = position	# undo next_beat_position preview
	else:
		position = new_position
		next_beat_position = new_position
	
	
# Used for proper cloning when copying game states for time travel purposes
func copy_to(other_monster:Monster):
	other_monster.position = position
	other_monster.health = health
	other_monster.beats_per_turn = beats_per_turn
	other_monster.turn_timer = turn_timer
	other_monster.home_position = home_position
	other_monster.type = type
	other_monster.direction = direction
	other_monster.next_beat_position = next_beat_position
	other_monster.aggro = aggro
	other_monster.gold = gold
	other_monster.health_drop = health_drop
	other_monster.color = color
	other_monster.just_hit_player = just_hit_player
