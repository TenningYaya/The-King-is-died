# TestPanel.gd
extends VBoxContainer

@export_dir var tres_folder_path: String = "res://resources/"

func _ready():
	for button in get_children():
		if button is Button:
			button.pressed.connect(_on_test_button_pressed.bind(button.name))

func _on_test_button_pressed(b_name: String):
	var file_path = tres_folder_path + b_name + ".tres"
	
	if FileAccess.file_exists(file_path):
		var data = load(file_path) as BuildingData
		if data:
			# ✅ 修改这里：根据你的截图，BlueprintUI 是 TestButtons 的父级
			# 使用 owner 可以直接拿到该场景的根节点（即挂了新 Manager 的 BlueprintUI）
			var bp_manager = owner 
			
			if bp_manager and bp_manager.has_method("add_blueprint"):
				bp_manager.add_blueprint(data)
				print("发号器：成功调用 BlueprintUI 上的管理器发放 - ", b_name)
			else:
				# 保底方案：如果 owner 不行，尝试 get_parent()
				bp_manager = get_parent()
				if bp_manager and bp_manager.has_method("add_blueprint"):
					bp_manager.add_blueprint(data)
				else:
					push_error("错误：找不到挂载了 add_blueprint 的 BlueprintUI 节点！")
	else:
		push_error("错误：找不到文件 " + file_path + "，请确认按钮名和文件名一致（区分大小写和空格）")
