#gamedata_manager.gd
extends Node

var full_save_dict: Dictionary = {}
var is_loading_save = false # 一个开关：告诉游戏场景“这次进入是读档还是新开”

func _ready():
	if GamedataManager.is_loading_save:
		# 1. 先等待一帧。
		# 这一帧里，固定节点（BuildingManager, Gaze, Wall）会跑完自己的 _ready，
		# 它们会自发地通过 GamedataManager.get_data_for_node(name) 领走自己的数据。
		await get_tree().process_frame
		
		# 2. 此时固定节点已经加载好了，我们只让 SaveManager 把缺失的小兵补上
		SaveManager.load_dynamic_units_only(GamedataManager.full_save_dict)
		
		# 3. 恭喜！全场数据同步完成，关闭读档模式
		GamedataManager.is_loading_save = false
		GamedataManager.full_save_dict = {}
		print("--- 场景切换后的动态补偿加载已完成 ---")
		
func reset_data():
	full_save_dict = {}
	is_loading_save = false

func get_data_for_node(node_name: String) -> Dictionary:
	if is_loading_save and full_save_dict.has(node_name):
		return full_save_dict[node_name]
	return {}
