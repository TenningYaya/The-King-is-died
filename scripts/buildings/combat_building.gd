# combat_building.gd
extends Building
class_name CombatBuilding

# 引用要生成的士兵/防御塔单位场景 (可以在 BuildingData 加个字段，或者在这里 export)
@export var minion_scene: PackedScene 

# 存储当前由本建筑生产且在场的单位
var active_minions: Array = []

func _ready():
	super._ready()
	# 确保在场单位上限至少为 1
	if data and data.amount_per_cycle <= 0:
		data.amount_per_cycle = 1

func _process(delta):
	# 第一步：清理已经死亡（无效）的单位引用
	_cleanup_minions()
	
	# 第二步：执行父类逻辑（包含位移和生产判定）
	super._process(delta)

# 重写生产判定逻辑
func _tick_production(delta):
	# 检查在场单位是否已达上限 (复用 amount_per_cycle 作为在场上限)
	if active_minions.size() >= data.amount_per_cycle:
		# 达到上限，进度条停止或重置，不执行生产
		if progress_pie:
			progress_pie.value = 0
		current_progress = 0.0
		return 
	
	# 如果没满，则执行父类的“凝视生产”逻辑
	super._tick_production(delta)
	
	# 检查进度是否完成（因为父类里没写完成后的钩子，我们在子类判定）
	if current_progress <= 0.0 and old_progress > 0.9: # 进度刚重置说明完成了一个周期
		_spawn_minion()

# 记录上一帧进度用于判定周期结束
var old_progress: float = 0.0
func _physics_process(_delta):
	old_progress = current_progress

func _spawn_minion():
	if minion_scene == null:
		print("[%s] 错误：未指定生产单位场景" % data.building_name)
		return
		
	var minion = minion_scene.instantiate()
	# 将单位放入世界层
	get_parent().add_child(minion)
	# 初始位置在建筑中心
	minion.global_position = self.global_position
	
	# 记录到数组中
	active_minions.append(minion)
	print("[%s] 生产了单位，当前在场: %d/%d" % [data.building_name, active_minions.size(), data.amount_per_cycle])

func _cleanup_minions():
	# 过滤掉已经被 queue_free() 的节点
	active_minions = active_minions.filter(func(m): return is_instance_valid(m))
