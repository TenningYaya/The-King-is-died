# combat_building.gd
extends Building
class_name CombatBuilding

# 存储当前由本建筑生产且在场的单位
var active_minions: Array = []

func _ready():
	super._ready() # 这会运行基类的图标设置和缩放逻辑

	# 确保在场单位上限至少为 1 (复用 BuildingData 中的 amount_per_cycle)
	if data and data.amount_per_cycle <= 0:
		data.amount_per_cycle = 1

func _process(delta):
	# 第一步：清理已经死亡（无效）的单位引用
	_cleanup_minions()
	
	# 第二步：执行父类逻辑（包含位移跟随、搬迁惩罚和生产判定）
	super._process(delta)

# 重写生产判定逻辑
func _tick_production(delta):
	if not data: return
	
	# 检查在场单位是否已达上限
	if active_minions.size() >= data.amount_per_cycle:
		# 达到上限，进度条停止，清空当前进度
		if progress_pie:
			progress_pie.value = 0
		current_progress = 0.0
		return 
	
	# 如果没满，则执行父类的“凝视生产”逻辑（处理 delta、multiplier 和进度累加）
	super._tick_production(delta)
	
	# 检查进度是否刚刚完成（current_progress 归零，说明触发了一个周期）
	# old_progress 来自物理帧记录，用于捕捉重置瞬间
	if current_progress <= 0.0 and old_progress > 0.9:
		_spawn_minion()

# 记录上一帧进度用于捕捉“进度条跑满重置”的瞬间
var old_progress: float = 0.0
func _physics_process(_delta):
	old_progress = current_progress

func _spawn_minion():
	if data == null or data.minion_scene == null:
		print("[%s] 错误：未发现士兵场景！" % name)
		return

	var minion = data.minion_scene.instantiate()
	minion.creator_building_name = self.name
	get_parent().add_child(minion)

	# 寻找出生点节点
	var spawn_point = get_tree().get_first_node_in_group("spawn_point")
	if spawn_point:
		minion.global_position = spawn_point.global_position
	else:
		# 找不到出生点就退回建筑旁边
		minion.global_position = self.global_position + Vector2(50, 0)
		print("[%s] 警告：场景中没有找到 spawn_point 组的节点" % name)

	active_minions.append(minion)
	print("[%s] 成功召唤单位，当前场内: %d/%d" % [data.building_name, active_minions.size(), data.amount_per_cycle])

func _cleanup_minions():
	# 过滤掉已经被 queue_free() 的节点（即被打死的单位）
	# 只要这里过滤掉一个，上面的 _tick_production 就会检测到 size < limit，从而自动重启进度条补兵
	active_minions = active_minions.filter(func(m): return is_instance_valid(m))

func get_save_data() -> Dictionary:
	# 1. 先拿父类存好的位置、进度、惩罚状态等
	var dict = super.get_save_data()
	
	# 2. 存入当前活着的士兵的名字（用于读档后“找妈妈”的校验）
	var minion_names = []
	for m in active_minions:
		if is_instance_valid(m):
			minion_names.append(m.name)
	
	dict["minion_names"] = minion_names
	return dict
