@tool
extends ColorRect
class_name GraphViewport

enum Orientations {TOP,SIDE,FRONT}

const AXIS_COLORS = {
	"X": Color(0.8, 0.2, 0.2, 1.0),  # red
	"Y": Color(0.2, 0.8, 0.2, 1.0),  # green
	"Z": Color(0.2, 0.6, 0.9, 1.0)   # blue
}

@export var orientation : Orientations = Orientations.TOP
@export var grid_line_color : Color = Color(0.4,0.4,0.4)
@export var coordinates : Coordinates
@export var orientation_l : Label

@export var _editor : StructuraEditor
var _camera_position : Vector2 = Vector2.ZERO
var _zoom : float = 1.0
var _is_panning : bool = false

func _ready() -> void:
	match orientation:
		Orientations.TOP:
			orientation_l.text = "TOP"
		Orientations.SIDE:
			orientation_l.text = "SIDE"
		Orientations.FRONT:
			orientation_l.text = "FRONT"

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# --- Zooming ---
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			set_zoom(_zoom * 1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			set_zoom(_zoom * 0.9)
		
		# --- Panning (MMB) ---
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			_is_panning = event.pressed
		#elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			#var local_mouse : Vector2 = get_local_mouse_position()
			#var world : Vector2 = _editor.to_world(local_mouse,_camera_position,_zoom)
			#print("X: %.1f, Y: %.1f" % [world.x, world.y])
		refresh()
	elif event is InputEventMouseMotion:
		# --- Panning ---
		if _is_panning:
			var scaler = _editor.world_unit_scale * _zoom
			var delta_world = event.relative / scaler
			_camera_position -= delta_world
	
			refresh()

func _draw() -> void:
	draw_graph()
	draw_meshes()

# A simple function for updating the whole viewport
func refresh() -> void:
	queue_redraw()
	coordinates.refresh()

func set_zoom(new_zoom: float, pivot: Vector2 = get_local_mouse_position()) -> void:
	# World position under mouse BEFORE zoom
	var world_before = _editor.to_world(pivot, _camera_position, _zoom)

	# Apply zoom
	_zoom = clampf(new_zoom, 0.25, 4.0)

	# World position under mouse AFTER zoom
	var world_after = _editor.to_world(pivot, _camera_position, _zoom)

	# Adjust camera so the mouse stays on the same world spot
	_camera_position += (world_before - world_after)

func draw_graph() -> void:
	var world_min = _editor.to_world(Vector2.ZERO, _camera_position, _zoom)
	var world_max = _editor.to_world(size, _camera_position, _zoom)

	var step = _editor.grid_size
	var rect = Rect2(Vector2.ZERO, size)

	# Vertical lines
	var start_x = floor(world_min.x / step) * step
	var end_x   = ceil(world_max.x / step) * step
	for x in range(int(start_x), int(end_x)+1, step):
		var p1 = _editor.to_screen(Vector2(x, world_min.y), _camera_position, _zoom)
		var p2 = _editor.to_screen(Vector2(x, world_max.y), _camera_position, _zoom)

		p1 = p1.clamp(rect.position, rect.end)
		p2 = p2.clamp(rect.position, rect.end)

		draw_line(p1, p2, grid_line_color, 1)

	# Horizontal lines
	var start_y = floor(world_min.y / step) * step
	var end_y   = ceil(world_max.y / step) * step
	for y in range(int(start_y), int(end_y)+1, step):
		var p1 = _editor.to_screen(Vector2(world_min.x, y), _camera_position, _zoom)
		var p2 = _editor.to_screen(Vector2(world_max.x, y), _camera_position, _zoom)

		p1 = p1.clamp(rect.position, rect.end)
		p2 = p2.clamp(rect.position, rect.end)

		draw_line(p1, p2, grid_line_color, 1)
	
	# Axis lines
	var origin : Vector2 = _editor.to_screen(Vector2.ZERO,_camera_position,_zoom)
	
	var axes = get_orientation_axes()
	var horiz_axis = axes[0]
	var vert_axis  = axes[1]
	
	#vertical line
	if origin.x > 0 and origin.x < size.x:
		draw_line(Vector2(origin.x,0),Vector2(origin.x,size.y),AXIS_COLORS[vert_axis],2.0)
	
	#hoizontal line
	if origin.y > 0 and origin.y < size.y:
		draw_line(Vector2(0,origin.y),Vector2(size.x,origin.y),AXIS_COLORS[horiz_axis],2.0)

func draw_meshes() -> void:
	for mesh in _editor.level_data.data:
		
		var rect : Rect2
		
		match orientation:
			Orientations.TOP:
				rect = mesh.get_top_view_rect()
			Orientations.SIDE:
				rect = mesh.get_side_view_rect()
			Orientations.FRONT:
				rect = mesh.get_front_view_rect()
		# Top-left and bottom-right corners in world space
		var p1 = rect.position
		var p2 = rect.position + rect.size

		# Convert to screen space
		var s1 = _editor.to_screen(p1, _camera_position, _zoom)
		var s2 = _editor.to_screen(p2, _camera_position, _zoom)
		
		# To avoid drawing off screen
		if s2.x < 0 or s2.y < 0:
			continue
		# To avoid drawing off screen
		if s1.x > size.x or s1.y > size.y:
			continue
		
		s1 = s1.clamp(Vector2.ZERO,size)
		s2 = s2.clamp(Vector2.ZERO,size)
		
		# Build rect from transformed corners
		var screen_rect = Rect2(s1, s2 - s1).abs()
		
		# coloring
		var fill_color = Color(0.7, 0.7, 0.7, 0.3)
		var outline_color = Color(0.9, 0.9, 0.9)
		if mesh == _editor.selected_mesh:
			fill_color = Color(0.2, 0.6, 1.0, 0.3)
			outline_color = Color(0.2, 0.6, 1.0)
		
		#print(screen_rect)
		draw_rect(screen_rect, fill_color, true)
		draw_rect(screen_rect, outline_color, false)


func get_orientation_axes() -> Array[String]:
	match orientation:
		Orientations.TOP:
			return ["X", "Z"]   # horizontal X, vertical Z
		Orientations.FRONT:
			return ["X", "Y"]   # horizontal X, vertical Y
		Orientations.SIDE:
			return ["Z", "Y"]   # horizontal Z, vertical Y
		_:
			return []


func _on_item_rect_changed() -> void:
	if _camera_position.is_equal_approx(Vector2.ZERO):
		_camera_position = -_editor.to_world(size / 2.0,_camera_position,_zoom)
		refresh()
