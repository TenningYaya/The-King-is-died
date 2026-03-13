extends Node
const SAVE_PATH = "user://savegame.json"

func save_game():
	var full_data = {}
	
	# 自动收集：找到场景中所有属于 "save_required" 分组的节点
	var save_nodes = get_tree().get_nodes_in_group("save_required")
	
	for node in save_nodes:
		# 检查节点是否有 get_save_data 函数
		if node.has_method("get_save_data"):
			# 以节点名字作为 Key，存入它们的数据
			full_data[node.name] = node.get_save_data()
	
	# 写入文件
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_line(JSON.stringify(full_data, "\t"))
	file.close()
	print("全自动存档完成！")

func load_game():
	if not FileAccess.file_exists(SAVE_PATH): return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	
	# 自动分发：找到场景中所有属于 "save_required" 分组的节点
	var save_nodes = get_tree().get_nodes_in_group("save_required")
	for node in save_nodes:
		if data.has(node.name) and node.has_method("load_save_data"):
			node.load_save_data(data[node.name])
	print("全自动读档完成！")
