@tool
extends EditorPlugin

const graph_editor_string : String = "editor/graph_editor.tscn"
const tool_dock_string : String = "res://addons/graph_editor/tool_dock/tool_dock.tscn"

var graph_editor : GraphEditor
var tool_dock : ToolDock

func _enter_tree() -> void:
	
	add_custom_type("GraphLevelBuilder", "Node3D", preload("res://addons/graph_editor/level_builder/graph_3d_builder.gd"),null)
	# Initialization of the plugin goes here.
	graph_editor = preload(graph_editor_string).instantiate()
	tool_dock = preload(tool_dock_string).instantiate()
	
	EditorInterface.get_editor_main_screen().add_child(graph_editor)
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL,tool_dock)
	_make_visible(false)
	
	graph_editor.set_tooldock(tool_dock)
	
	make_connections()

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	
	remove_custom_type("GraphLevelBuilder")
	if graph_editor:
		graph_editor.queue_free()
	
	if tool_dock:
		remove_control_from_docks(tool_dock)
		tool_dock.queue_free()

func _make_visible(visible):
	if graph_editor:
		graph_editor.visible = visible
	
	if tool_dock:
		var tabc := tool_dock.get_parent()
		match visible:
			true:
				if tabc and tabc is TabContainer:
					var idx = tabc.get_tab_idx_from_control(tool_dock)
					tabc.current_tab = idx
			false:
				pass
				if tabc and tabc is TabContainer:
					var idx = tabc.get_tab_idx_from_control(tool_dock)
					tabc.current_tab = 0

func _has_main_screen():
	return true

func _get_plugin_name():
	return "Level Editor"

func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")

func make_connections() -> void:
	tool_dock.on_creation.connect(graph_editor._on_tooldock_create)
	tool_dock.on_deletion.connect(graph_editor._on_tooldock_delete)
	tool_dock.increase_grid_size.connect(graph_editor.increase_grid)
	tool_dock.decrease_grid_size.connect(graph_editor.decrease_grid)
	tool_dock.update_snapping.connect(graph_editor.set_snap)
	tool_dock.on_duplicate.connect(graph_editor.on_duplicate_mesh)
