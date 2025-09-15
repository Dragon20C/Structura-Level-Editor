@tool
extends EditorPlugin

const CFG := "res://addons/MounirTohami.plugin_tools/plugin.cfg"

var addons := {}
var cfg := ConfigFile.new()
var hbox: HBoxContainer
var opt_button: OptionButton
var checkbox: CheckBox


func _ready():
	if not Engine.is_editor_hint():
		return
	cfg.load(CFG)
	var fs = get_editor_interface().get_resource_filesystem()
	fs.filesystem_changed.connect(_on_fs_changed)
	get_addons()


func _enter_tree():
	if not Engine.is_editor_hint():
		return
	
	hbox = HBoxContainer.new()
	opt_button = PluginOptions.new()
	opt_button.item_selected.connect(_on_plugin_selected)
	hbox.add_child(opt_button)
	
	checkbox = CheckBox.new()
	checkbox.tooltip_text = "Toggle plugin enabled/disabled."
	checkbox.focus_mode = Control.FOCUS_NONE
	checkbox.toggled.connect(_on_checkbox_toggled)
	hbox.add_child(checkbox)
	
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, hbox)


func _exit_tree():
	if not Engine.is_editor_hint():
		return
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, hbox)
	hbox.free()
	hbox = null
	opt_button = null
	checkbox = null


func get_recent():
	return cfg.get_value("data", "recent", "")


func is_plugin_enabled(plg):
	return get_editor_interface().is_plugin_enabled(plg)


func _on_plugin_selected(idx: int):
	var meta = opt_button.get_item_metadata(idx)
	cfg.set_value("data", "recent", meta)
	checkbox.set_pressed_no_signal(is_plugin_enabled(meta))
	cfg.save(CFG)


func _on_checkbox_toggled(pressed: bool):
	if addons.keys().size() == 0:
		checkbox.set_pressed_no_signal(false)
		return
	var meta = get_recent()
	get_editor_interface().set_plugin_enabled(meta, pressed)
	checkbox.set_pressed_no_signal(is_plugin_enabled(meta))


func _on_fs_changed():
	get_addons()


func get_addons():
	if not opt_button:
		return
	opt_button.clear()
	var dir := DirAccess.open("res://addons/")
	dir.list_dir_begin()
	var d := dir.get_next()
	var _i := 0
	while d:
		if d == "WhalesState.plugin_tools":
			d = dir.get_next()
			continue
		var _path = "res://addons/%s/plugin.cfg" % d
		if FileAccess.file_exists(_path):
			var _cfg := ConfigFile.new()
			_cfg.load(_path)
			var _name := _cfg.get_value("plugin", "name", "")
			addons[d] = _name
			opt_button.add_item(_name)
			opt_button.set_item_metadata(_i, d)
			_i += 1
		d = dir.get_next()
	var rec_idx = -1
	for i in opt_button.get_item_count():
		if get_recent() == opt_button.get_item_metadata(i):
			rec_idx = i
			break
	if opt_button.get_item_count() > 0:
		if get_recent().is_empty():
			cfg.set_value("data", "recent", opt_button.get_item_metadata(0))
			rec_idx = 0
			cfg.save(CFG)
		opt_button.select(rec_idx)
		await get_tree().process_frame
		checkbox.set_pressed_no_signal(is_plugin_enabled(get_recent()))


class PluginOptions:
	extends OptionButton
	
	
	func _init() -> void:
		fit_to_longest_item = false
		text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		custom_minimum_size.x = 128
		focus_mode = Control.FOCUS_NONE
	
	
	func _get_tooltip(at_position: Vector2) -> String:
		if selected < 0:
			return ""
		return get_item_text(selected)
