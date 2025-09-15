@tool
extends Node3D
class_name Graph3DBuilder

# Editor button (Godot 4.4+)
@export_tool_button("Load Level") var gen = attempt_build

@export var graph_data: GraphData:
	set(value):
		graph_data = value
		_build_scene()
	get:
		return graph_data

var _mesh_nodes: Array[CSGBox3D] = []


func attempt_build() -> void:
	if graph_data:
		_build_scene()
		# reconnect signal safely
		if not graph_data.data_updated.is_connected(_build_scene):
			graph_data.data_updated.connect(_build_scene)


func _build_scene() -> void:
	# Clear old boxes
	for box in _mesh_nodes:
		if is_instance_valid(box):
			box.queue_free()
	_mesh_nodes.clear()

	if not graph_data:
		return

	for mesh in graph_data.data:
		var box := CSGBox3D.new()

		# Size in world units
		box.size = mesh.get_size()

		# Position at the center of ranges
		var center = Vector3(
			(mesh.x_range.x + mesh.x_range.y) * 0.5,
			((mesh.y_range.x + mesh.y_range.y) * 0.5) * -1,
			(mesh.z_range.x + mesh.z_range.y) * 0.5
		)
		box.position = center

		# Add and make persistent in the editor scene
		add_child(box)
		box.owner = get_tree().edited_scene_root

		_mesh_nodes.append(box)
