@tool
extends SubViewportContainer

const camea_controller_path : String = "res://addons/structura/camera_controller/camera_controller.tscn"
@export var _camera_controller : CameraController
@export var world : Node3D

func _ready() -> void:
	if world:
		_camera_controller = preload(camea_controller_path).instantiate()
		world.add_child(_camera_controller)
		_camera_controller.in_control = true
		_camera_controller.position = Vector3.ZERO

func _input(event: InputEvent) -> void:
	if _camera_controller:
		_camera_controller.input(event)
