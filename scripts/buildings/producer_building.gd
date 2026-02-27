# producer_building.gd
extends Building
class_name ProducerBuilding

var total_produced: int = 0

# 重写基类的虚函数，当进度条满时会自动被调用
func _on_production_finished():
	# 1. 增加本地产出记录
	total_produced += data.amount_per_cycle
	
	# 2. 找到资源管理器并更新全局资源
	var manager = get_tree().get_first_node_in_group("level_manager")
	if manager:
		# 调用管理器的 add_resource 方法，这会触发 level_resource_changed 信号
		# 从而让 ResourceBar UI 自动更新
		manager.add_resource(data.product_type, data.amount_per_cycle)
	else:
		push_error("ProducerBuilding错误：找不到带有 'level_manager' 分组的节点！")
	
	# 3. 检查是否达到生产上限，达到则销毁
	if data.max_production > 0:
		if total_produced >= data.max_production:
			_handle_limit_reached()

func _handle_limit_reached():
	is_active = false
	print("[%s] 产量已满，建筑准备拆除..." % data.building_name)
	# 给一点延迟让玩家看到进度条满的状态
	await get_tree().create_timer(0.5).timeout
	queue_free()
