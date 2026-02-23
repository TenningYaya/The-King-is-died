# Slot.gd
extends Button

@onready var icon_node = $Icon
@onready var label_node = $CountLabel

var current_data: BuildingData = null

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
