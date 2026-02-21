#producer_building.gd
extends Building
class_name ProducerBuilding

var total_produced: int = 0

func _on_cycle_complete():
	total_produced += data.amount_per_cycle
	print("[%s] 产出了资源! 总量: %d/%d" % [data.building_name, total_produced, data.max_production])
	
	# 核心逻辑：达到上限销毁
	if data.max_production > 0:
		if total_produced >= data.max_production:
			_handle_limit_reached()

func _handle_limit_reached():
	is_active = false
	print("产量已满，准备拆除...")
	await get_tree().create_timer(1.0).timeout
	queue_free()
