@tool
extends Node3D
class_name LevelBuilder3D

@export_tool_button("Load Level") var load_level = _build_level
@export var level_data : LevelData

@onready var mat : StandardMaterial3D = preload("res://addons/structura/assets/DevMat.tres")

func _get_property_list() -> Array:
	# Adds a custom button to the inspector
	return [
		{
			"name": "Build from Level Data",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_EDITOR,
			"hint": PROPERTY_HINT_NONE
		}
	]

func _set(property: StringName, value) -> bool:
	if property == "Build from Level Data":
		_build_level()
		return true
	return false

func _build_level() -> void:
	if not level_data:
		return
	
	# Clear existing children
	for child in get_children():
		child.queue_free()
	
	# Spawn boxes
	for mesh : GraphMesh in level_data.data:
		var box := CSGBox3D.new()
		box.size = mesh.get_size()
		var center : Vector3 = mesh.get_center()
		var invert_y : float = center.y * -1
		center.y = invert_y
		box.position = center
		box.use_collision = true
		box.material_override = mat
		add_child(box)

	print("Level built with %s meshes" % level_data.data.size())
