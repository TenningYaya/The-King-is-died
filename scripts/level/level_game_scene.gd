# level_game_scene.gd
extends Node2D

func _ready():
	# 所有的子节点（Gaze, Manager等）现在都已经运行完它们的 _ready() 并领完钱了
	if GamedataManager.is_loading_save:
		print("所有节点已领完数据，正在清空缓存并关闭读档模式...")
		GamedataManager.is_loading_save = false
		GamedataManager.full_save_dict = {} # 清空，防止内存占用或二次误读
