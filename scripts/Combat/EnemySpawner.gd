class_name EnemySpawner
extends Node2D

# ─────────────────────────────────────────
#  配置（在 Inspector 里设置）
# ─────────────────────────────────────────
# key: 敌人类型字符串（如 "tank"），value: 对应场景
@export var enemy_scenes: Dictionary[String, PackedScene] = {}
# 刷怪点，在场景里放 Marker2D 然后拖进来
@export var spawn_points: Array[Node2D] = []

var _current_spawn_index: int = 0

# ─────────────────────────────────────────
#  波次数据
# ─────────────────────────────────────────
var waves: Array[Dictionary] = [
	{ "spawn_time": 0, "spawn_list": { "tank": 2 } },
	{ "spawn_time": 25.0, "spawn_list": { "tank": 1 } },
	{ "spawn_time": 30.0, "spawn_list": { "tank": 1 } }
]

# ─────────────────────────────────────────
#  状态
# ─────────────────────────────────────────
var current_time: float = 0.0
var current_wave_index: int = 0

# ─────────────────────────────────────────
#  主循环
# ─────────────────────────────────────────
func _process(delta: float) -> void:
	if current_wave_index >= waves.size():
		return

	current_time += delta

	while current_wave_index < waves.size() and current_time >= waves[current_wave_index]["spawn_time"]:
		_spawn_wave(waves[current_wave_index]["spawn_list"])
		current_wave_index += 1

# ─────────────────────────────────────────
#  生成逻辑
# ─────────────────────────────────────────
func _spawn_wave(spawn_list: Dictionary) -> void:
	for enemy_type in spawn_list.keys():
		for i in range(spawn_list[enemy_type]):
			_spawn_single_enemy(enemy_type)

# 记录当前应该在哪个点生成（索引从 0 开始）


func _spawn_single_enemy(enemy_type: String) -> void:
	# 1. 安全检查
	if not enemy_scenes.has(enemy_type) or enemy_scenes[enemy_type] == null:
		push_error("EnemySpawner: 无法生成敌人，未找到类型 -> " + enemy_type)
		return
		
	var scene: PackedScene = enemy_scenes[enemy_type]
	var enemy_instance = scene.instantiate()
	
	# 2. 核心逻辑：按顺序选择生成点
	if spawn_points.size() > 0:
		# 按照计数器的索引选择点位
		# 使用 % spawn_points.size() 是为了防止索引溢出（万一怪比点多，会循环回第一个点）
		var target_point = spawn_points[_current_spawn_index % spawn_points.size()]
		enemy_instance.global_position = target_point.global_position
		
		# 3. 递增计数器，为下一个敌人做准备
		_current_spawn_index += 1
	else:
		# 备选方案：如果没有配置点位，则生成在自身位置
		enemy_instance.global_position = self.global_position
		
	# 将生成的敌人加入场景树
	add_child(enemy_instance)
