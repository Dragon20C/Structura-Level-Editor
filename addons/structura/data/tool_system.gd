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

func _gui_input(event: InputEvent) -> void:
	match current_tool:
		ToolMode.SELECT:
			handle_select(event)
		ToolMode.CREATE:
			handle_create(event)
		ToolMode.MOVE:
			handle_move(event)
		ToolMode.SCALE:
			pass


func handle_select(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var world_pos : Vector2 = editor.to_world(event.position,viewport._camera_position,viewport._zoom)
			var mesh : GraphMesh = find_mesh(world_pos)
			if mesh:
				if mesh == editor.selected_mesh:
					# start moving
					drag_start_world = world_pos
					set_tool(ToolMode.MOVE)
				else:
					editor.selected_mesh = mesh
			else:
				# no mesh hit → prepare create
				create_start_world = world_pos
				set_tool(ToolMode.CREATE)

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
			target_min = Vector2(
				round(mouse_world.x / editor.grid_size) * editor.grid_size,
				round(mouse_world.y / editor.grid_size) * editor.grid_size
			)
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
		viewport.refresh()


func handle_create(event : InputEvent) -> void:
	# REQUIRE CODE - Going back
	## Requirments, we need to check if the inital position and the current position is larger then say 5x5
	## This is to avoid creating super small box shapes
	set_tool(ToolMode.SELECT)
	print("Creating!")

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

func set_tool(mode: ToolMode) -> void:
	current_tool = mode
	# optionally update gizmos or cursor visuals
	
