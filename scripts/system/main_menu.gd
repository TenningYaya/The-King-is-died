#main_menu.gd
extends CanvasLayer

func _on_new_pressed() -> void:
	# 1. 删除存档文件
	var save_path = "user://savegame.json"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	
	# 2. 彻底重置中转站（把所有旧数据清空）
	GamedataManager.full_save_dict = {}  # 建议在中转站改用这个名字，代表全量数据
	GamedataManager.is_loading_save = false
	
	# 3. 切换场景
	get_tree().change_scene_to_file("res://Scene/Game.tscn")


func _on_load_pressed() -> void:
	var save_path = "user://savegame.json"
	if not FileAccess.file_exists(save_path):
		print("没有找到存档文件！")
		return
		
	# 1. 告诉中转站：我们要读档
	GamedataManager.is_loading_save = true
	
	# 2. 读取整个 JSON 字典
	var file = FileAccess.open(save_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(json_string)
	
	if data is Dictionary:
		# 3. 把整个大字典塞给中转站，让游戏场景里的各节点自己去领
		GamedataManager.full_save_dict = data
		get_tree().change_scene_to_file("res://Scene/Game.tscn")
	else:
		print("存档格式错误！")
