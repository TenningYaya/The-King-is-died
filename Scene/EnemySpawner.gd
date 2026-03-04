extends Node2D
class_name EnemySpawner

# ---------------- 配置区域 ----------------

# 1. 注册敌人场景：将字符串映射到对应的 PackedScene
# 在检查器中配置：{"tank": res://.../Enemy_Tank.tscn, "mage": res://.../Enemy_Mage.tscn, ...}
@export var enemy_scenes: Dictionary[String, PackedScene] = {}

# 2. 刷怪点集合：避免怪物全部重叠在同一个坐标
# 可以在场景中放置几个 Marker2D 节点，并将它们分配给这个数组
@export var spawn_points: Array[Node2D] = []

# 3. 波次数据结构
# 使用 Array 存储按顺序排列的波次，每个波次是一个 Dictionary。
var waves: Array[Dictionary] = []

# ---------------- 状态变量 ----------------
var current_time: float = 0.0
var current_wave_index: int = 0
var is_spawning_finished: bool = false

func _ready() -> void:
	# 初始化波次数据。
	# 未来如果波次变多，你可以把这部分数据移到外部 JSON 文件中解析，这里为了方便直接在代码里初始化。
	waves = [
		{
			"spawn_time": 15.0, 
			"spawn_list": { "tank": 2 }
		},
		{
			"spawn_time": 25.0, 
			"spawn_list": { "mage": 1, "tank": 1, "assassin": 1 }
		},
		{
			"spawn_time": 30.0, 
			"spawn_list": { "boss": 1 }
		}
	]

func _process(delta: float) -> void:
	if is_spawning_finished:
		return
		
	# 累加游戏时间。因为通过 Engine.time_scale 控制了游戏速度，
	# 这里的 delta 会自动适应暂停、1倍速、2倍速和3倍速，无需额外处理时间逻辑。
	current_time += delta
	
	# 获取当前等待生成的波次
	var next_wave = waves[current_wave_index]
	
	# 检查是否达到了生成时间
	if current_time >= next_wave["spawn_time"]:
		_spawn_wave(next_wave["spawn_list"])
		
		# 推进到下一波
		current_wave_index += 1
		if current_wave_index >= waves.size():
			is_spawning_finished = true

# ---------------- 生成逻辑 ----------------

func _spawn_wave(spawn_list: Dictionary) -> void:
	# 遍历这一波需要生成的所有敌人类型
	for enemy_type in spawn_list.keys():
		var count: int = spawn_list[enemy_type]
		for i in range(count):
			_spawn_single_enemy(enemy_type)

func _spawn_single_enemy(enemy_type: String) -> void:
	# 安全检查：确保我们要生成的敌人在注册表中存在
	if not enemy_scenes.has(enemy_type) or enemy_scenes[enemy_type] == null:
		push_error("EnemySpawner: 无法生成敌人，未找到或未绑定该类型的场景 -> " + enemy_type)
		return
		
	var scene: PackedScene = enemy_scenes[enemy_type]
	var enemy_instance = scene.instantiate()
	
	# 决定生成位置（不确定的地方：如果你们的游戏有特定的出怪规律，需要在这里修改）
	if spawn_points.size() > 0:
		# 随机选择一个刷怪点
		var random_point = spawn_points.pick_random()
		enemy_instance.global_position = random_point.global_position
	else:
		# 明确标注不确定的地方：如果没有配置刷怪点，默认生成在 Spawner 自身的位置。
		# 在王之凝视这类游戏中，通常会有地图边缘的特定入口，请务必绑定 spawn_points。
		enemy_instance.global_position = self.global_position
		
	# 将生成的敌人加入场景树。
	# 推荐将其作为 Spawner 的子节点，方便层级管理。
	add_child(enemy_instance)
