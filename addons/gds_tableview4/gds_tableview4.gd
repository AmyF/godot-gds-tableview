@tool
extends EditorPlugin

var scripts: Array

func _enter_tree() -> void:
	scripts = [
		["TableView", "ScrollContainer", load("res://addons/gds_tableview4/tableview.gd")],
		["TableViewDataSource", "RefCounted", load("res://addons/gds_tableview4/tableview_data_source.gd")]
	]
	
	for script in scripts:
		add_custom_type(script[0], script[1], script[2], null)


func _exit_tree() -> void:
	for script in scripts:
		remove_custom_type(script[0])
