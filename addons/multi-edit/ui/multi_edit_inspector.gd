class_name MultiEditInspector extends EditorInspectorPlugin

var multi_edit_mode : bool
var resources : Array[Resource]

func _can_handle(object: Object) -> bool:
	if object is Resource:
		return true
	return false

func _parse_begin(object: Object) -> void:
	if multi_edit_mode:
		var options := OptionButton.new()
		for r in resources:
			options.add_item(r.resource_path)
		options.select(resources.find(object))
		options.item_selected.connect(_on_select, CONNECT_DEFERRED)
		add_custom_control(options)

func _on_select(index : int) -> void:
	EditorInterface.edit_resource(resources[index])

func _on_current_object_edited () -> void:
	pass
