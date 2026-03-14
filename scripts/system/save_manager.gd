# save_manager.gd
extends Node
const SAVE_PATH = "user://savegame.json"

# --- 存档逻辑 ---
func save_game():
	var full_data = {}
	# 1. 静态节点 (Gaze, Wall等)
	var save_nodes = get_tree().get_nodes_in_group("save_required")
	for node in save_nodes:
		if node.has_method("get_save_data"):
			full_data[node.name] = node.get_save_data()
	
	# 2. 动态单位 (小兵和敌人)
	var dynamic_units_data = []
	var all_units = get_tree().get_nodes_in_group("player_units") + get_tree().get_nodes_in_group("enemy_units")
	for unit in all_units:
		if unit is Unit_General and not unit.is_in_group("save_required"):
			dynamic_units_data.append(unit.get_save_data())
	
	full_data["dynamic_units"] = dynamic_units_data
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_line(JSON.stringify(full_data, "\t"))
	file.close()
	print("存档成功！已记录 %d 个动态单位" % dynamic_units_data.size())

func _execute_loading_logic(data: Dictionary):
	print("\n--- [SaveManager] 开始补全动态单位 ---")
	
	if not data.has("dynamic_units") or data["dynamic_units"].is_empty():
		print("  ℹ️ 存档中没有需要恢复的小兵。")
		return

	# 1. 清理现场
	for old_unit in get_tree().get_nodes_in_group("player_units") + get_tree().get_nodes_in_group("enemy_units"):
		if not old_unit is Wall:
			old_unit.queue_free()

	# 2. 循环生成
	for u_info in data["dynamic_units"]:
		var scene_path = u_info.get("scene_path", "")
		if scene_path == "" or not ResourceLoader.exists(scene_path): 
			continue
		
		var unit_scene = load(scene_path)
		var unit = unit_scene.instantiate()
		get_tree().current_scene.add_child(unit)
		
		# 给小兵灌入属性
		unit.load_save_data(u_info)
		
		# 3. 握手环节
		var target_id = unit.creator_building_name
		if target_id != "":
			# 尝试搜索建筑
			var creator = get_tree().current_scene.find_child(target_id, true, false)
			if not creator:
				creator = get_node_or_null(target_id)
				
			# --- 核心修复：只有 creator 真正存在时才操作 ---
			if creator != null:
				if creator is CombatBuilding:
					if not unit in creator.active_minions:
						creator.active_minions.append(unit)
						creator.is_active = true  # 找到了才解冻
						print("  ✅ 关联成功: %s -> %s" % [unit.name, creator.name])
			else:
				# 找不到就打印，不要再尝试给 creator 赋值了！
				print("  ❌ 关联失败：找不到名为 %s 的建筑" % str(target_id))

	print("--- [SaveManager] 动态单位补全完成 ---\n")

# --- 入口 1：对应你刚才报错的那个调用 ---
func load_game_from_dict(data: Dictionary):
	_execute_loading_logic(data)

# --- 入口 2：对应你 Game.gd 里的调用 ---
func load_dynamic_units_only(data: Dictionary):
	_execute_loading_logic(data)
