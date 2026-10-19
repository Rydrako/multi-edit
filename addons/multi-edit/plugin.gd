@tool
extends EditorPlugin

var current_selected_resources : Array[Resource]

var in_multi_edit_mode : bool

var inspector : MultiEditInspector
var current_selected_paths: PackedStringArray

var undo_redo : EditorUndoRedoManager

func _enter_tree() -> void:
	inspector = MultiEditInspector.new()
	undo_redo = get_undo_redo()
	add_inspector_plugin(inspector)
	EditorInterface.get_inspector().property_edited.connect(_on_property_edited)

func _exit_tree() -> void:
	if inspector:
		remove_inspector_plugin(inspector)
	EditorInterface.get_inspector().property_edited.disconnect(_on_property_edited)

func _process(delta: float) -> void:
	var selection := EditorInterface.get_selected_paths()
	if selection.size() > 1:
		if current_selected_paths.size() != selection.size():
			current_selected_paths = selection
			current_selected_resources.clear()
			for path in selection:
				# checks if the selected file isn't a folder
				if ResourceLoader.exists(path):
					current_selected_resources.append(ResourceLoader.load(path))
				else: 
					_set_multi_edit_mode(false)
					return
			
			_set_multi_edit_mode(_all_files_are_same_type())
	else:
		_set_multi_edit_mode(false)

func _all_files_are_same_type () -> bool:
	if current_selected_resources[0] == null:
		return false
	
	var selected_class = current_selected_resources[0].get_class()
	for r in current_selected_resources:
		if r == null or r.get_class() != selected_class:
			return false
	
	return true

func _on_property_edited (property : String) -> void:
	if not in_multi_edit_mode:
		return
	
	# wait for the property edit action to be added to the history
	# otherwise we crash the editor
	await get_tree().process_frame
	var current_resource := EditorInterface.get_inspector().get_edited_object() as Resource
	var value := current_resource.get(property)
	undo_redo.create_action("Multi-set "+property)
	var original_values : Array
	for r in current_selected_resources:
		original_values.append(r.get(property))
		
	undo_redo.add_do_method(self, "apply_multi_edit", property, value, current_selected_resources)
	undo_redo.add_undo_method(self, "undo_multi_edit", property, original_values, current_selected_resources)
	
	undo_redo.commit_action()
	
func apply_multi_edit (property : String, value : Variant, targets : Array[Resource]) -> void:
	for t in targets:
		t.set(property, value)
		
func undo_multi_edit (property : String, values : Array[Variant], targets : Array[Resource]) -> void:
	for i in targets.size():
		targets[i].set(property, values[i])


func _set_multi_edit_mode (multi_edit : bool) -> void:
	inspector.multi_edit_mode = multi_edit
	inspector.resources = current_selected_resources
	
	var index = current_selected_resources.find(EditorInterface.get_inspector().get_edited_object())
	EditorInterface.edit_resource(current_selected_resources[index])
	current_selected_resources[index].notify_property_list_changed()
	
	in_multi_edit_mode = multi_edit
