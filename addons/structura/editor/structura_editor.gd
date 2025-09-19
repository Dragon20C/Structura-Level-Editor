@tool
extends Control
class_name StructuraEditor

@export_group("Node Requirements")
@export var grid_label : Label
@export var snap_button : Button
@export var level_data : LevelData
var grid_size : int = 16
var world_unit_scale : int = 10
var snapping : bool = false

@export var viewports : Array[GraphViewport]
var selected_mesh : GraphMesh

@onready var file_dialog: FileDialog = FileDialog.new()

func _ready() -> void:
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.add_filter("*.tres ; Level Data Resource")
	file_dialog.connect("file_selected", Callable(self, "_on_level_file_selected"))
	add_child(file_dialog)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_E and event.pressed:
			duplicate_mesh()
			refresh_viewports()

func duplicate_mesh() -> void:
	if selected_mesh:
		var copy : GraphMesh = selected_mesh.duplicate()
		level_data.add_mesh(copy)
		selected_mesh = copy

## should only call this if we are updating all of the viewports at the same time.
## example when adding a new mesh or when a mesh is modified
func refresh_viewports() -> void:
	for viewport in viewports:
		viewport.refresh()

# From drawing to world units
func to_world(screen_position : Vector2,camera_position : Vector2, zoom : float) -> Vector2:
	var scaler : float = world_unit_scale * zoom
	
	var world_unit : Vector2 = (screen_position / scaler) + camera_position
	
	return world_unit
	
# from world units to drawing
func to_screen(world_position : Vector2,camera_position : Vector2, zoom : float) -> Vector2:
	var scaler : float = world_unit_scale * zoom
	
	var screen_unit : Vector2 = (world_position - camera_position) * scaler
	
	return screen_unit

# snaps world position on a grid position
func snap_world(world_position : Vector2) -> Vector2:
	return Vector2(
		round(world_position.x / grid_size) * grid_size,
		round(world_position.y / grid_size) * grid_size
	)

func _on_load_level_pressed() -> void:
	file_dialog.popup_centered()

func _on_level_file_selected(path: String) -> void:
	var res = load(path)
	if res is LevelData:  # 👈 replace with your actual class_name
		level_data = res
		refresh_viewports()
	else:
		push_error("Selected file is not a LevelData resource!")


func _on_minus_grid_pressed() -> void:
	grid_size = clamp(grid_size - 4, 4, 256)
	grid_label.text = "Grid size: %s" % grid_size
	refresh_viewports()

func _on_plus_grid_pressed() -> void:
	grid_size = clamp(grid_size + 4, 4, 256)
	grid_label.text = "Grid size: %s" % grid_size
	refresh_viewports()

func _on_snap_pressed() -> void:
	snapping = !snapping
	match snapping:
		true:
			snap_button.text = "Snapping: Enabled"
		false:
			snap_button.text = "Snapping: Disabled"
	
	refresh_viewports()

func _on_delete_pressed() -> void:
	if selected_mesh:
		level_data.remove_mesh(selected_mesh)
		selected_mesh = null
		refresh_viewports()
