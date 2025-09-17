@tool
extends Control
class_name StructuraEditor

@export_group("Node Requirements")
@export var level_data : LevelData
var grid_size : int = 16
var world_unit_scale : int = 10
var snapping : bool = false

@export var viewports : Array[GraphViewport]
var selected_mesh : GraphMesh

## should only call this if we are updating all of the viewports at the same time.
## example when adding a new mesh or when a mesh is modified
func refresh_viewports() -> void:
	for viewport in viewports:
		viewport.refresh()

# From drawing to world units
func to_world(screen_position : Vector2,camera_position : Vector2, zoom : float) -> Vector2:
	var scaler : float = world_unit_scale * zoom
	
	var world_unit : Vector2 = (screen_position / scaler) + camera_position
	
	return world_unit
	
# from world units to drawing
func to_screen(world_position : Vector2,camera_position : Vector2, zoom : float) -> Vector2:
	var scaler : float = world_unit_scale * zoom
	
	var screen_unit : Vector2 = (world_position - camera_position) * scaler
	
	return screen_unit

# snaps world position on a grid position
func snap_world(world_position : Vector2) -> Vector2:
	return Vector2(
		round(world_position.x / grid_size) * grid_size,
		round(world_position.y / grid_size) * grid_size
	)
