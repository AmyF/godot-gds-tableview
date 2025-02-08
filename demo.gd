extends CanvasLayer

@onready var a_table_view: TableView = $PanelContainer/MarginContainer/VBoxContainer/ATableView
@onready var b_table_view: TableView = $PanelContainer2/MarginContainer/VBoxContainer/BTableView

var a_item_list: Array[String] = []
var data_source = DataSource.new()

func _ready() -> void:
	a_table_view.register_cell_scene("Cell", load("res://demo_cell.tscn"))
	a_table_view.data_source = self
	a_table_view.data_reloaded.connect(on_table_View_reloaded)
	
	b_table_view.register_cell_scene("Cell", load("res://demo_cell.tscn"))
	b_table_view.data_source = data_source
	b_table_view.data_reloaded.connect(on_table_View_reloaded)

func on_table_View_reloaded(tableView: TableView):
	print("%s reloaded" % tableView.name)

func reload_a():
	a_table_view.reload_data()

func add_for_a():
	a_item_list.append(create_string(a_item_list.size()))
	reload_a()
	
func add_10_for_a():
	var appending_list = range(a_item_list.size(), a_item_list.size() + 10).map(create_string)
	a_item_list.append_array(appending_list)
	reload_a()
	
func clear_a():
	a_item_list.clear()
	reload_a()

func create_string(index: int) -> String:
	return str(index)

func reload_b():
	b_table_view.reload_data()

func add_for_b():
	data_source.count += 1
	reload_b()
	
func add_10_for_b():
	data_source.count += 10
	reload_b()
	
func clear_b():
	data_source.count = 0
	reload_b()


func number_of_rows(tableView: TableView) -> int:
	if tableView == a_table_view:
		return a_item_list.size()
	return 0


func height_for_row_at(tableView: TableView, index: int) -> float:
	if tableView == a_table_view:
		return 32 if index % 5 == 0 else 24
	return 0
	

func cell_for_row_at(tableView: TableView, index: int) -> Control:
	if tableView == a_table_view:
		var cell = tableView.dequeue_reusable_cell("Cell") as Label
		cell.text = "Item %s" % a_item_list[index]
		return cell
	return null


class DataSource extends TableViewDataSource:
	var count: int = 0
	
	func number_of_rows(tableView: TableView) -> int:
		return count

	func height_for_row_at(tableView: TableView, index: int) -> float:
		return 32 if index % 5 == 0 else 24

	func cell_for_row_at(tableView: TableView, index: int) -> Control:
		var cell = tableView.dequeue_reusable_cell("Cell") as Label
		cell.text = "Item %d" % index
		return cell
