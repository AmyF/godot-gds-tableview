@tool
extends ScrollContainer
class_name TableView

signal data_reloaded(TableView)

# 数据源接口
var data_source = null : set = _set_data_source

const CELL_REUSE_ID_META_KEY := "tableview_reuse_identifier"

# 内部节点引用
var _content_container: Control
var _visible_cells: Dictionary[int, Control] = {}  # {row_index: TableViewCell}
var _cell_pools: Dictionary[String, Array] = {}     # {reuse_id: [cell_instances]}
var _registered_cells: Dictionary[String, PackedScene] = {} # {reuse_id: PackedScene}
var _row_offsets: Array[float] = []

# getter setter

func _set_data_source(value):
	if data_source == value:
		return
	
	if value:
		if !_validate_data_source(value):
			push_error("DataSource missing required methods")
			return
	
	data_source = value
	call_deferred("reload_data")

# lifecycle

func _ready() -> void:
	_content_container = Control.new()
	_content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_content_container)
	
	get_v_scroll_bar().value_changed.connect(_on_scroll)
	resized.connect(_on_resized)

# public

func reload_data() -> void:
	_clear_cells()
	_update_row_offsets()
	_update_content_size()
	_update_visible_cells()
	data_reloaded.emit(self)


func register_cell_scene(reuse_identifier: String, packed_scene: PackedScene) -> void:
	if !packed_scene.can_instantiate():
		push_error("Invalid packed scene")
		return
	
	_registered_cells[reuse_identifier] = packed_scene


func dequeue_reusable_cell(reuse_identifier: String) -> Control:
	var cell = null
	
	if _cell_pools.has(reuse_identifier) && !_cell_pools[reuse_identifier].is_empty():
		cell = _cell_pools[reuse_identifier].pop_front()
		
	if !cell && _registered_cells.has(reuse_identifier):
		var packed_scene = _registered_cells[reuse_identifier]
		cell = packed_scene.instantiate()
		if cell:
			cell.set_meta(CELL_REUSE_ID_META_KEY, reuse_identifier)
	
	if !cell:
		push_error("No register cell for identifier: ", reuse_identifier)
	
	return cell
	

# private

func _update_row_offsets() -> void:
	_row_offsets.clear()
	if !data_source:
		return
	
	var num_rows = data_source.number_of_rows(self)
	var cumulative = 0.0
	_row_offsets.append(cumulative)
	
	for i in range(num_rows):
		var height = data_source.height_for_row_at(self, i)
		cumulative += height
		_row_offsets.append(cumulative)


func _update_content_size() -> void:
	if !data_source || _row_offsets.is_empty():
		return
	
	var r_margin = get_v_scroll_bar().size.x if get_v_scroll_bar().visible else 0.0
	_content_container.custom_minimum_size = Vector2(size.x - r_margin, _row_offsets[-1])
	

func _update_visible_cells() -> void:
	if !data_source || _row_offsets.is_empty():
		return
	
	var num_rows = data_source.number_of_rows(self)
	if num_rows == 0:
		return
	
	var scroll_value = get_v_scroll_bar().value
	var view_height = size.y
	
	# 计算可见行范围
	var first_visible_row = _get_row_index_for_offset(scroll_value)
	var last_visible_row = _get_row_index_for_offset(scroll_value + view_height)
	# 加1是为了最后一行只有部分露出时正确展示
	last_visible_row = min(last_visible_row + 1, num_rows - 1)
	
	# 回收不可见单元格
	for row in _visible_cells.keys().duplicate():
		if row > first_visible_row || row > last_visible_row:
			var cell = _visible_cells[row]
			var reuse_id = cell.get_meta(CELL_REUSE_ID_META_KEY)
			
			if !_cell_pools.has(reuse_id):
				_cell_pools[reuse_id] = []
			
			_cell_pools[reuse_id].append(cell)
			_content_container.remove_child(cell)
			_visible_cells.erase(row)
	
	# 创建/更新可见单元格
	var cell_width = _content_container.size.x
	for row in range(first_visible_row, last_visible_row + 1):
		if !_visible_cells.has(row):
			var cell: Control = data_source.cell_for_row_at(self, row)
			if cell:
				cell.position = Vector2(0, _row_offsets[row])
				cell.custom_minimum_size = Vector2(cell_width, _row_offsets[row + 1] - _row_offsets[row])
				_visible_cells[row] = cell
				_content_container.add_child(cell)
		else:
			var cell = _visible_cells[row]
			cell.position = Vector2(0, _row_offsets[row])
			cell.custom_minimum_size = Vector2(cell_width, _row_offsets[row + 1] - _row_offsets[row])
	

func _clear_cells() -> void:
	for child in _content_container.get_children():
		_content_container.remove_child(child)
		child.queue_free()
	
	_visible_cells.clear()
	_cell_pools.clear()


func _get_row_index_for_offset(offset: float) -> int:
	if _row_offsets.is_empty():
		return 0
	
	var low = 0
	var high = _row_offsets.size() - 1
	
	while low <= high:
		var mid = low + (high - low) / 2
		if _row_offsets[mid] < offset:
			low = mid + 1
		else:
			high = mid - 1
	
	return max(0, high)


# 方法存在性验证
func _validate_data_source(obj: Object) -> bool:
	return obj.has_method("number_of_rows") \
		and obj.has_method("height_for_row_at") \
		and obj.has_method("cell_for_row_at")

# singal

func _on_scroll(value: float):
	_update_visible_cells()


func _on_resized():
	_update_content_size()
	_update_visible_cells()
