# building_manager.gd
extends Node

@export var production_scene: PackedScene
@export var market_scene: PackedScene
@export var combat_scene: PackedScene

# 你存放所有建筑实例的父节点（建议在场景里专门搞一个 Node2D 叫 Structures）
@onready var structure_container = get_node("/root/Game/Structures") 

func _ready():
	# 2. 主动认领数据
	if GamedataManager.is_loading_save:
		var my_data = GamedataManager.get_data_for_node(name) # 确保节点名就是 BuildingManager
		if not my_data.is_empty():
			load_save_data(my_data)
		else:
			print("[建筑调试] 缓存中没有我的数据！JSON里的Key有: ", GamedataManager.full_save_dict.keys())
			
func get_save_data() -> Dictionary:
	var list = []
	var nodes = get_tree().get_nodes_in_group("buildings")
	print("[存档调试] 扫描到建筑数量: ", nodes.size()) # 重点看这里是不是 0
	for b in nodes:
		if is_instance_valid(b):
			list.append(b.get_save_data())
	return {"all_buildings": list}

func load_save_data(data: Dictionary):
	if not data.has("all_buildings"): return
	
	# 1. 强制立即清理，不要等待帧末
	for b in structure_container.get_children():
		structure_container.remove_child(b) # 先移除关系
		b.free() # 立即释放内存
	
	# 2. 稍微延迟一点点再开始生成，确保物理世界已经更新
	var buildings_list = data["all_buildings"]
	for b_info in buildings_list:
		_spawn_saved_building(b_info)

func _spawn_saved_building(info: Dictionary):
	var res_path = info["res_path"]
	if not ResourceLoader.exists(res_path): return
	
	var b_data = load(res_path)
	var new_b: Building
	
	# --- 修复后的安全判定逻辑 ---
	var p_type = ""
	if "product_type" in b_data:
		p_type = b_data.product_type
	
	var has_minion = false
	if "minion_scene" in b_data:
		has_minion = b_data.minion_scene != null
	
	# --- 判定分支 ---
	if has_minion:
		new_b = combat_scene.instantiate()
	elif p_type == "spirit_stone":
		new_b = market_scene.instantiate()
	else:
		new_b = production_scene.instantiate()
		
	if info.has("node_name"): 
		new_b.name = info["node_name"]
	# --- 核心：先赋 Data，再入场 ---
	new_b.data = b_data
	structure_container.add_child(new_b)
	
	# --- 还原所有细节状态 ---
	new_b.global_position = Vector2(info["pos_x"], info["pos_y"])
	new_b.current_progress = info["progress"]
	new_b.is_active = info.get("is_active", true)
	new_b.is_under_penalty = info.get("is_under_penalty", false)
	new_b.penalty_timer = info.get("penalty_timer", 0.0)
	
	if "total_produced" in new_b:
		new_b.total_produced = info.get("total_produced", 0)

	# --- 视觉与 UI 强行同步 ---
	if new_b.has_method("_setup_visuals"):
		new_b._setup_visuals()
	
	if new_b is MarketBuilding:
		new_b.current_target_resource = info.get("market_target", "")
		new_b.next_target_resource = info.get("market_target", "")
		new_b.call_deferred("_update_main_button_ui")
	if new_b is CombatBuilding:
		new_b.active_minions = [] # 强行清空，等待 SaveManager 补人
		#new_b.is_active = false
		
	_rebind_slot(new_b)

func _rebind_slot(b: Building):
	# 等待一帧确保物理碰撞生效，或者直接用点探测
	await get_tree().process_frame 
	var areas = b.get_overlapping_areas()
	for a in areas:
		if a.is_in_group("slots"):
			b.set_initial_slot(a)
			break
