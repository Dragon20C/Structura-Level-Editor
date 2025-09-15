@tool
extends ColorRect
class_name GraphViewport

#signal search_mesh(pixel_position : Vector2)
signal mesh_selected(mesh : GraphMesh)
signal clear_selection
#signal mesh_updated(mesh : GraphMesh)
#signal mesh_created(pos : Vector2)

enum Orientations {TOP,FRONT,SIDE}

const AXIS_COLORS = {
	"X": Color(0.8, 0.2, 0.2, 1.0),  # red
	"Y": Color(0.2, 0.8, 0.2, 1.0),  # green
	"Z": Color(0.2, 0.6, 0.9, 1.0)   # blue
}

@export var graph_editor : GraphEditor
@export var orientation : Orientations = Orientations.TOP
@export var coordinates : Coordinates
@export var orientation_l : Label

## Camera position is how we traverse the graph grid
var camera_position : Vector2 = Vector2.ZERO
## Zoom level is the zoom of the grid
var zoom_level : float = 1.0
## The ranges of the zoom level
var _min_zoom : float = 0.25
var _max_zoom : float = 5.0
## Unassigned world units variable
var _world_units : int = 0
var _grid_size : int = 0
var _is_dragging : bool = false
var _graph_data : GraphData

var graph_utils : GraphUtils

var drag_start_world := Vector2.ZERO
var drag_start_axes := []
var drag_grab_offset := Vector2.ZERO
var drag_mesh_size := Vector2.ZERO
var dragging_mesh : bool = false
var dragging_handle : bool = false
var drag_start_mouse := Vector2.ZERO
var drag_start_origin := Vector2.ZERO

var gizmo : GraphGizmo


func _ready() -> void:
	graph_utils = GraphUtils.new()
	
	gizmo = GraphGizmo.new()
	add_child(gizmo)
	mesh_selected.connect(gizmo.set_target)
	clear_selection.connect(gizmo.clear_target)
	
	match orientation:
		Orientations.TOP:
			orientation_l.text = "TOP"
		Orientations.SIDE:
			orientation_l.text = "SIDE"
		Orientations.FRONT:
			orientation_l.text = "FRONT"
	
	await get_tree().process_frame
	update()

