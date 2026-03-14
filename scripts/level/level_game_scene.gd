# level_game_scene.gd
extends Node2D

#func _ready():
	#if GamedataManager.is_loading_save:
		## 调用你刚才写在 SaveManager 里的那个 load_game 逻辑
		## 如果 SaveManager 是全局单例，直接调：
		#SaveManager.load_game_from_dict(GamedataManager.full_save_dict)
		#
		## 读完记得关掉开关
		#GamedataManager.is_loading_save = false
		#GamedataManager.full_save_dict = {}

func _ready():
	if GamedataManager.is_loading_save:
		# 1. 强制等一帧，确保 BuildingManager 盖完了房
		await get_tree().process_frame 
		
		# 2. 塞兵逻辑（这里面不用写 is_active = true 了）
		SaveManager.load_game_from_dict(GamedataManager.full_save_dict)
		
		# 3. 【核心点火】全场建筑，统一开工！
		# 这样即便某个建筑读档时没兵，它现在也会发现自己没兵，从而开始补生产
		get_tree().call_group("buildings", "set_active_status", true)
		
		GamedataManager.is_loading_save = false
