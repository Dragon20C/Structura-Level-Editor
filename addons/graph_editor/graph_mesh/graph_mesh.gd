@tool
extends Resource
class_name GraphMesh

## All measurments are in world units

@export var x_range: Vector2 = Vector2(-1.0, 1.0)
@export var y_range: Vector2 = Vector2(-1.0, 1.0)
@export var z_range: Vector2 = Vector2(-1.0, 1.0)

@export var origin_position : Vector2

func copy() -> GraphMesh:
	var copy : GraphMesh = GraphMesh.new()
	copy.x_range = x_range
	copy.y_range = y_range
	copy.z_range = z_range
	copy.origin_position = origin_position
	return copy

func get_size() -> Vector3:
	return Vector3(
		x_range.y - x_range.x,
		y_range.y - y_range.x,
		z_range.y - z_range.x
	)
