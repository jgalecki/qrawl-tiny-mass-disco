extends Resource
class_name Unit

@export var position:Vector2i
@export var health:int

# An example of how the imagined code structure differs from the actual code structure.
# Inherited by Player and Monster classes, but there's nothing that deals with Units abstractly.
