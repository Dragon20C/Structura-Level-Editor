@tool
extends Control
class_name ToolDock

signal on_creation
signal on_deletion
signal on_duplicate
signal increase_grid_size
signal decrease_grid_size
signal update_snapping(state : bool)

@export var grid_l : Label
@export var position_l : Label
@export var mesh_counter_l : Label
@export var x_range_l : Label
@export var y_range_l : Label
@export var z_range_l : Label
@export var snap_button : Button

var snapping : bool = false

func _ready() -> void:
	clear_ranges()

func _on_create_box_mesh_pressed() -> void:
	on_creation.emit()

func _on_destory_box_mesh_pressed() -> void:
	on_deletion.emit()

## --  FUNCTIONS  -- ##

func clear_position() -> void:
	if position_l: position_l.text = "Position: (-,-)"

func update_position(mesh : GraphMesh) -> void:
	if position_l: position_l.text = "Position: (%.2f,%.2f)" % [mesh.origin_position.x,mesh.origin_position.y]

func clear_ranges() -> void:
	if x_range_l: x_range_l.text = "X range: -"
	if y_range_l: y_range_l.text = "Y range: -"
	if z_range_l: z_range_l.text = "Z range: -"

func update_ranges(mesh: GraphMesh) -> void:
	set_x_range(mesh.x_range.x, mesh.x_range.y)
	set_y_range(mesh.y_range.x, mesh.y_range.y)
	set_z_range(mesh.z_range.x, mesh.z_range.y)

func set_grid_size(grid_size: int) -> void:
	grid_l.text = "Grid size: %s" % grid_size

func set_x_range(min : float , max : float) -> void:
	if x_range_l:
		x_range_l.text = "X range (%.2f)  (%.2f)" % [min,max]

func set_y_range(min : float , max : float) -> void:
	if y_range_l:
		y_range_l.text = "Y range (%.2f) (%.2f)" % [min,max]

func set_z_range(min : float , max : float) -> void:
	if z_range_l:
		z_range_l.text = "Z range (%.2f) (%.2f)" % [min,max]


func _on_minus_pressed() -> void:
	decrease_grid_size.emit()


func _on_plus_pressed() -> void:
	increase_grid_size.emit()


func _on_snapping_pressed() -> void:
	snapping = !snapping
	update_snapping.emit(snapping)
	match snapping:
		true:
			snap_button.text = "Snapping: Enabled"
		false:
			snap_button.text = "Snapping: Disabled"
			


func _on_duplicate_mesh_pressed() -> void:
	on_duplicate.emit()
