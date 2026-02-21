#producer_building.gd
extends Building
class_name ProducerBuilding

var total_produced: int = 0

func _on_cycle_complete():
	total_produced += data.amount_per_cycle
	
	var manager = get_tree().get_first_node_in_group("level_manager")
	if manager:
		# 调用管理器的 add_resource 方法
		# data.product_type 应该是在 BuildingData 资源里定义的字符串（如 "Resource_1"）
		manager.add_resource(data.product_type, data.amount_per_cycle)
	else:
		push_error("错误：场景中找不到带有 'level_manager' 分组的节点！")
	
	# 核心逻辑：达到上限销毁
	if data.max_production > 0:
		if total_produced >= data.max_production:
			_handle_limit_reached()

func _handle_limit_reached():
	is_active = false
	print("产量已满，准备拆除...")
	await get_tree().create_timer(1.0).timeout
	queue_free()
