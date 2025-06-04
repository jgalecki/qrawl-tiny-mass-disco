extends AudioStreamPlayer

class_name SoundPlayer

# Simple sound player. Will need to add your own sound files, since
# I don't have the copyright on the ones in the official Qrawl: Tiny Mass Disco
# game - just a license.

enum Sfxs { PlayerAttack, MonsterHit, MonsterDeath, FireTrapHit, WallDig, WallBump, \
			GoldPickup, AmuletPickup, Victory, GameOver, BadHit, MissedHit, Dodge, \
			HealthPickup, GearPickup }

#@export var ui_confirm:AudioStream
#@export var ui_cancel:AudioStream
#@export var ui_fail:AudioStream
#
#@export var player_attack:AudioStream
#@export var monster_hit:AudioStream
#@export var monster_death:AudioStream
#@export var fire_trap_hit:AudioStream
#@export var wall_dig:AudioStream
#@export var wall_bump:AudioStream
#@export var gold_pickup:AudioStream
#@export var amulet_pickup:AudioStream
#@export var victory:AudioStream
#@export var game_over:AudioStream
#@export var bad_hit:AudioStream
#@export var missed_hit:AudioStream
#@export var dodge:AudioStream
#@export var health_pickup:AudioStream
#@export var gear_pickup:AudioStream



var volume:int

func play_confirm():
	pass
	#stream = ui_confirm
	#play()
	
func play_cancel():
	pass
	#stream = ui_cancel
	#play()
	
func play_fail():
	pass
	#stream = ui_fail
	#play()
	
	
func player_sfx(sfx:Sfxs):
	pass
	#match sfx:
		#Sfxs.PlayerAttack:
			#stream = player_attack
		#Sfxs.MonsterHit:
			#stream = monster_hit
		#Sfxs.MonsterDeath:
			#stream = monster_death
		#Sfxs.FireTrapHit:
			#stream = fire_trap_hit
		#Sfxs.WallDig:
			#stream = wall_dig
		#Sfxs.WallBump:
			#stream = wall_bump
		#Sfxs.GoldPickup:
			#stream = gold_pickup
		#Sfxs.AmuletPickup:
			#stream = amulet_pickup
		#Sfxs.Victory:
			#stream = victory
		#Sfxs.GameOver:
			#stream = game_over
		#Sfxs.BadHit:
			#stream = bad_hit
		#Sfxs.MissedHit:
			#stream = bad_hit #	
		#Sfxs.Dodge:
			#stream = dodge
		#Sfxs.HealthPickup:
			#stream = health_pickup
		#Sfxs.GearPickup:
			#stream = gear_pickup
	#play()

func change_volume(value):
	print("volume is now " + str(value))
	volume = value
	match volume:
		0:
			volume_db = -80
		1:
			volume_db = -40
		2:
			volume_db = -20
		3:
			volume_db = -10
		4:
			volume_db = -7.5
		5:
			volume_db = -5
		6:
			volume_db = -3.75
		7:
			volume_db = -2.5
		8:
			volume_db = -1
		9:
			volume_db = -0.5
		10:
			volume_db = 0
