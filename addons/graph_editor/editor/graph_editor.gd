@tool
extends Control
class_name GraphEditor

@export_group("Config")
@export var graph_data : GraphData

@export_group("Viewports")
@export var top_viewport : GraphViewport
@export var side_viewport : GraphViewport
@export var front_viewport : GraphViewport

## Converts world unit 1 to pixels -> 1 wu == 10 pixels
var world_unit_scale : int = 10
## Grid size
var grid_size : int = 16
## Snapping
var snapping_enabled : bool = false
## Graph Utils that help connect things together
var graph_utils : GraphUtils
var tool_dock : ToolDock
var selected_mesh : GraphMesh

func _ready() -> void:
	graph_utils = GraphUtils.new()
	
	top_viewport.set_graph_data(graph_data)
	top_viewport.set_world_units(world_unit_scale)
	top_viewport.set_grid_scale(grid_size)
	
	top_viewport.mesh_selected.connect(mesh_selected)
	top_viewport.clear_selection.connect(func(): mesh_selected(null))
	
	side_viewport.set_graph_data(graph_data)
	side_viewport.set_world_units(world_unit_scale)
	side_viewport.set_grid_scale(grid_size)
	
	side_viewport.mesh_selected.connect(mesh_selected)
	side_viewport.clear_selection.connect(func(): mesh_selected(null))
	
	front_viewport.set_graph_data(graph_data)
	front_viewport.set_world_units(world_unit_scale)
	front_viewport.set_grid_scale(grid_size)
	
	front_viewport.mesh_selected.connect(mesh_selected)
	front_viewport.clear_selection.connect(func(): mesh_selected(null))
	
	
	
	graph_data.data_updated.connect(_refresh_viewports)
	_update_tooldock_ui()

func set_snap(snap_state : bool) -> void:
	print("Setting snap!")
	snapping_enabled = snap_state

func _refresh_viewports() -> void:
	top_viewport.set_grid_scale(grid_size)
	top_viewport.update()
	
	side_viewport.set_grid_scale(grid_size)
	side_viewport.update()
	
	front_viewport.set_grid_scale(grid_size)
	front_viewport.update()
	## Include the other viewports in the future when it is ready!

func mesh_selected(mesh : GraphMesh) -> void:
	selected_mesh = mesh
	_update_tooldock_ui()

func _on_tooldock_create():
	var mesh : GraphMesh = GraphMesh.new()
	mesh_selected(mesh)
	graph_data.add_mesh(mesh,Vector2.ZERO)
	_update_tooldock_ui()

func _on_tooldock_delete():
	if selected_mesh:
		graph_data.remove_mesh(selected_mesh)
		_update_tooldock_ui()
		tool_dock.clear_ranges()
		tool_dock.clear_position()

func _update_tooldock_ui():
	tool_dock.mesh_counter_l.text = "Meshes: %d" % graph_data.data.size()
	
	if selected_mesh:
		tool_dock.update_ranges(selected_mesh)
		tool_dock.update_position(selected_mesh)
	else:
		tool_dock.clear_ranges()
		tool_dock.clear_position()

func on_duplicate_mesh() -> void:
	if selected_mesh:
		var copy : GraphMesh = selected_mesh.copy()
		graph_data.add_mesh(copy,Vector2.ZERO)

func increase_grid() -> void:
	grid_size = clamp(grid_size + 8, 8, 256)
	tool_dock.set_grid_size(grid_size)
	_refresh_viewports()

func decrease_grid() -> void:
	grid_size = clamp(grid_size - 8, 8, 256)
	tool_dock.set_grid_size(grid_size)
	_refresh_viewports()

func set_tooldock(_tool_dock : ToolDock) -> void:
	tool_dock = _tool_dock
