@tool
extends Node2D
class_name GraphGizmo

var target_mesh: GraphMesh = null
var orientation: int = 0   # GraphViewport.Orientations.TOP/FRONT/SIDE

var handles := {}
var selected_handle: String = ""

@export var handle_size := 6.0
@export var color_x := Color(0.9, 0.2, 0.2)
@export var color_y := Color(0.2, 0.9, 0.2)
@export var color_z := Color(0.2, 0.6, 0.9)

var camera_pos: Vector2 = Vector2.ZERO
var zoom: float = 1.0
var viewport_size: Vector2 = Vector2.ZERO
var graph_utils: GraphUtils
var drag_start_world: Vector2 = Vector2.ZERO
@export var handle_offset := 12.0

func set_target(mesh: GraphMesh) -> void:
	target_mesh = mesh
	_update_handles()
	queue_redraw()

func clear_target() -> void:
	target_mesh = null
	handles.clear()
	selected_handle = ""
	queue_redraw()

func set_view(camera_position: Vector2, zoom_level: float, vp_size: Vector2, utils: GraphUtils, orient: int) -> void:
	camera_pos = camera_position
	zoom = zoom_level
	viewport_size = vp_size
	graph_utils = utils
	orientation = orient
	_update_handles()
	queue_redraw()

func _update_handles() -> void:
	handles.clear()
	if not target_mesh:
		return

	var axes = _get_axes()
	var horiz_range: Vector2 = axes[0]  # min.x, max.x
	var vert_range: Vector2  = axes[1]  # min.y, max.y

	var center_y = (vert_range.x + vert_range.y) * 0.5
	var center_x = (horiz_range.x + horiz_range.y) * 0.5

	# Handles positioned at the middle of each edge
	# Handles positioned at the middle of each edge
	var left_world   = Vector2(horiz_range.x, center_y)
	var right_world  = Vector2(horiz_range.y, center_y)
	var top_world    = Vector2(center_x, vert_range.x)
	var bottom_world = Vector2(center_x, vert_range.y)

	var left_screen   = graph_utils.to_pixel(left_world, camera_pos, zoom, viewport_size)  - Vector2(handle_offset, 0)
	var right_screen  = graph_utils.to_pixel(right_world, camera_pos, zoom, viewport_size) + Vector2(handle_offset, 0)
	var top_screen    = graph_utils.to_pixel(top_world, camera_pos, zoom, viewport_size)   - Vector2(0, handle_offset)
	var bottom_screen = graph_utils.to_pixel(bottom_world, camera_pos, zoom, viewport_size)+ Vector2(0, handle_offset)

	handles["left"]   = Rect2(left_screen - Vector2.ONE * handle_size, Vector2.ONE * handle_size * 2)
	handles["right"]  = Rect2(right_screen - Vector2.ONE * handle_size, Vector2.ONE * handle_size * 2)
	handles["top"]    = Rect2(top_screen - Vector2.ONE * handle_size, Vector2.ONE * handle_size * 2)
	handles["bottom"] = Rect2(bottom_screen - Vector2.ONE * handle_size, Vector2.ONE * handle_size * 2)


func _draw() -> void:
	if not target_mesh:
		return
	
	for key in handles.keys():
		var rect: Rect2 = handles[key]
		var center = rect.get_center()
		var col: Color
		match key:
			"left", "right":
				col = color_x  # horizontal axis
			"top", "bottom":
				col = color_z if orientation == GraphViewport.Orientations.TOP else color_y
			_:
				col = Color.WHITE
		
		draw_circle(center, handle_size, col)



func pick_handle(mouse_pos: Vector2) -> String:
	for key in handles.keys():
		if handles[key].has_point(mouse_pos):
			selected_handle = key
			return key
	selected_handle = ""
	return ""

func apply_handle_drag_world(current_world: Vector2, snapping_enabled: bool, grid_size: float) -> void:
	if not target_mesh or selected_handle == "":
		return

	var axes = _get_axes()
	var horiz_range: Vector2 = axes[0]
	var vert_range: Vector2  = axes[1]

	# Optionally snap
	if snapping_enabled:
		current_world = graph_utils.snap_to_grid(current_world, grid_size)

	match selected_handle:
		"left":
			horiz_range.x = current_world.x
		"right":
			horiz_range.y = current_world.x
		"top":
			vert_range.x = current_world.y
		"bottom":
			vert_range.y = current_world.y

	# Prevent inversion
	if horiz_range.x > horiz_range.y:
		horiz_range.x = horiz_range.y
	if vert_range.x > vert_range.y:
		vert_range.x = vert_range.y

	# write back
	var h_axis = _get_horizontal_axis_name()
	var v_axis = _get_vertical_axis_name()
	target_mesh.set(h_axis, horiz_range)
	target_mesh.set(v_axis, vert_range)

	_update_handles()
	queue_redraw()

func begin_handle_drag(handle: String, start_world: Vector2) -> void:
	selected_handle = handle
	drag_start_world = start_world


#func apply_handle_drag(delta_pixels: Vector2) -> void:
	#if not target_mesh or selected_handle == "":
		#return
#
	#var graph_delta = delta_pixels / zoom / graph_utils.world_unit_scale
	#var axes = _get_axes()
	#var horiz_range: Vector2 = axes[0]
	#var vert_range: Vector2  = axes[1]
#
	#match selected_handle:
		#"left":
			#horiz_range.x += graph_delta.x
		#"right":
			#horiz_range.y += graph_delta.x
		#"top":
			#vert_range.x += graph_delta.y   # invert for top
		#"bottom":
			#vert_range.y += graph_delta.y   # invert for bottom
#
	## Prevent inversion (optional safeguard)
	#if horiz_range.x > horiz_range.y:
		#horiz_range.x = horiz_range.y
	#if vert_range.x > vert_range.y:
		#vert_range.x = vert_range.y
#
	## write back
	#var h_axis = _get_horizontal_axis_name()
	#var v_axis = _get_vertical_axis_name()
	#target_mesh.set(h_axis, horiz_range)
	#target_mesh.set(v_axis, vert_range)
#
	#_update_handles()
	#queue_redraw()


# --- helpers ---
func _get_axes() -> Array:
	match orientation:
		GraphViewport.Orientations.TOP:
			return [target_mesh.x_range, target_mesh.z_range]
		GraphViewport.Orientations.FRONT:
			return [target_mesh.x_range, target_mesh.y_range]
		GraphViewport.Orientations.SIDE:
			return [target_mesh.z_range, target_mesh.y_range]
		_:
			return [Vector2.ZERO, Vector2.ZERO]

func _get_horizontal_axis_name() -> String:
	match orientation:
		GraphViewport.Orientations.TOP: return "x_range"
		GraphViewport.Orientations.FRONT: return "x_range"
		GraphViewport.Orientations.SIDE: return "z_range"
		_: return ""

func _get_vertical_axis_name() -> String:
	match orientation:
		GraphViewport.Orientations.TOP: return "z_range"
		GraphViewport.Orientations.FRONT: return "y_range"
		GraphViewport.Orientations.SIDE: return "y_range"
		_: return ""
