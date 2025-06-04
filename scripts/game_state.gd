extends Node
class_name GameState

# Big block of game state. Trying to keep all important things in here,
# going for 'black box sim' style (Brian Cronin, https://www.youtube.com/watch?v=jhcHlg7YhPg)
# The aim is to separate input and logic from presentation, although in a 
# dungeon-crawler rhythm game, input is heavily tied to logic.

var map:Array[Array]		# 0 = floor, 1 = wall, 2 = dug wall, 3 = amulet, 4 = qr white (floor), 5 = qr black (wall)
var qr_map:Array[Array]
var map_size:int
var player:Player
var traps:Array[Trap]
var monsters:Array[Monster]
var gold:Array[Gold]
var health_potions:Array[Vector2i]
var amulets:Array[Vector2i]
var amulet_positions:Array[Vector2i]
var weapon_positions:Array[Vector2i]
var weapon_types:Array[int]
var armor_positions:Array[Vector2i]
var shovel_positions:Array[Vector2i]

var is_collapsing:bool
var collapsing_timer:int

enum HitState { None, Early, Okay, Good, Great, Late, Failed, Missed }
var player_hit_state:HitState

# Used for effects that extend into the next beat. The single example right now: the player runs into the walls
# without any digs.
var prev_hit_state:HitState
var player_moved:bool

var flash_map_walls:bool
var flash_wall_extra:Vector2i


func init() -> void:
	player = Player.new()
	player.position = Vector2i(map_size - 2, map_size - 2)
	player.health = 3
	player.gold = 0
	player.combo = 0
	player.digs = 2
	player.amulets = 0
	player.weapon_type = 0
	player.shovel_beats = 0
	player.armor = 0
	
	is_collapsing = false
	collapsing_timer = 0

	player_hit_state = HitState.None
	flash_map_walls = false
	
	traps = []
	# Original trap density set in a 50 x 50 (= 2500) square map.
	# To keep the same density, multiply by that factor.
	var trap_count = (80.0 / 2500) * map_size * map_size
	for i in range(trap_count):
		var trap = Trap.new()
		trap.position = empty_map_spot()
		var trap_roll = randi_range(0, 9)
		trap.fire_on_1 = trap_roll > 1
		trap.fire_on_3 = trap_roll > 1
		trap.fireball_on_1 = trap_roll == 0 || trap_roll == 1
		traps.append(trap)
	
	monsters = []
	var monster_count = (64.0 / 2500) * map_size * map_size
	for i in range(monster_count):
		var monster = Monster.new()
		monster.type = Monster.MonsterType.SlowSlime
		monster.beats_per_turn = 4
		monster.turn_timer = 4
		monster.health = 1
		monster.gold = 1
		monster.health_drop = 2
		monster.position = empty_map_spot()
		monster.home_position = monster.position
		monster.next_beat_position = monster.position
		monster.color = Color.hex(0x6b3e75ff)
		monster.aggro = false
		
		if monster.position.y + 1 < map_size && map[monster.position.y + 1][monster.position.x] != 1:
			monster.direction = Vector2i(0, 1)
		elif monster.position.x + 1 < map_size && map[monster.position.y][monster.position.x + 1] != 1:
			monster.direction = Vector2i(1, 0)
		elif monster.position.y - 1 >= 0 && map[monster.position.y - 1][monster.position.x] != 1:
			monster.direction = Vector2i(0, -1)
		elif monster.position.x - 1 >= 0 && map[monster.position.y][monster.position.x - 1] != 1:
			monster.direction = Vector2i(-1, 0)
		else:
			monster.direction = Vector2i.ZERO
			
		monsters.append(monster)
	var quick_slime_count = (48.0 / 2500) * map_size * map_size
	for i in range(quick_slime_count):
		var monster = Monster.new()
		monster.type = Monster.MonsterType.QuickSlime
		monster.beats_per_turn = 2
		monster.turn_timer = 4
		monster.health = 2
		monster.gold = 1
		monster.health_drop = 3
		monster.position = empty_map_spot()
		monster.home_position = monster.position
		monster.next_beat_position = monster.position
		monster.color = Color.hex(0x905ea9ff)
		monster.aggro = false
		
		if monster.position.y + 1 < map_size && map[monster.position.y + 1][monster.position.x] != 1:
			monster.direction = Vector2i(0, 1)
		elif monster.position.x + 1 < map_size && map[monster.position.y][monster.position.x + 1] != 1:
			monster.direction = Vector2i(1, 0)
		elif monster.position.y - 1 >= 0 && map[monster.position.y - 1][monster.position.x] != 1:
			monster.direction = Vector2i(0, -1)
		elif monster.position.x - 1 >= 0 && map[monster.position.y][monster.position.x - 1] != 1:
			monster.direction = Vector2i(-1, 0)
		else:
			monster.direction = Vector2i.ZERO
			
		monsters.append(monster)
	var skeleton_count = (48.0 / 2500) * map_size * map_size
	for i in range(skeleton_count):
		var monster = Monster.new()
		monster.type = Monster.MonsterType.Skeleton
		monster.beats_per_turn = 2
		monster.turn_timer = 4
		monster.health = 2
		monster.gold = 2
		monster.health_drop = 8
		monster.position = empty_map_spot()
		monster.home_position = monster.position
		monster.next_beat_position = monster.position
		monster.color = Color.hex(0xbaafceff)
		monster.aggro = false
		
		if monster.position.y + 1 < map_size && map[monster.position.y + 1][monster.position.x] != 1:
			monster.direction = Vector2i(0, 1)
		elif monster.position.x + 1 < map_size && map[monster.position.y][monster.position.x + 1] != 1:
			monster.direction = Vector2i(1, 0)
		elif monster.position.y - 1 >= 0 && map[monster.position.y - 1][monster.position.x] != 1:
			monster.direction = Vector2i(0, -1)
		elif monster.position.x - 1 >= 0 && map[monster.position.y][monster.position.x - 1] != 1:
			monster.direction = Vector2i(-1, 0)
		else:
			monster.direction = Vector2i.ZERO
			
		monsters.append(monster)
		
	var ghost_count = (10.0 / 2500) * map_size * map_size
	for i in range(ghost_count):
		var monster = Monster.new()
		monster.type = Monster.MonsterType.Ghost
		monster.beats_per_turn = 2
		monster.turn_timer = 8
		monster.health = 3
		monster.gold = 3
		monster.health_drop = 25
		monster.position = empty_map_spot()
		monster.home_position = monster.position
		monster.next_beat_position = monster.position
		monster.color = Color.hex(0xf3e3f7ff)
		monster.aggro = false
		
		monster.direction = Vector2i.ZERO
			
		monsters.append(monster)
	
	amulets = []
	amulets.append(Vector2i(6, 6))
	amulet_positions.append(Vector2i(6, 6))
	map[6][6] = 3
	amulets.append(Vector2i(6, map_size - 8))
	amulet_positions.append(Vector2i(6, map_size - 8))
	map[6][map_size - 8] = 3
	amulets.append(Vector2i(map_size - 8, 6))
	amulet_positions.append(Vector2i(map_size - 8, 6))
	map[map_size - 8][6] = 3
	
	# Pickups for the player - one weapon (spear or broadsword), three
	# armor drops (+1 temp HP) and three shovels (16 beats of free digs)
	weapon_positions = [empty_map_spot(), empty_map_spot()]
	weapon_types = [1, 2]
	armor_positions = [empty_map_spot(), empty_map_spot(), empty_map_spot(), empty_map_spot()]
	shovel_positions = [empty_map_spot(), empty_map_spot(), empty_map_spot(), empty_map_spot(), empty_map_spot()]
	
	

