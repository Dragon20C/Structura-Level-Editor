@tool
extends EditorPlugin

const inputs : Dictionary[String,int] = {
	"S_Forward" : KEY_W,
	"S_Backward" : KEY_S,
	"S_Left" : KEY_A,
	"S_Right" : KEY_D,
	"S_Up" : KEY_SPACE,
	"S_Down" : KEY_SHIFT,
	"S_Sprint" : KEY_TAB
	}

const structura_editor_path : String = "editor/structura_editor.tscn"
var structura_editor : StructuraEditor

func _enter_tree():
	
	add_input_maps()
	
	structura_editor = preload(structura_editor_path).instantiate()
	EditorInterface.get_editor_main_screen().add_child(structura_editor)
	# Hide the main panel. Very much required.
	_make_visible(false)

func _exit_tree():
	if structura_editor:
		structura_editor.queue_free()
	
	remove_input_maps()

func _has_main_screen():
	return true


func _make_visible(visible):
	
	if structura_editor:
		structura_editor.visible = visible
		get_editor_interface().distraction_free_mode = visible


func _get_plugin_name():
	return "Structura Editor"


func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")

func add_input_maps() -> void:
	for input in inputs:
		if InputMap.has_action(input):
			continue
		InputMap.add_action(input)
		var ev : InputEventKey = InputEventKey.new()
		ev.keycode = inputs[input]
		InputMap.action_add_event(input, ev)

func remove_input_maps() -> void:
	for input in inputs:
		if InputMap.has_action(input):
			InputMap.erase_action(input)
