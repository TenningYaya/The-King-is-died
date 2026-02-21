extends Node
class_name LevelResourceManager

# 定义信号，用于通知 UI 刷新（例如局内的资源栏）
signal level_resource_changed(resource_id: String, new_amount: int)

# 局内基础资源池
# 每次关卡加载时，这个脚本实例被创建，字典会自动初始化为以下数值
var current_resources = {
	"elixir": 0,
	"herb": 0,
	"aether_crystal": 0,
	"mystic_iron": 0,
	"spirit_stone": 0,
	"q_coin": 0
}

# 增加资源（由建筑实体调用）
func add_resource(id: String, amount: int):
	if current_resources.has(id):
		current_resources[id] += amount
		level_resource_changed.emit(id, current_resources[id])
		print("局内资源更新 | ", id, ": ", current_resources[id])
	else:
		push_warning("尝试增加未定义的局内资源: " + id)

# 消耗资源（用于局内建造或升级，返回是否成功）
func consume_resource(id: String, amount: int) -> bool:
	if current_resources.has(id) and current_resources[id] >= amount:
		current_resources[id] -= amount
		level_resource_changed.emit(id, current_resources[id])
		return true
	return false

# 获取特定资源当前数量
func get_amount(id: String) -> int:
	return current_resources.get(id, 0)
