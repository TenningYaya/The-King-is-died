extends Building
class_name ProducerBuilding

var total_produced: int = 0

func _on_production_finished():
	# 读取资源数量加成
	var amount_bonus: int = int(UpgradeManager.get_flat("resource_amount_1") + UpgradeManager.get_flat("resource_amount_2"))
	var total_amount: int = data.amount_per_cycle + amount_bonus

	total_produced += total_amount

	var manager = get_tree().get_first_node_in_group("level_manager")
	if manager:
		manager.add_resource(data.product_type, total_amount)
		show_production_popup(data.product_type, total_amount)
	else:
		push_error("ProducerBuilding错误：找不到带有 'level_manager' 分组的节点！")

	if data.max_production > 0:
		if total_produced >= data.max_production:
			_handle_limit_reached()

func _handle_limit_reached():
	is_active = false
	await get_tree().create_timer(0.5).timeout
	queue_free()
