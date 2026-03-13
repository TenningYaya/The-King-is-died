#gamedata_manager.gd
extends Node

var full_save_dict: Dictionary = {}
var is_loading_save = false # 一个开关：告诉游戏场景“这次进入是读档还是新开”

func reset_data():
	full_save_dict = {}
	is_loading_save = false

func get_data_for_node(node_name: String) -> Dictionary:
	if is_loading_save and full_save_dict.has(node_name):
		return full_save_dict[node_name]
	return {}
