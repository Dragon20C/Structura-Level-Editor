@tool
extends Resource
class_name GraphUtils

var world_unit_scale: float = 1.0

func set_world_unit_scale(scale: float) -> void:
	world_unit_scale = scale

## Converts pixel coords (screen space) into world/graph coords
## camera_position = world position at the center of the viewport
## viewport_size = size of the Control (in pixels)
func to_graph(pixel_cords: Vector2, camera_position: Vector2, zoom: float, viewport_size: Vector2) -> Vector2:
	# Step 1: move pixel into "camera-centered" coordinates
	var centered = pixel_cords - (viewport_size * 0.5)
	# Step 2: undo zoom
	var world = centered / zoom
	# Step 3: apply camera center offset
	world += camera_position
	# Step 4: apply scaling (if using custom world units)
	return world / world_unit_scale


## Converts world/graph coords into pixel coords (screen space)
## camera_position = world position at the center of the viewport
## viewport_size = size of the Control (in pixels)
func to_pixel(graph_cords: Vector2, camera_position: Vector2, zoom: float, viewport_size: Vector2) -> Vector2:
	# Step 1: scale into raw world space
	var world = graph_cords * world_unit_scale
	# Step 2: offset by camera center
	world -= camera_position
	# Step 3: apply zoom
	world *= zoom
	# Step 4: shift into viewport space
	return world + (viewport_size * 0.5)

## Snaps a world/graph position to the nearest grid cell
func snap_to_grid(world_pos: Vector2, grid_size: float) -> Vector2:
	if grid_size <= 0.0:
		return world_pos
	return Vector2(
		round(world_pos.x / grid_size) * grid_size,
		round(world_pos.y / grid_size) * grid_size
	)