func empty_map_spot() -> Vector2i:
	var empty = false
	var pos = Vector2i.ZERO
	while not empty:
		pos = Vector2i(randi_range(0, map_size - 1), randi_range(0, map_size - 1))
		if not map[pos.y][pos.x] == 1 \
			&& not player.position == pos \
			&& not traps.any(func(x): return x.position == pos):
			
			empty = true
	return pos

# Used for proper cloning when copying game states for time travel purposes
func copy_to(other_state:GameState):
	
	player.copy_to(other_state.player)
	
	other_state.amulets = amulets.duplicate(true)
	for i in range(monsters.size()):
		if i >= other_state.monsters.size():
			var new_monster = Monster.new()
			monsters[i].copy_to(new_monster)
			other_state.monsters.append(new_monster)
		else:
			monsters[i].copy_to(other_state.monsters[i])
		
	while other_state.monsters.size() > monsters.size():
		other_state.monsters.remove_at(other_state.monsters.size() - 1)
	
	other_state.gold = gold.duplicate(true)
	other_state.map = map.duplicate(true)
	other_state.qr_map = qr_map.duplicate(true)
	other_state.health_potions = health_potions.duplicate(true)
	other_state.amulet_positions = amulet_positions.duplicate(true)
	other_state.is_collapsing = is_collapsing
	other_state.collapsing_timer = collapsing_timer
	other_state.player_hit_state = player_hit_state
	other_state.prev_hit_state = prev_hit_state
	other_state.player_moved = player_moved
	other_state.flash_map_walls = flash_map_walls
	other_state.flash_wall_extra = flash_wall_extra
	other_state.weapon_positions = weapon_positions
	other_state.weapon_types = weapon_types
	other_state.armor_positions = armor_positions.duplicate(true)
	other_state.shovel_positions = shovel_positions.duplicate(true)
