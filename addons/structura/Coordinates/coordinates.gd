@tool
extends Control
class_name Coordinates

@export var editor : StructuraEditor
@export var viewport : GraphViewport
@export var max_pool_size : int = 125
@export var position_offset : Vector2 = Vector2.ONE
@export var font : Font
@export var font_size : int = 14

var horizontal_pool : Array[Label]
var vertical_pool : Array[Label]

func _ready() -> void:
	generate_pool()

func refresh() -> void:
	draw_coordinates()

func generate_pool() -> void:
	
	horizontal_pool.resize(max_pool_size)
	vertical_pool.resize(max_pool_size)
	
	for i in range(max_pool_size):
		var label : Label = Label.new()
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_font_override("font",font)
		add_child(label)
		horizontal_pool[i] = label
	
	for i in range(max_pool_size):
		var label : Label = Label.new()
		label.add_theme_font_size_override("font_size", font_size)
		add_child(label)
		vertical_pool[i] = label

func draw_coordinates() -> void:
	clear_results()
	
	var step : int = editor.grid_size
	var cam_pos : Vector2 = viewport._camera_position
	var zoom : float = viewport._zoom
	
	var horizontal_left  : float = editor.to_world(Vector2.ZERO,cam_pos,zoom).x
	var horizontal_right : float = editor.to_world(Vector2(viewport.size.x,0),cam_pos,zoom).x
	var vertical_top     : float = editor.to_world(Vector2.ZERO,cam_pos,zoom).y
	var vertical_bottom  : float = editor.to_world(Vector2(0,viewport.size.y),cam_pos,zoom).y
	
	var start_x = floor(horizontal_left / step) * step
	var end_x   = ceil(horizontal_right / step) * step
	
	var start_y = floor(vertical_top / step) * step
	var end_y   = ceil(vertical_bottom / step) * step
	
	# Horizontal placement
	var index : int = 0
	for i in range(start_x,end_x,step):
		var label  : Label = horizontal_pool[index]
		var draw_pos : Vector2 = editor.to_screen(Vector2(i,vertical_top),cam_pos,zoom)
		if draw_pos.x > 0.0:
			label.position = draw_pos + Vector2(position_offset.x,0)
			label.text = "%s" % i
			index += 1
	
	index = 0
	
	for i in range(start_y,end_y,step):
		var label  : Label = vertical_pool[index]
		var draw_pos : Vector2 = editor.to_screen(Vector2(horizontal_left,i),cam_pos,zoom)
		if draw_pos.y > 0.0:
			label.position = draw_pos + Vector2(0,position_offset.y)
			label.text = "%s" % i
			index += 1

func clear_results() -> void:
	for i in horizontal_pool:
		i.text = ""
	
	for i in vertical_pool:
		i.text = ""
