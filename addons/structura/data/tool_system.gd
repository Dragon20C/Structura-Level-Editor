@tool
extends Control
class_name ToolSystem

enum ToolMode { SELECT, CREATE, MOVE, SCALE }
var current_tool: ToolMode = ToolMode.SELECT

enum InteractionState { IDLE, SELECTING, MOVING, SCALING}
var interaction_state: InteractionState = InteractionState.IDLE

@export var editor : StructuraEditor
@export var viewport : GraphViewport

var drag_start_world : Vector2
var create_start_world : Vector2
var create_end_world : Vector2
var active_axis : String

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


func handle_select(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var world_pos : Vector2 = editor.to_world(event.position,viewport._camera_position,viewport._zoom)
			var mesh : GraphMesh = find_mesh(world_pos)
			
			var handle = get_handle_under_mouse(event.position)
			if not handle.is_empty():
				active_axis = handle["name"]
				print(active_axis)
				set_tool(ToolMode.SCALE)
				return
			
			if mesh:
				if mesh == editor.selected_mesh:
					# start moving
					drag_start_world = world_pos
					set_tool(ToolMode.MOVE)
				else:
					editor.selected_mesh = mesh
			elif editor.selected_mesh:
				editor.selected_mesh = null
			else:
				# no mesh hit → prepare create
				var new_mesh : GraphMesh = GraphMesh.new()
				editor.level_data.add_mesh(new_mesh)
				editor.selected_mesh = new_mesh
				
				if editor.snapping:
					create_start_world = editor.snap_world(world_pos)
				else:
					create_start_world = world_pos
					
				set_tool(ToolMode.CREATE)
			editor.refresh_viewports()

# ToolSystem.gd - handle_move
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
	print("Back to SELECT!")
	set_tool(ToolMode.SELECT)

func find_mesh(world_position : Vector2) -> GraphMesh:
	for mesh in editor.level_data.data:
		var rect: Rect2
		
		match viewport.orientation:
			viewport.Orientations.TOP:
				rect = mesh.get_top_view_rect()
			viewport.Orientations.SIDE:
				rect = mesh.get_side_view_rect()
			viewport.Orientations.FRONT:
				rect = mesh.get_front_view_rect()
		
		if rect.has_point(world_position):
			return mesh
	return null

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
	
	# Edge points in local space
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
		"left":   Rect2(left - Vector2(half, half), Vector2(handle_size, handle_size)),
		"right":  Rect2(right - Vector2(half, half), Vector2(handle_size, handle_size)),
		"top":    Rect2(top - Vector2(half, half), Vector2(handle_size, handle_size)),
		"bottom": Rect2(bottom - Vector2(half, half), Vector2(handle_size, handle_size))
	}
	
	for name in handles.keys():
		if handles[name].has_point(mouse_pos):
			return {"name": name, "rect": handles[name]}
	
	return {}


func set_tool(mode: ToolMode) -> void:
	current_tool = mode
	# optionally update gizmos or cursor visuals
	
