@tool
extends Resource
class_name GraphData

signal data_updated

@export var data : Array[GraphMesh]

func add_mesh(mesh : GraphMesh,position : Vector2) -> void:
	mesh.origin_position = position
	data.append(mesh)
	data_updated.emit()

func remove_mesh(mesh : GraphMesh) -> void:
	data.erase(mesh)
	data_updated.emit()
