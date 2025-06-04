extends Unit
class_name Player

# health is in Unit
var combo:int # Ranges 0 - 4
var keeping_beat_combo:int # Ranges 0 - 4
var digs:int # Ranges 0 - 8
var gold:int # No range
var amulets:int

var shovel_beats:int
var armor:int
var weapon_type:int


var just_hit:bool

# Used for proper cloning when copying game states for time travel purposes
func copy_to(other_player:Player):
	other_player.combo = combo
	other_player.keeping_beat_combo = keeping_beat_combo
	other_player.digs = digs
	other_player.gold = gold
	other_player.amulets = amulets
	other_player.just_hit = just_hit
	other_player.position = position
	other_player.health = health
	other_player.shovel_beats = shovel_beats
	other_player.armor = armor
	other_player.weapon_type = weapon_type
