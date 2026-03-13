# blueprint_slot.gd
extends Button

@onready var icon_node = $Icon
@onready var label_node = $CountLabel

var current_data: BuildingData = null
var is_in_sell_mode: bool = false
var is_affordable: bool = true # 新增：标记当前建筑是否买得起

func _ready():
	add_to_group("blueprint_slots")
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# 连接资源管理器信号
	var manager = get_tree().get_first_node_in_group("level_manager")
	if manager:
		manager.level_resource_changed.connect(_on_resources_changed)

# --- 资源检测逻辑 ---
func _on_resources_changed(_id, _amount):
	_update_affordability_visual()

func _update_affordability_visual():
	if not current_data:
		return
		
	# 检查资源是否足够
	is_affordable = _check_can_afford(current_data)
	
	# 视觉反馈
	if is_affordable:
		icon_node.modulate = Color(1, 1, 1, 1) # 正常
		# 只有买得起时才启用按钮，除非是在出售模式
		disabled = false if not is_in_sell_mode else false
	else:
		icon_node.modulate = Color(0.5, 0.5, 0.5, 0.9) # 置灰
		# 买不起时禁用按钮（这样就点不动了）
		if not is_in_sell_mode:
			disabled = true

func _check_can_afford(data: BuildingData) -> bool:
	var manager = get_tree().get_first_node_in_group("level_manager")
	if not manager or data.cost.is_empty():
		return true
		
	for res_index in data.cost.keys():
		var res_id = BuildingData.get_resource_id_name(res_index)
		if manager.get_amount(res_id) < data.cost[res_index]:
			return false
	return true

# --- 修改原有的 display 函数 ---
func display(data: BuildingData, count: int):
	current_data = data
	icon_node.texture = data.icon
	icon_node.visible = true
	label_node.text = str(count)
	
	# 每次显示新数据时，立即刷新一次亮暗状态
	_update_affordability_visual()

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and current_data:
			# 如果买不起且不在出售模式，直接拦截，不让拖拽
			if not is_affordable and not is_in_sell_mode:
				return

			if is_in_sell_mode:
				_execute_sell()
				accept_event()
				return

			var bp_manager = owner 
			if bp_manager and bp_manager.has_method("start_placing_blueprint"):
				bp_manager.start_placing_blueprint(current_data)
				release_focus() 
				button_pressed = false

# --- 视觉高亮修复 ---
func _on_mouse_entered():
	if is_in_sell_mode and current_data:
		modulate = Color(2, 0.5, 0.5) 
	elif not is_affordable:
		# 买不起时移入也没反应
		pass

func _on_mouse_exited():
	modulate = Color(1, 1, 1)

func clear_slot():
	current_data = null
	icon_node.texture = null
	icon_node.visible = false
	label_node.text = ""
	disabled = true # 没东西时不让点

func _execute_sell():
	# 1. 玩家获得 Q-Coin (sell_value)
	var manager = get_tree().get_first_node_in_group("level_manager")
	if manager:
		manager.add_resource("q_coin", current_data.sell_value)
	
	# 2. 调用管理器扣除蓝图数量
	# 假设你的 BlueprintUI 节点也在 blueprint_manager 分组
	var bp_ui = get_tree().get_first_node_in_group("blueprint_manager")
	if bp_ui and bp_ui.has_method("consume_blueprint"):
		bp_ui.consume_blueprint(current_data)
	
	# 3. 通知 SellButton 恢复正常鼠标
	var sell_btn = get_tree().get_first_node_in_group("sell_button_node")
	if sell_btn:
		sell_btn.reset_mode()
