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
			var bp_manager = owner 
			if bp_manager and bp_manager.has_method("start_placing_blueprint"):
				bp_manager.start_placing_blueprint(current_data)
				
				# ✅ 关键：强制释放焦点和状态
				# 这会让按钮以为你已经“松开了”，从而把鼠标控制权还给世界
				release_focus() 
				button_pressed = false
