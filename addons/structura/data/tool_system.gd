@tool
extends Control
class_name ToolSystem

enum Axes {TOP,BOTTOM,RIGHT,LEFT}
enum ToolMode { SELECT, CREATE, MOVE, SCALE }
var current_tool: ToolMode = ToolMode.SELECT

enum InteractionState { IDLE, SELECTING, MOVING, SCALING}
var interaction_state: InteractionState = InteractionState.IDLE

@export var editor : StructuraEditor
@export var viewport : GraphViewport

var drag_start_world : Vector2
var create_start_world : Vector2
var create_end_world : Vector2
var active_axis : Axes
# Add next to press_pos / press_mesh etc.
var create_pending : bool = false

var selection_cycle : Array = []
var selection_index : int = 0


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEvent and current_tool == ToolMode.SELECT:
		if event.keycode == KEY_D and event.pressed and editor.selected_mesh:
			editor.level_data.remove_mesh(editor.selected_mesh)
			editor.selected_mesh = null
			editor.refresh_viewports()

func _gui_input(event: InputEvent) -> void:
	match current_tool:
		ToolMode.SELECT:
			handle_select(event)
		ToolMode.CREATE:
			handle_create(event)
		ToolMode.MOVE:
			handle_move(event)
		ToolMode.SCALE:
			handle_scale(event)

var press_pos : Vector2
var press_mesh : GraphMesh
var drag_threshold := 4.0
var is_dragging := false

func handle_select(event: InputEvent) -> void:
	# Only care about left mouse interactions for select/create start
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# record press info
			press_pos = event.position
			is_dragging = false
			create_pending = false
			press_mesh = null

			# compute world pos and test handles/hits immediately on press
			var world_pos : Vector2 = editor.to_world(event.position, viewport._camera_position, viewport._zoom)

			# if over a handle -> go straight to SCALE mode (priority)
			var handle = get_handle_under_mouse(event.position)
			if not handle.is_empty():
				active_axis = handle["name"]
				set_tool(ToolMode.SCALE)
				return

			# collect meshes under the cursor (sorted by depth)
			var hits = find_meshes_sorted(world_pos)

			if hits.size() > 0:
				# store the top hit under the cursor for potential drag
				press_mesh = hits[0]["mesh"]
				# NOTE: we do NOT change selection yet; selection happens on click (mouse release)
				# but we do set up selection_cycle so click will cycle properly later
				var hit_meshes = hits.map(func(x): return x["mesh"])
				if selection_cycle != hit_meshes:
					selection_cycle = hit_meshes
					selection_index = 0
			else:
				# nothing hit: prepare to create. We will actually create on drag (or on click release)
				create_pending = true
				if editor.snapping:
					create_start_world = editor.snap_world(world_pos)
				else:
					create_start_world = world_pos

		else:
			# Mouse released
			# If the user didn't drag, treat as a click
			if not is_dragging:
				# If we had a create pending (pressed on empty space) we want to create a new mesh
				# immediately (with minimum size) and enter SELECT (or keep CREATE briefly)
				_process_click(event.position)
			# reset press state
			press_mesh = null
			create_pending = false

	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT != 0:
		# If movement exceeds threshold, treat as drag
		if not is_dragging and press_pos.distance_to(event.position) > drag_threshold:
			is_dragging = true

			# If we pressed on an existing mesh and it's the currently selected mesh -> start move
			if press_mesh and press_mesh == editor.selected_mesh:
				var world_pos : Vector2 = editor.to_world(event.position, viewport._camera_position, viewport._zoom)
				drag_start_world = world_pos
				set_tool(ToolMode.MOVE)
				return

			# If we pressed empty space and creation is pending -> create a new mesh and start CREATE mode
			if create_pending and press_mesh == null:
				# Make new mesh and select it
				var new_mesh : GraphMesh = GraphMesh.new()
				editor.level_data.add_mesh(new_mesh)
				editor.selected_mesh = new_mesh

				# ensure create_start_world is set (it was set on press)
				# switch to CREATE mode so handle_create handles the drag resizing
				set_tool(ToolMode.CREATE)
				editor.refresh_viewports()
				return

