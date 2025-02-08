extends RefCounted
class_name TableViewDataSource

func number_of_rows(tableView: TableView) -> int:
	assert(false, "This method must be implemented")
	return 0


func height_for_row_at(tableView: TableView, index: int) -> float:
	assert(false, "This method must be implemented")
	return 0
	

func cell_for_row_at(tableView: TableView, index: int) -> Control:
	assert(false, "This method must be implemented")
	return null
