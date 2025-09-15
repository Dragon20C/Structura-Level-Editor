@tool
extends Resource
class_name GraphMesh

@export var x_min: float = -5
@export var x_max: float = 5
@export var y_min: float = -5
@export var y_max: float = 5
@export var z_min: float = -5
@export var z_max: float = 5
	
func get_size() -> Vector3:
	return Vector3(x_max - x_min, y_max - y_min, z_max - z_min)

func get_center() -> Vector3:
	return Vector3(
		(x_min + x_max) / 2.0,
		(y_min + y_max) / 2.0,
		(z_min + z_max) / 2.0
		)

func to_aabb() -> AABB:
	return AABB(get_center() - get_size() / 2.0, get_size())


func get_top_view_rect() -> Rect2:
	return Rect2(Vector2(x_min, z_min), Vector2(x_max - x_min, z_max - z_min))

func get_front_view_rect() -> Rect2:
	return Rect2(Vector2(x_min, y_min), Vector2(x_max - x_min, y_max - y_min))

func get_side_view_rect() -> Rect2:
	return Rect2(Vector2(z_min, y_min), Vector2(z_max - z_min, y_max - y_min))
