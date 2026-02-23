extends CanvasLayer

# 建立一个字典，把资源 ID 映射到对应的 Label 节点
# 请确保这些节点路径与你场景树中的实际路径一致
@onready var labels = {
	"elixir": $Background/GridContainer/ElixirItem/ElixirLabel,
	"herb": $Background/GridContainer/HerbItem/HerbLabel,
	"aether_crystal": $Background/GridContainer/CrystalItem/CrystalLabel,
	"mystic_iron": $Background/GridContainer/IronItem/IronLabel,
	"spirit_stone": $Background/GridContainer/StoneItem/StoneLabel,
	"q_coin": $Background/GridContainer/CoinItem/CoinLabel
}

func _ready():
	# 1. 找到场景中的资源管理器（使用了你队友定义的 group: level_manager）
	var manager = get_tree().get_first_node_in_group("level_manager")
	
	if manager:
		# 2. 连接信号：当资源变动时，执行我们的 _on_resource_changed 函数
		manager.level_resource_changed.connect(_on_resource_changed)
		
		# 3. 初始化：把当前的数值先显示出来
		for res_id in labels.keys():
			var current_val = manager.get_amount(res_id)
			_update_label_text(res_id, current_val)
	else:
		push_error("ResourceBar错误：找不到带有 'level_manager' 分组的节点！")

# 收到信号后的回调函数
func _on_resource_changed(res_id: String, new_amount: int):
	_update_label_text(res_id, new_amount)

# 更新文字的具体逻辑
func _update_label_text(res_id: String, amount: int):
	if labels.has(res_id) and labels[res_id] != null:
		labels[res_id].text = str(amount)
		
