extends Resource
class_name Trap

enum TrapType { FireTrap }

@export var type:TrapType
@export var position:Vector2i
@export var fire_on_1:bool
@export var fire_on_3:bool

@export var fireball_on_1:bool
