@tool
extends Control
class_name ToolSystem

enum ToolMode { SELECT, CREATE, MOVE, SCALE }
var current_tool: ToolMode = ToolMode.SELECT

enum InteractionState { IDLE, HOVERING, DRAGGING, MOVING, SCALING }
var interaction_state: InteractionState = InteractionState.IDLE

@export var editor : StructuraEditor
@export var viewport : GraphViewport

var drag_start_world : Vector2

func _gui_input(event: InputEvent) -> void:
	handle_input(event)

func _process(delta: float) -> void:
	update(delta)

func handle_input(event: InputEvent) -> void:
	match current_tool:
		ToolMode.SELECT:
			handle_select(event)
		ToolMode.CREATE:
			handle_create(event)
		ToolMode.MOVE:
			handle_move(event)
		ToolMode.SCALE:
			handle_scale(event)

func update(delta: float) -> void:
	match current_tool:
		ToolMode.SELECT:
			update_select(delta)
		ToolMode.CREATE:
			update_create(delta)
		#ToolMode.MOVE:
			#update_move(delta)
		ToolMode.SCALE:
			update_scale(delta)

## HANDLES
func handle_select(event: InputEvent) -> void:
	# If no mesh selected yet
	if editor.selected_mesh == null:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Try to select a mesh under mouse
			var world_pos = editor.to_world(event.position, viewport._camera_position, viewport._zoom)
			var mesh = pick_mesh_at(world_pos)
			editor.selected_mesh = mesh
		return
	
	# A mesh is selected, so check interactions
	match interaction_state:
		InteractionState.IDLE:
			if event is InputEventMouseMotion:
				pass
				#if is_hovering_handle(event.position):
					#interaction_state = InteractionState.HOVERING

			elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				var world_pos = editor.to_world(event.position, viewport._camera_position, viewport._zoom)
				if is_hovering_handle(world_pos):
					interaction_state = InteractionState.MOVING
					drag_start_world = world_pos
					#start_move(event.position)
				elif event.button_index == MOUSE_BUTTON_LEFT:
					# Clicked elsewhere → deselect
					editor.selected_mesh = null

		InteractionState.MOVING:
			if event is InputEventMouseMotion:
				update_move(event.position)
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
					interaction_state = InteractionState.IDLE
			#elif event is InputEventMouseButton and not event.pressed:
				#interaction_state = InteractionState.IDLE
				#end_move()


func handle_create(event : InputEvent) -> void:
	pass

func handle_move(event : InputEvent) -> void:
	pass
	#var world_pos_now = editor.to_world(mouse_pos, camera_position, zoom)
	#var delta = world_pos_now - drag_start_world
	#mesh.apply_move(delta, viewport.orientation)
	#drag_start_world = world_pos_now  # reset so movement is incremental


func handle_scale(event : InputEvent) -> void:
	pass

## UPDATE
func update_select(delta : float) -> void:
	pass

func update_create(delta : float) -> void:
	pass

func update_move(mouse_pos : Vector2) -> void:
	var world_pos_now = editor.to_world(mouse_pos, viewport._camera_position, viewport._zoom)
	var delta = world_pos_now - drag_start_world
	editor.selected_mesh.apply_move(delta, viewport)
	drag_start_world = world_pos_now  # reset so movement is incremental
	viewport.refresh()

func update_scale(delta : float) -> void:
	pass 

func pick_mesh_at(world_position: Vector2) -> GraphMesh:
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


func is_hovering_handle(world_position : Vector2) -> bool:
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
			return true
	return false


func set_tool(mode: ToolMode) -> void:
	current_tool = mode
	# optionally update gizmos or cursor visuals
	
