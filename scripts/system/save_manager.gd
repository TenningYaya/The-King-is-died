#save_manager.gd
extends Node
# 这是一个单例 (Autoload)，可以在全局调用

const SAVE_PATH = "user://savegame.json"

# 保存游戏
func save_game(resource_manager: LevelResourceManager):
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		print("无法创建文件: ", FileAccess.get_open_error())
		return

	# 1. 收集数据
	var full_data = {
		"version": "1.0",
		"timestamp": Time.get_datetime_string_from_system(),
		"resources": resource_manager.get_save_data() # 调用刚才写的函数
	}

	# 2. 转换成 JSON 字符串并保存
	var json_string = JSON.stringify(full_data, "\t") # "\t" 让导出的 JSON 文件带缩进，人类可读
	file.store_line(json_string)
	file.close()
	print("存档已保存至: ", OS.get_user_data_dir())

# 读取游戏
func load_game(resource_manager: LevelResourceManager) -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("找不到存档文件")
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error == OK:
		var data = json.data
		# 3. 将数据分发回各个管理器
		if data.has("resources"):
			resource_manager.load_save_data(data["resources"])
		return true
	else:
		print("JSON 解析失败: ", json.get_error_message())
		return false
