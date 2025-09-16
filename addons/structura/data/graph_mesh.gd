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

func apply_move(delta: Vector2, viewport : GraphViewport) -> void:
	# delta is in world units from the editor drag
	match viewport.orientation:
		# Top view = X (horizontal), Z (vertical)
		viewport.Orientations.TOP:
			x_min += delta.x
			x_max += delta.x
			z_min += delta.y
			z_max += delta.y

		# Front view = X (horizontal), Y (vertical)
		viewport.Orientations.FRONT:
			x_min += delta.x
			x_max += delta.x
			y_min += delta.y
			y_max += delta.y

		# Side view = Z (horizontal), Y (vertical)
		viewport.Orientations.SIDE:
			z_min += delta.x
			z_max += delta.x
			y_min += delta.y
			y_max += delta.y


func to_aabb() -> AABB:
	return AABB(get_center() - get_size() / 2.0, get_size())

func get_top_view_rect() -> Rect2:
	return Rect2(Vector2(x_min, z_min), Vector2(x_max - x_min, z_max - z_min))

func get_front_view_rect() -> Rect2:
	return Rect2(Vector2(x_min, y_min), Vector2(x_max - x_min, y_max - y_min))

func get_side_view_rect() -> Rect2:
	return Rect2(Vector2(z_min, y_min), Vector2(z_max - z_min, y_max - y_min))
