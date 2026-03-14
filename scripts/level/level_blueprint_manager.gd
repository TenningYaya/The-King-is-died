# level_blueprint_manager.gd
extends CanvasLayer

enum FilterType { ALL, PRODUCTION, COMBAT }
var current_filter = FilterType.ALL
var inventory: Dictionary = {}

@export var slot_scene: PackedScene
@onready var grid_container = $Control/HBoxContainer/BlueprintsSlots
@onready var save_popup = $BackMainWindow
# 必须在 Inspector 中把 Blueprint.tscn 拖入这个槽位
@export var common_blueprint_scene: PackedScene 

func _ready():
	# 1. 确保它在组里
	add_to_group("save_required")
	
	# 2. 只有从 MainMenu 读档进来时才执行
	if GamedataManager.is_loading_save:
		# 这里一定要用 node.name 去匹配 JSON 里的 Key
		# 既然 JSON 里是 "BlueprintUI"，那这个 node.name 必须也是这个
		var my_data = GamedataManager.get_data_for_node(name)
		
		if not my_data.is_empty():
			load_save_data(my_data)
		else:
			print("[警告] 蓝图管理器领不到数据！JSON里只有: ", GamedataManager.full_save_dict.keys())
			
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
		
func get_save_data() -> Dictionary:
	var ordered_list = []
	
	# 如果你想按当前 UI 看到的顺序存，就遍历你的 inventory
	# 如果想更精确，可以遍历 grid_container 的子节点
	for data in inventory.keys():
		if data is BuildingData:
			var item = {
				"path": data.resource_path,
				"count": inventory[data]
			}
			ordered_list.append(item) # 数组会严格保持 append 的先后顺序
			
	return {"blueprint_array": ordered_list}

func load_save_data(data: Dictionary):
	if not data.has("blueprint_array"): return
	
	inventory.clear()
	var list = data["blueprint_array"]
	
	for item in list:
		var path = item["path"]
		var count = item["count"]
		if ResourceLoader.exists(path):
			var res = load(path)
			inventory[res] = count
	
	call_deferred("refresh_ui")

func _on_save_button_pressed() -> void:
	SaveManager.save_game()


func _on_exit_button_pressed() -> void:
	save_popup.open()
