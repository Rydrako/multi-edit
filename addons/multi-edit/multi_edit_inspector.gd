class_name MultiEditInspector extends EditorInspectorPlugin

var multi_edit_mode : bool
var resources : Array[Resource]


func _can_handle(object: Object) -> bool:
	if object is Resource:
		return true
	return false


func _parse_begin(object: Object) -> void:
	if multi_edit_mode:
		_create_dropdown(object)


func _select_resource(index : int) -> void:
	EditorInterface.edit_resource(resources[index])


func _create_dropdown (object: Resource) -> void:
	var info := MenuButton.new()
	info.text = "%s resources selected\n%s" % [resources.size(), object.resource_path]
	info.icon = EditorInterface.get_base_control().get_theme_icon("Info", "EditorIcons")
	
	for r in resources:
		info.get_popup().add_item(r.resource_path)
	
	info.get_popup().index_pressed.connect(_select_resource, CONNECT_DEFERRED)
	add_custom_control(info)
