extends Node
class_name DisplayArray

# Base class for displaying the game in 16x9 pixels. A lot of setup, but
# set_pixel() is the only function you'll really need.

@export var row_a:Node2D
@export var row_b:Node2D
@export var row_c:Node2D
@export var row_d:Node2D
@export var row_e:Node2D
@export var row_f:Node2D
@export var row_g:Node2D
@export var row_h:Node2D
@export var row_i:Node2D

var _display:Array[Array]

func _ready() -> void:
	_display = []
	
	var a:Array[Sprite2D] = []
	for child in row_a.get_children():
		a.append(child as Sprite2D)
	_display.append(a)
		
	var b:Array[Sprite2D] = []
	for child in row_b.get_children():
		b.append(child as Sprite2D)
	_display.append(b)
	
	var c:Array[Sprite2D] = []
	for child in row_c.get_children():
		c.append(child as Sprite2D)
	_display.append(c)
	
	var d:Array[Sprite2D] = []
	for child in row_d.get_children():
		d.append(child as Sprite2D)
	_display.append(d)
	
	var e:Array[Sprite2D] = []
	for child in row_e.get_children():
		e.append(child as Sprite2D)
	_display.append(e)
	
	var f:Array[Sprite2D] = []
	for child in row_f.get_children():
		f.append(child as Sprite2D)
	_display.append(f)
	
	var g:Array[Sprite2D] = []
	for child in row_g.get_children():
		g.append(child as Sprite2D)
	_display.append(g)
	
	var h:Array[Sprite2D] = []
	for child in row_h.get_children():
		h.append(child as Sprite2D)
	_display.append(h)
	
	var i:Array[Sprite2D] = []
	for child in row_i.get_children():
		i.append(child as Sprite2D)
	_display.append(i)
	
func get_pixel(x:int, y:int) -> Sprite2D:
	assert(y >= 0 && y < _display.size())
	assert(x >= 0 && x < _display[0].size()) # _display.size() at least 1, guaranteed by assert above.
	return _display[y][x] as Sprite2D

func set_color(x:int, y:int, color:Color):
	var pixel = get_pixel(x, y)
	pixel.modulate = color
	
