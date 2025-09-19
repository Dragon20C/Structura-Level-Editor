@tool
extends Resource
class_name GraphMesh

@export var x_range: Vector2 = Vector2(0, 8)  # x_min = x_range.x, x_max = x_range.y
@export var y_range: Vector2 = Vector2(0, 8)  # y_min = y_range.x, y_max = y_range.y
@export var z_range: Vector2 = Vector2(0, 8)  # z_min = z_range.x, z_max = z_range.y

func get_size() -> Vector3:
	return Vector3(x_range.y - x_range.x,
				   y_range.y - y_range.x,
				   z_range.y - z_range.x)

func get_center() -> Vector3:
	return Vector3((x_range.x + x_range.y) / 2,
				   (y_range.x + y_range.y) / 2,
				   (z_range.x + z_range.y) / 2)

func to_aabb() -> AABB:
	return AABB(get_center() - get_size() / 2.0, get_size())

# Rects for 2D views
func get_top_view_rect() -> Rect2:
	return Rect2(Vector2(x_range.x, z_range.x),
				 Vector2(x_range.y - x_range.x, z_range.y - z_range.x))

func get_front_view_rect() -> Rect2:
	return Rect2(Vector2(x_range.x, y_range.x),
				 Vector2(x_range.y - x_range.x, y_range.y - y_range.x))

func get_side_view_rect() -> Rect2:
	return Rect2(Vector2(z_range.x, y_range.x),
				 Vector2(z_range.y - z_range.x, y_range.y - y_range.x))

# Returns an array of axes (min, max) Vector2s for current viewport orientation
func get_axes(viewport : GraphViewport) -> Array:
	match viewport.orientation:
		viewport.Orientations.TOP:
			return [x_range, z_range]
		viewport.Orientations.FRONT:
			return [x_range, y_range]
		viewport.Orientations.SIDE:
			return [z_range, y_range]
		_:
			return []

# In GraphMesh.gd
func set_axes(viewport : GraphViewport, axes: Array[Vector2]) -> void:
	if axes == null or axes.size() < 2:
		return
	var a0: Vector2 = axes[0]
	var a1: Vector2 = axes[1]

	match viewport.orientation:
		viewport.Orientations.TOP:
			x_range = Vector2(a0.x, a0.y)
			z_range = Vector2(a1.x, a1.y)
		viewport.Orientations.FRONT:
			x_range = Vector2(a0.x, a0.y)
			y_range = Vector2(a1.x, a1.y)
		viewport.Orientations.SIDE:
			z_range = Vector2(a0.x, a0.y)
			y_range = Vector2(a1.x, a1.y)
