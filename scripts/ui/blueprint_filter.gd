# FilterButton.gd
extends Button

# 定义本地枚举，确保与 BlueprintManager 一致
enum Filter { ALL, PRODUCTION, COMBAT }
# 在 Inspector 里选择对应的类型
@export var filter_to_set: Filter = Filter.ALL

func _pressed():
	# 根据你的截图路径，owner 通常就是 BlueprintUI 根节点
	var bp_manager = owner 
	
	if bp_manager and bp_manager.has_method("change_filter"):
		# 转换为整数传递给 Manager
		bp_manager.change_filter(int(filter_to_set))
		print("已切换页签至: ", filter_to_set)
	else:
		# 如果找不到，尝试通过路径找（保底方案）
		var manual_find = get_tree().current_scene.find_child("BlueprintUI", true, false)
		if manual_find:
			manual_find.change_filter(int(filter_to_set))