#func _process(delta: float) -> void:
	#gizmo.set_view(camera_position, zoom_level, get_rect().size, graph_utils)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# --- Zooming ---
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			set_zoom(zoom_level * 1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			set_zoom(zoom_level * 0.9)

		# --- Panning (MMB) ---
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_is_dragging = event.pressed

		# --- Mesh / Gizmo (LMB) ---
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var mp = get_local_mouse_position()

				# First: try gizmo handle
				var handle = gizmo.pick_handle(mp)
				if handle != "":
					dragging_handle = true
					drag_start_mouse = mp

					# also tell gizmo about the world start pos for snapping
					var world_start = graph_utils.to_graph(mp, camera_position, zoom_level, get_rect().size)
					gizmo.begin_handle_drag(handle, world_start)
					return

				# Next: try dragging selected mesh
				if graph_editor.selected_mesh:
					var rect = get_screen_rect(graph_editor.selected_mesh, camera_position, zoom_level, get_rect().size, graph_utils)
					if rect.has_point(mp):
						# start dragging: record absolute start state (not only a mouse delta)
						dragging_mesh = true
						drag_start_mouse = mp
						drag_start_world = graph_utils.to_graph(mp, camera_position, zoom_level, get_rect().size)
						
						# store start axes & mesh size
						var axes = get_axes(graph_editor.selected_mesh)
						drag_start_axes = [axes[0], axes[1]] # horiz_range, vert_range
						var horiz_range = drag_start_axes[0]
						var vert_range  = drag_start_axes[1]
						drag_mesh_size = Vector2(horiz_range.y - horiz_range.x, vert_range.y - vert_range.x)

						# compute how far into the mesh the click was (top-left is world position)
						var top_left_world = Vector2(horiz_range.x, vert_range.x)
						drag_grab_offset = drag_start_world - top_left_world

						return

				# Otherwise: select a mesh under cursor
				select_mesh_at(mp)
				update()

			else:
				# Release LMB → stop dragging
				dragging_handle = false
				dragging_mesh = false

	elif event is InputEventMouseMotion:
		# --- Panning ---
		if _is_dragging:
			var delta_world = event.relative / zoom_level
			camera_position -= delta_world
			update()

		# --- Gizmo dragging ---
		elif dragging_handle:
			var current_world = graph_utils.to_graph(event.position, camera_position, zoom_level, get_rect().size)
			gizmo.apply_handle_drag_world(current_world, graph_editor.snapping_enabled, _grid_size)

			graph_editor._update_tooldock_ui()
			update()

		# --- Mesh dragging (absolute, not accumulating) ---
		elif dragging_mesh and graph_editor.selected_mesh:
			var mp = event.position
			var current_world = graph_utils.to_graph(mp, camera_position, zoom_level, get_rect().size)

			# desired top-left in world coords (preserve where the user grabbed the mesh)
			var desired_top_left = current_world - drag_grab_offset

			# apply snapping to the absolute top-left (prevents accumulation issues)
			if graph_editor.snapping_enabled:
				desired_top_left = graph_utils.snap_to_grid(desired_top_left, _grid_size)

			# build new ranges from top-left + original size
			var new_horiz = Vector2(desired_top_left.x, desired_top_left.x + drag_mesh_size.x)
			var new_vert  = Vector2(desired_top_left.y, desired_top_left.y + drag_mesh_size.y)

			# write them back depending on orientation
			match orientation:
				Orientations.TOP:
					graph_editor.selected_mesh.x_range = new_horiz
					graph_editor.selected_mesh.z_range = new_vert
				Orientations.FRONT:
					graph_editor.selected_mesh.x_range = new_horiz
					graph_editor.selected_mesh.y_range = new_vert
				Orientations.SIDE:
					graph_editor.selected_mesh.z_range = new_horiz
					graph_editor.selected_mesh.y_range = new_vert

			graph_editor._update_tooldock_ui()
			update()



#func _gui_input(event: InputEvent) -> void:
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			#set_zoom(zoom_level * 1.1)
			#
		#elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			#set_zoom(zoom_level * 0.9)
			#
		#elif event.button_index == MOUSE_BUTTON_MIDDLE:
			#_is_dragging = event.pressed
		#
		##if event is InputEventMouseButton and event.pressed:
			##var mouse_pos = event.position
			##var selected_mesh : GraphMesh = graph_editor.selected_mesh
			##if selected_mesh:
				##var rect = get_screen_rect(selected_mesh, camera_position, zoom_level, size, graph_utils)
				##var handle = _get_handle_at(mouse_pos, rect)
				##if handle != null:
					##active_handle = handle
				##elif rect.has_point(mouse_pos):
					##dragging_mesh = true
					##drag_offset = mouse_pos - rect.position
#
		#
		#elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			#var mp = get_local_mouse_position()
			#select_mesh_at(mp)
			#update()
			##var wpos = graph_utils.to_graph(mp,camera_position,zoom_level,size)#graph_utils.to_graph(camera_position, zoom_level, _world_units, size)
			##var back = graph_utils.to_pixel(wpos,camera_position,zoom_level, size)#graph_utils.to_pixel(camera_position, zoom_level, _world_units, size)
			##print("mouse_px:", mp, "  world:", wpos, "  pixel_back:", back)
			#
	#elif event is InputEventMouseMotion and _is_dragging:
		#var delta_world = event.relative / zoom_level
		#camera_position -= delta_world
		#update()
		
func update() -> void:
	queue_redraw()
	
	coordinates.set_view(zoom_level,camera_position)
	gizmo.set_view(camera_position, zoom_level, get_rect().size, graph_utils,orientation)
	#update_shader()

func set_zoom(new_zoom: float) -> void:
	zoom_level = clamp(new_zoom, _min_zoom, _max_zoom)
	update()

func set_world_units(world_units : int) -> void:
	_world_units = world_units
	graph_utils.set_world_unit_scale(_world_units)
	coordinates.set_world_units(_world_units)

func set_grid_scale(grid_size : int) -> void:
	_grid_size = grid_size
	coordinates.set_grid_size(_grid_size)

func set_graph_data(graph_data : GraphData) -> void:
	_graph_data = graph_data

#func update_shader() -> void:
	#material.set_shader_parameter("world_unit_scale",_world_units)
	#material.set_shader_parameter("camera_offset",camera_position)
	#material.set_shader_parameter("grid_size",_grid_size)
	#material.set_shader_parameter("zoom_level",zoom_level)
	#material.set_shader_parameter("control_size",size)

func _draw() -> void:
	draw_grid()
	draw_meshes()
	
	gizmo.queue_redraw()

func draw_grid() -> void:
	
	var grid_color : Color = Color(0.4, 0.4, 0.4, 1.0)
	
	var viewport_size = get_rect().size

	# Figure out the visible world rect
	var world_start = graph_utils.to_graph(Vector2.ZERO, camera_position, zoom_level, viewport_size)
	var world_end   = graph_utils.to_graph(viewport_size, camera_position, zoom_level, viewport_size)

	# Snap starting coordinates to nearest grid line
	var start_x = floor(world_start.x / _grid_size) * _grid_size
	var start_y = floor(world_start.y / _grid_size) * _grid_size

	# Vertical lines
	var x = start_x
	while x <= world_end.x:
		var p1 = graph_utils.to_pixel(Vector2(x, world_start.y), camera_position, zoom_level, viewport_size)
		var p2 = graph_utils.to_pixel(Vector2(x, world_end.y),   camera_position, zoom_level, viewport_size)
		p1 = clamp(p1,Vector2.ZERO,Vector2.INF)
		p2 = clamp(p2,Vector2.ZERO,Vector2.INF)
		draw_line(p1, p2, grid_color)
		x += _grid_size

	# Horizontal lines
	var y = start_y
	while y <= world_end.y:
		var p1 = graph_utils.to_pixel(Vector2(world_start.x, y), camera_position, zoom_level, viewport_size)
		var p2 = graph_utils.to_pixel(Vector2(world_end.x, y),   camera_position, zoom_level, viewport_size)
		draw_line(p1, p2, grid_color)
		y += _grid_size
	
	# --- Axis lines ---
	var origin_pixel = graph_utils.to_pixel(Vector2.ZERO, camera_position, zoom_level, get_rect().size)

	var axes = get_orientation_axes()
	var horiz_axis = axes[0]
	var vert_axis  = axes[1]

	# Vertical axis (second axis in mapping)
	draw_line(
		Vector2(origin_pixel.x, 0),
		Vector2(origin_pixel.x, get_rect().size.y),
		AXIS_COLORS[vert_axis],
		2.0
	)

	# Horizontal axis (first axis in mapping)
	draw_line(
		Vector2(0, origin_pixel.y),
		Vector2(get_rect().size.x, origin_pixel.y),
		AXIS_COLORS[horiz_axis],
		2.0
	)

func draw_meshes() -> void:
	for mesh in _graph_data.data:
		# pick the right 2D axes for current orientation
		var axes = get_axes(mesh)
		var horiz_range: Vector2 = axes[0]
		var vert_range: Vector2  = axes[1]

		# compute rect in world space from ranges
		var top_left_world = Vector2(horiz_range.x, vert_range.x)
		var size = Vector2(horiz_range.y - horiz_range.x, vert_range.y - vert_range.x)
		var rect_world = Rect2(top_left_world, size)

		# convert to screen space
		var top_left_screen = graph_utils.to_pixel(rect_world.position, camera_position, zoom_level, get_rect().size)
		var bottom_right_screen = graph_utils.to_pixel(rect_world.position + rect_world.size, camera_position, zoom_level, get_rect().size)

		var rect = Rect2(top_left_screen, bottom_right_screen - top_left_screen)

		# coloring
		var fill_color = Color(0.7, 0.7, 0.7, 0.3)
		var outline_color = Color(0.9, 0.9, 0.9)
		if mesh == graph_editor.selected_mesh:
			fill_color = Color(0.2, 0.6, 1.0, 0.3)
			outline_color = Color(0.2, 0.6, 1.0)

		draw_rect(rect, fill_color, true)
		draw_rect(rect, outline_color, false)
		
		# selection corner markers
		if mesh == graph_editor.selected_mesh:
			var handle_size = 6
			for corner in [rect.position,
						   rect.position + Vector2(rect.size.x, 0),
						   rect.position + Vector2(0, rect.size.y),
						   rect.position + rect.size]:
				draw_rect(Rect2(corner - Vector2(handle_size/2, handle_size/2),
								Vector2(handle_size, handle_size)),
						  Color(1, 1, 0), true)





func select_mesh_at(pixel_position : Vector2) -> void:
	var data : Array[GraphMesh] = _graph_data.data

	for mesh in data:
		var rect = get_screen_rect(mesh, camera_position, zoom_level, get_rect().size, graph_utils)
		if rect.has_point(pixel_position):
			# Found a mesh under the cursor
			mesh_selected.emit(mesh)
			return

	# If nothing found
	clear_selection.emit()


func get_screen_rect(mesh: GraphMesh, camera_position: Vector2, zoom: float, viewport_size: Vector2, utils: GraphUtils) -> Rect2:
	var axes = get_axes(mesh)
	var horiz_range: Vector2 = axes[0]
	var vert_range: Vector2  = axes[1]

	# rect in world space from ranges
	var top_left_world = Vector2(horiz_range.x, vert_range.x)
	var size = Vector2(horiz_range.y - horiz_range.x, vert_range.y - vert_range.x)

	# convert to screen space
	var top_left_screen = utils.to_pixel(top_left_world, camera_position, zoom, viewport_size)
	var bottom_right_screen = utils.to_pixel(top_left_world + size, camera_position, zoom, viewport_size)

	return Rect2(top_left_screen, bottom_right_screen - top_left_screen)

func get_axes(mesh: GraphMesh) -> Array:
	match orientation:
		Orientations.TOP:
			return [mesh.x_range, mesh.z_range]
		Orientations.FRONT:
			return [mesh.x_range, mesh.y_range]
		Orientations.SIDE:
			return [mesh.z_range, mesh.y_range]
		_:
			return []

func get_orientation_axes() -> Array:
	match orientation:
		Orientations.TOP:
			return ["X", "Z"]   # horizontal X, vertical Z
		Orientations.FRONT:
			return ["X", "Y"]   # horizontal X, vertical Y
		Orientations.SIDE:
			return ["Z", "Y"]   # horizontal Z, vertical Y
		_:
			return []
