@tool
extends Control
class_name Coordinates

@export var step_world: float = 1.0       # spacing in world units
@export var world_unit_scale: float = 10  # pixels per world unit
@export var font_size: int = 14
@export var offset: Vector2 = Vector2.ZERO

var zoom: float = 1.0
var camera_position: Vector2 = Vector2.ZERO   # world coords at screen center

var x_labels: Array[Label] = []
var y_labels: Array[Label] = []

var graph_utils : GraphUtils


func _ready() -> void:
	graph_utils = GraphUtils.new()
	graph_utils.set_world_unit_scale(world_unit_scale)


func set_view(new_zoom: float, new_position: Vector2) -> void:
	zoom = new_zoom
	camera_position = new_position
	_update_labels()


func _update_labels() -> void:
	var rect_size = get_rect().size

	# --- compute visible world extents ---
	var world_left   = graph_utils.to_graph(Vector2(0, 0), camera_position, zoom, rect_size).x
	var world_right  = graph_utils.to_graph(Vector2(rect_size.x, 0), camera_position, zoom, rect_size).x
	var world_top    = graph_utils.to_graph(Vector2(0, 0), camera_position, zoom, rect_size).y
	var world_bottom = graph_utils.to_graph(Vector2(0, rect_size.y), camera_position, zoom, rect_size).y

	var start_world_x = floor(world_left / step_world) * step_world
	var end_world_x   = world_right
	var start_world_y = floor(world_top / step_world) * step_world
	var end_world_y   = world_bottom

	# --- how many labels needed ---
	var needed_x = int((end_world_x - start_world_x) / step_world) + 2
	var needed_y = int((end_world_y - start_world_y) / step_world) + 2

	# --- grow pools if needed ---
	while x_labels.size() < needed_x:
		var label = Label.new()
		label.add_theme_font_size_override("font_size", font_size)
		add_child(label)
		x_labels.append(label)

	while y_labels.size() < needed_y:
		var label = Label.new()
		label.add_theme_font_size_override("font_size", font_size)
		add_child(label)
		y_labels.append(label)

	# --- update/reuse X labels ---
	var x = start_world_x
	for i in range(needed_x):
		var screen_pos = graph_utils.to_pixel(Vector2(x, 0), camera_position, zoom, rect_size)
		var label = x_labels[i]
		label.text = str(int(x))
		label.position = Vector2(screen_pos.x + offset.x, 0)
		label.show()
		x += step_world

	# hide extra
	for i in range(needed_x, x_labels.size()):
		x_labels[i].hide()

	# --- update/reuse Y labels ---
	var y = start_world_y
	for i in range(needed_y):
		var screen_pos = graph_utils.to_pixel(Vector2(0, y), camera_position, zoom, rect_size)
		var label = y_labels[i]
		label.text = str(int(y))
		label.position = Vector2(0, screen_pos.y + offset.y)
		label.show()
		y += step_world

	# hide extra
	for i in range(needed_y, y_labels.size()):
		y_labels[i].hide()

func set_grid_size(grid_size : int) -> void:
	step_world = grid_size

func set_world_units(world_unit : float) -> void:
	world_unit_scale = world_unit
	graph_utils.set_world_unit_scale(world_unit_scale)
