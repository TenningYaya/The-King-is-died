# 挂载在 BlueprintUI (CanvasLayer) 上
extends CanvasLayer

enum FilterType { ALL, PRODUCTION, COMBAT }
var current_filter = FilterType.ALL
var inventory: Dictionary = {}

@export var slot_scene: PackedScene
@onready var grid_container = $Control/HBoxContainer/BlueprintsSlots

# 必须在 Inspector 中把 Blueprint.tscn 拖入这个槽位
@export var common_blueprint_scene: PackedScene 

func add_blueprint(data: BuildingData):
	if data == null: return
	if not inventory.has(data): inventory[data] = 0
	inventory[data] += 1
	refresh_ui()

func consume_blueprint(data: BuildingData):
	if inventory.has(data) and inventory[data] > 0:
		inventory[data] -= 1
		# 数量为 0 时移除键，这样 2x5 格子就会自动重排
		if inventory[data] <= 0: 
			inventory.erase(data)
		refresh_ui()

func _matches_current_filter(data: BuildingData) -> bool:
	if current_filter == FilterType.ALL: return true
	if current_filter == FilterType.PRODUCTION:
		return data.type == BuildingData.BuildingType.PRODUCTION
	return data.type == BuildingData.BuildingType.COMBAT

func change_filter(filter_index: int):
	current_filter = filter_index as FilterType
	refresh_ui()

func refresh_ui():
	if not grid_container: return
	var slots = grid_container.get_children()
	
	# 重置所有固定的 10 个格子
	for s in slots:
		if s.has_method("clear_slot"): 
			s.clear_slot()
	
	# 提取当前需要显示的蓝图数据
	var visible_list = []
	for data in inventory.keys():
		if inventory[data] > 0 and _matches_current_filter(data):
			visible_list.append(data)
	
	# 按顺序填充格子
	for i in range(visible_list.size()):
		if i < slots.size():
			slots[i].display(visible_list[i], inventory[visible_list[i]])

## --- 核心改动部分 ---
func start_placing_blueprint(data: BuildingData):
	var preview = common_blueprint_scene.instantiate()
	var game_node = get_node_or_null("/root/Game")
	
	if game_node:
		game_node.add_child(preview)
		preview.setup_blueprint(data)
		
		# 关键：生成即激活拖拽，且位置立即同步
		preview.is_dragging = true
		preview.global_position = preview.get_global_mouse_position()