func _process_click(mouse_pos: Vector2) -> void:
	var world_pos : Vector2 = editor.to_world(mouse_pos, viewport._camera_position, viewport._zoom)

	# Handle scale handle click first
	var handle = get_handle_under_mouse(mouse_pos)
	if not handle.is_empty():
		active_axis = handle["name"]
		set_tool(ToolMode.SCALE)
		return

	# find meshes under the mouse
	var hits = find_meshes_sorted(world_pos)
	if hits.size() > 0:
		# cycle selection among the meshes under cursor
		var hit_meshes = hits.map(func(x): return x["mesh"])
		if selection_cycle != hit_meshes:
			selection_cycle = hit_meshes
			selection_index = 0

		if editor.selected_mesh and editor.selected_mesh in selection_cycle:
			selection_index = (selection_cycle.find(editor.selected_mesh) + 1) % selection_cycle.size()
		else:
			selection_index = 0

		editor.selected_mesh = selection_cycle[selection_index]
		editor.refresh_viewports()
		return

	# nothing hit -> CLICK on empty space: create a new mesh and enter CREATE mode so user can drag to size
	var new_mesh : GraphMesh = GraphMesh.new()
	editor.level_data.add_mesh(new_mesh)
	editor.selected_mesh = new_mesh

	# set up create_start_world (snap if enabled)
	if editor.snapping:
		create_start_world = editor.snap_world(world_pos)
	else:
		create_start_world = world_pos

	# Enter CREATE mode; user can immediately drag to resize
	set_tool(ToolMode.CREATE)
	editor.refresh_viewports()


func handle_move(event: InputEvent) -> void:
	if editor.selected_mesh == null:
		return

	# end move on mouse release
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
		set_tool(ToolMode.SELECT)
		return

	if event is InputEventMouseMotion:
		var mouse_world: Vector2 = editor.to_world(event.position, viewport._camera_position, viewport._zoom)

		# Read axes from mesh for current viewport (Vector2(min,max) pairs)
		var axes: Array = editor.selected_mesh.get_axes(viewport) # [axis0, axis1]
		var width: float = axes[0].y - axes[0].x
		var height: float = axes[1].y - axes[1].x


		var target_min: Vector2
		if editor.snapping:
			# Snap the reference corner (min) directly to grid under mouse
			target_min = editor.snap_world(mouse_world)
		else:
			# Delta-based movement (smooth drag)
			var delta: Vector2 = mouse_world - drag_start_world
			target_min = Vector2(axes[0].x + delta.x, axes[1].x + delta.y)
			# update drag start for incremental movement
			drag_start_world = mouse_world

		# Build new axes preserving size
		var new_axes : Array[Vector2] = [
			Vector2(target_min.x, target_min.x + width),
			Vector2(target_min.y, target_min.y + height)
		]

		# Commit changes into the mesh
		editor.selected_mesh.set_axes(viewport, new_axes)

		# Redraw viewport
		editor.refresh_viewports()

func handle_create(event : InputEvent) -> void:
	# early exit
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			editor.level_data.remove_mesh(editor.selected_mesh)
			editor.refresh_viewports()
			set_tool(ToolMode.SELECT)
			return
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			set_tool(ToolMode.SELECT)
			return
	
	# detect mouse movement and check if its greater then the min size of 5x5
	if event is InputEventMouseMotion:
		create_end_world = editor.to_world(event.position, viewport._camera_position, viewport._zoom)
		
		if editor.snapping:
			create_end_world = editor.snap_world(create_end_world)
		
		var min_x = min(create_start_world.x, create_end_world.x)
		var max_x = max(create_start_world.x, create_end_world.x)
		var min_y = min(create_start_world.y, create_end_world.y)
		var max_y = max(create_start_world.y, create_end_world.y)
		
		var step : int = editor.grid_size
		
		if max_x - min_x < step:
			max_x = min_x + step
		if max_y - min_y < 5:
			max_y = min_y + step
		
		var new_x = Vector2(min_x, max_x)
		var new_y = Vector2(min_y, max_y)
		
		var new_axes : Array[Vector2] = [new_x,new_y]
		
		editor.selected_mesh.set_axes(viewport, new_axes)
		
		editor.refresh_viewports()

