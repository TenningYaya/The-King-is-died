extends Control

@onready var labels = {
	"elixir": $Background/GridContainer/ElixirItem/ElixirLabel,
	"herb": $Background/GridContainer/HerbItem/HerbLabel,
	"aether_crystal": $Background/GridContainer/CrystalItem/CrystalLabel,
	"mystic_iron": $Background/GridContainer/IronItem/IronLabel,
	"spirit_stone": $Background/GridContainer/StoneItem/StoneLabel,
	"q_coin": $Background/GridContainer/CoinItem/CoinLabel
}

var level_manager = null

func _ready():
	# 1. 普通资源：连接 level_manager
	level_manager = get_tree().get_first_node_in_group("level_manager")
	if level_manager:
		if not level_manager.level_resource_changed.is_connected(_on_resource_changed):
			level_manager.level_resource_changed.connect(_on_resource_changed)
		for res_id in labels.keys():
			if res_id == "q_coin":
				continue
			_update_label_text(res_id, level_manager.get_amount(res_id))
	else:
		push_error("ResourceBar错误：找不到带有 'level_manager' 分组的节点！")

	# 2. q_coin：连接 ResourceManager（autoload）
	print("[ResourceBar] ResourceManager found, currency:", ResourceManager.get_currency())
	if not ResourceManager.special_currency_changed.is_connected(_on_special_currency_changed):
		ResourceManager.special_currency_changed.connect(_on_special_currency_changed)
	_update_label_text("q_coin", ResourceManager.get_currency())

	print("[ResourceBar] ready complete")

func _on_resource_changed(res_id: String, new_amount: int):
	_update_label_text(res_id, new_amount)

func _on_special_currency_changed(new_amount: int):
	print("[ResourceBar] q_coin updated: ", new_amount)
	_update_label_text("q_coin", new_amount)

func _update_label_text(res_id: String, amount: int):
	if labels.has(res_id) and labels[res_id] != null:
		labels[res_id].text = str(amount)

func _on_999button_pressed():
	if level_manager:
		for res_id in labels.keys():
			if res_id == "q_coin":
				continue
			var current_val = level_manager.get_amount(res_id)
			var difference = 999 - current_val
			if difference > 0:
				level_manager.add_resource(res_id, difference)
			elif difference < 0:
				level_manager.consume_resource(res_id, abs(difference))
		ResourceManager.set_currency(999)
		print("测试：所有资源已设为 999")
	else:
		push_error("测试按钮错误：找不到 level_manager")

func _on_99button_pressed():
	if level_manager:
		for res_id in labels.keys():
			if res_id == "q_coin":
				continue
			var current_val = level_manager.get_amount(res_id)
			var difference = 99 - current_val
			if difference > 0:
				level_manager.add_resource(res_id, difference)
			elif difference < 0:
				level_manager.consume_resource(res_id, abs(difference))
		ResourceManager.set_currency(99)
		print("测试：所有资源已设为 99")
	else:
		push_error("测试按钮错误：找不到 level_manager")
