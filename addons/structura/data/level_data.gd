@tool
extends Resource
class_name LevelData

signal mesh_added(mesh: GraphMesh)
signal mesh_removed(mesh: GraphMesh)

@export var data : Array[GraphMesh] = []


func add_mesh(graph_mesh: GraphMesh) -> void:
	if not data.has(graph_mesh):
		data.append(graph_mesh)
		emit_signal("mesh_added", graph_mesh)

func remove_mesh(graph_mesh: GraphMesh) -> void:
	if data.has(graph_mesh):
		data.erase(graph_mesh)
		emit_signal("mesh_removed", graph_mesh)