func handle_scale(event : InputEvent) -> void:
	if editor.selected_mesh == null:
		return

	# Finish scaling on release
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
		set_tool(ToolMode.SELECT)
		return
	
	if event is InputEventMouseMotion:
		var mouse_world: Vector2 = editor.to_world(event.position, viewport._camera_position, viewport._zoom)
		
		if editor.snapping:
			mouse_world = editor.snap_world(mouse_world)
		
		# Copy current axes
		var axes: Array = editor.selected_mesh.get_axes(viewport) # [axis0, axis1]
		var a0: Vector2 = axes[0] # horizontal axis (x or z)
		var a1: Vector2 = axes[1] # vertical axis   (y or z)

		match active_axis:
			Axes.RIGHT:
				a0.y = max(mouse_world.x, a0.x + 0.1) # keep right > left
			Axes.LEFT:
				a0.x = min(mouse_world.x, a0.y - 0.1) # keep left < right
			Axes.TOP:
				a1.x = min(mouse_world.y, a1.y - 0.1) # keep top < bottom
			Axes.BOTTOM:
				a1.y = max(mouse_world.y, a1.x + 0.1) # keep bottom > top

		# Apply back to mesh
		editor.selected_mesh.set_axes(viewport, [a0, a1])

		# Redraw viewport
		editor.refresh_viewports()

func get_handle_under_mouse(mouse_pos: Vector2) -> Dictionary:
	var mesh : GraphMesh = editor.selected_mesh
	if not mesh:
		return {}
	
	var rect : Rect2
	match viewport.orientation:
		viewport.Orientations.TOP:
			rect = mesh.get_top_view_rect()
		viewport.Orientations.SIDE:
			rect = mesh.get_side_view_rect()
		viewport.Orientations.FRONT:
			rect = mesh.get_front_view_rect()
	
	var handle_size : int = 12
	var offset : float = 2.5
	
	# Edge points in world units
	var left = rect.position + Vector2(0, rect.size.y / 2) - Vector2(offset,0)
	var right = rect.position + Vector2(rect.size.x, rect.size.y / 2) + Vector2(offset,0)
	var top = rect.position + Vector2(rect.size.x / 2, 0) - Vector2(0,offset)
	var bottom = rect.position + Vector2(rect.size.x / 2, rect.size.y) + Vector2(0,offset)
	
	# Convert to screen
	left = editor.to_screen(left,viewport._camera_position,viewport._zoom)
	right = editor.to_screen(right,viewport._camera_position,viewport._zoom)
	top = editor.to_screen(top,viewport._camera_position,viewport._zoom)
	bottom = editor.to_screen(bottom,viewport._camera_position,viewport._zoom)
	
	var half = handle_size / 2
	var handles = {
		Axes.LEFT:   Rect2(left - Vector2(half, half), Vector2(handle_size, handle_size)),
		Axes.RIGHT:  Rect2(right - Vector2(half, half), Vector2(handle_size, handle_size)),
		Axes.TOP:    Rect2(top - Vector2(half, half), Vector2(handle_size, handle_size)),
		Axes.BOTTOM: Rect2(bottom - Vector2(half, half), Vector2(handle_size, handle_size))
	}
	
	for axes in handles.keys():
		if handles[axes].has_point(mouse_pos):
			return {"name": axes, "rect": handles[axes]}
	
	return {}

func find_meshes_sorted(world_pos: Vector2) -> Array:
	var hits : Array = []
	
	for mesh in editor.level_data.data:
		var rect : Rect2
		var depth : float
		
		match viewport.orientation:
			viewport.Orientations.TOP:
				rect = mesh.get_top_view_rect()
				depth = (mesh.y_range.x + mesh.y_range.y) / 2.0
			viewport.Orientations.FRONT:
				rect = mesh.get_front_view_rect()
				depth = (mesh.z_range.x + mesh.z_range.y) / 2.0
			viewport.Orientations.SIDE:
				rect = mesh.get_side_view_rect()
				depth = (mesh.x_range.x + mesh.x_range.y) / 2.0
		
		if rect.has_point(world_pos):
			hits.append({"mesh": mesh, "depth": depth})
	
	# Sort by depth — you can flip < to > depending on whether you want “front-most” first or last
	hits.sort_custom(func(a, b):
		return a["depth"] < b["depth"]
	)
	
	return hits


func set_tool(mode: ToolMode) -> void:
	current_tool = mode
	# optionally update gizmos or cursor visuals
	
