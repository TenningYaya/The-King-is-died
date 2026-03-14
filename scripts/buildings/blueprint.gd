# blueprint.gd
extends Area2D

var data: BuildingData 
var building_scene: PackedScene 
var resource_manager: LevelResourceManager
var is_dragging: bool = false 
var current_slot: Area2D = null 
var is_affordable: bool = false

@onready var sprite: Sprite2D = $Sprite2D

func setup_blueprint(building_data: BuildingData):
	self.data = building_data
	if data.base_scene_path != "":
		self.building_scene = load(data.base_scene_path)
	
	if sprite and data.icon:
		sprite.texture = data.icon
	
	# 视觉：保持原色，仅设置透明度
	modulate = Color(1, 1, 1, 0.7) 
	update_affordability()

func _ready():
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	resource_manager = get_tree().get_first_node_in_group("level_manager")
	
	if resource_manager:
		resource_manager.level_resource_changed.connect(_on_global_resource_changed)
		# 强制初始检查
		update_affordability()
	else:
		print("[蓝图调试] 警告：未能找到 level_manager 组！检查场景节点设置。")
		
func _process(_delta):
	if is_dragging:
		global_position = get_global_mouse_position()
		
		# --- 修复后的逻辑 ---
		if not is_affordable:
			# 如果买不起，无论在哪都显示“禁用暗色”
			modulate = Color(0.2, 0.2, 0.2, 0.8) 
		else:
			# 只有在买得起的情况下，才显示地块的红白反馈
			if current_slot == null:
				modulate = Color(1, 0.3, 0.3, 0.7) # 红色：不能放
			else:
				modulate = Color(1, 1, 1, 0.7)     # 原色：可以放
		
func _input(event):
	if is_dragging and event is InputEventMouseButton:
		# 只要监听到左键松开（not event.pressed）
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_on_release()
			
func _on_release():
	is_dragging = false
	if current_slot:
		_start_working()
	else:
		queue_free()

func _start_working():
	var can_afford_now = true
	var charged_resources = [] # 记录已经扣除的资源，用于如果中途失败好回滚（可选）

	for res_index in data.cost.keys():
		var res_id = BuildingData.get_resource_id_name(res_index)
		var amount = data.cost[res_index]
		
		# 调用管理器的消耗函数
		if not resource_manager.consume_resource(res_id, amount):
			can_afford_now = false
			break
	
	# 2. 如果扣费过程中发现钱突然不够了
	if not can_afford_now:
		_handle_build_failed()
		return

	# 1. 实例化真实的建筑（如 Production.tscn）
	var new_building = building_scene.instantiate()
	
	# 2. 核心修复：注入数据！
	# 这一步必须在 add_child 之前，这样建筑的 _ready() 运行时间才能读取到数据并启动进度条
	if "data" in new_building:
		new_building.data = self.data 
	
	# 3. 将建筑添加到世界层（Game 节点）
	get_parent().add_child(new_building)
	new_building.global_position = current_slot.global_position
	
	# 4. 锁定地块并传递格子引用
	current_slot.set_meta("is_occupied", true)
	if "current_slot" in new_building:
		new_building.current_slot = current_slot
			
	# 5. 扣除 UI 蓝图数量
	var bp_ui = get_node_or_null("/root/Game/BlueprintUI")
	if bp_ui and bp_ui.has_method("consume_blueprint"):
		bp_ui.consume_blueprint(self.data)
	queue_free()

func _handle_build_failed():
	queue_free()
	
func _on_area_entered(area):
	if area.is_in_group("slots") and not area.get_meta("is_occupied", false):
		current_slot = area

func _on_area_exited(area):
	if area == current_slot:
		current_slot = null

			
func _on_global_resource_changed(_id, _amount):
	update_affordability()

func update_affordability():
	is_affordable = _check_resources_sufficient()
	# 变暗/变亮的视觉处理
	if is_affordable:
		modulate = Color(1, 1, 1, 0.7) 
	else:
		modulate = Color(0.2, 0.2, 0.2, 0.8)

func _check_resources_sufficient() -> bool:
	if not resource_manager or not data: return true
	print("[调试] 当前建筑: ", data.building_name, " | Cost字典内容: ", data.cost, " | Size: ", data.cost.size())
	
	if data.cost.is_empty(): 
		# print("此建筑无消耗，检查通过")
		return true
	
	for res_index in data.cost.keys():
		# 1. 转换 ID
		var res_id = BuildingData.get_resource_id_name(res_index) 
		
		# 2. 获取数值
		var needed = data.cost[res_index]
		var owned = resource_manager.get_amount(res_id)
		
		# 3. 打印详细信息
		if owned < needed:
			return false
			
	return true
