@tool
extends Camera3D
class_name CameraController

@export var move_speed: float = 10.0
@export var sprint_multiplier: float = 3.0
@export var mouse_sensitivity: float = 0.002

var _yaw: float = 0.0
var _pitch: float = 0.0
var toggle_sprint : bool = false
var in_control : bool = false

#func _ready() -> void:
	## Capture mouse inside editor only when viewport has focus
	#if Engine.is_editor_hint():
		#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and in_control: #and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clamp(_pitch, deg_to_rad(-89), deg_to_rad(89))
		rotation = Vector3(_pitch, _yaw, 0)
		print("Im here bro!")

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta: float) -> void:
	if not in_control:
		return
		
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("S_Forward"):
		input_dir -= transform.basis.z
	if Input.is_action_pressed("S_Backward"):
		input_dir += transform.basis.z
	if Input.is_action_pressed("S_Left"):
		input_dir -= transform.basis.x
	if Input.is_action_pressed("S_Right"):
		input_dir += transform.basis.x
	if Input.is_action_pressed("S_Up"):
		input_dir += transform.basis.y
	if Input.is_action_pressed("S_Down"):
		input_dir -= transform.basis.y

	if input_dir != Vector3.ZERO:
		input_dir = input_dir.normalized()

	var speed = move_speed * sprint_multiplier if toggle_sprint else move_speed
	if Input.is_action_just_pressed("S_Sprint"):
		toggle_sprint = !toggle_sprint

	translate(input_dir * speed * delta)
