# Slot.gd
extends Button

@onready var icon_node = $Icon
@onready var label_node = $CountLabel

var current_data: BuildingData = null
var is_in_sell_mode: bool = false

func _ready():
	# 🔴 关键：加入分组，以便 SellButton 能批量控制所有格子
	add_to_group("blueprint_slots")
	
	# 连接鼠标移入移出信号，处理高亮
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
# --- 供 SellButton 调用函数 ---
func enter_sell_mode():
	is_in_sell_mode = true

func exit_sell_mode():
	is_in_sell_mode = false
	modulate = Color(1, 1, 1) # 恢复原色

# --- 视觉高亮 ---
func _on_mouse_entered():
	if is_in_sell_mode and current_data:
		# 变红高亮，表示“回收”
		modulate = Color(2, 0.5, 0.5) 

func _on_mouse_exited():
	modulate = Color(1, 1, 1)

func clear_slot():
	current_data = null
	icon_node.texture = null
	icon_node.visible = false
	label_node.text = ""
	disabled = true # 没东西时不让点

func display(data: BuildingData, count: int):
	current_data = data
	icon_node.texture = data.icon
	icon_node.visible = true
	label_node.text = str(count)
	disabled = false

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and current_data:
			# 分支 1：出售模式
			if is_in_sell_mode:
				_execute_sell()
				accept_event() # 拦截点击，不触发背景的“退出模式”逻辑
				return

			# 分支 2：原有的放置逻辑 (保持不变)
			var bp_manager = owner 
			if bp_manager and bp_manager.has_method("start_placing_blueprint"):
				bp_manager.start_placing_blueprint(current_data)
				
				# ✅ 关键：强制释放焦点和状态
				# 这会让按钮以为你已经“松开了”，从而把鼠标控制权还给世界
				release_focus() 
				button_pressed = false

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
