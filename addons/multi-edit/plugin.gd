@tool
extends EditorPlugin

var _in_multi_edit_mode : bool = false:
	set = _set_multi_edit_mode

var _inspector : MultiEditInspector
var _current_selected_resources : Array[Resource]
var _current_selected_paths: PackedStringArray
var _undo_redo : EditorUndoRedoManager


func _enter_tree() -> void:
	_inspector = MultiEditInspector.new()
	_undo_redo = get_undo_redo()
	add_inspector_plugin(_inspector)
	EditorInterface.get_inspector().property_edited.connect(_on_property_edited)


func _exit_tree() -> void:
	if _inspector:
		remove_inspector_plugin(_inspector)
	EditorInterface.get_inspector().property_edited.disconnect(_on_property_edited)


func _process(delta: float) -> void:
	var selection := EditorInterface.get_selected_paths()
	if selection.size() > 1:
		if not _current_selected_paths.size() == selection.size():
			_current_selected_paths = selection
			_current_selected_resources.clear()
			for path in selection:
				if ResourceLoader.exists(path): # checks if the selected file isn't a folder
					_current_selected_resources.append(ResourceLoader.load(path))
				else: 
					_in_multi_edit_mode = false
					return
			
			_in_multi_edit_mode = _all_files_are_same_type()
	else:
		_in_multi_edit_mode = false


func _set_multi_edit_mode (multi_edit : bool) -> void:
	_inspector.multi_edit_mode = multi_edit
	_inspector.resources = _current_selected_resources
	_in_multi_edit_mode = multi_edit
	
	if multi_edit:
		var index = _current_selected_resources.find(EditorInterface.get_inspector().get_edited_object())
		if index >= 0:
			EditorInterface.edit_resource(_current_selected_resources[index])
			_current_selected_resources[index].notify_property_list_changed()


func _all_files_are_same_type () -> bool:
	if _current_selected_resources[0] == null:
		return false
	
	var selected_class = _current_selected_resources[0].get_class()
	for r in _current_selected_resources:
		if r == null or not r.get_class() == selected_class:
			return false
	
	return true


func _on_property_edited (property : String) -> void:
	if not _in_multi_edit_mode:
		return
	# wait for the property edit action to be added to the history
	# so we can avoid crashing the editor
	await get_tree().process_frame
	
	var current_resource := EditorInterface.get_inspector().get_edited_object() as Resource
	var value := current_resource.get(property)
	_undo_redo.create_action("Multi-set "+property)
	
	var original_values : Array
	for r in _current_selected_resources:
		original_values.append(r.get(property))
		
	_undo_redo.add_do_method(self, "apply_multi_edit", property, value, _current_selected_resources)
	_undo_redo.add_undo_method(self, "undo_multi_edit", property, original_values, _current_selected_resources)
	
	_undo_redo.commit_action()


func apply_multi_edit (property : String, value : Variant, targets : Array[Resource]) -> void:
	for t in targets:
		t.set(property, value)


func undo_multi_edit (property : String, values : Array[Variant], targets : Array[Resource]) -> void:
	for i in targets.size():
		targets[i].set(property, values[i])
