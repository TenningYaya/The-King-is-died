class_name EnemySpawner
extends Node2D

@export var enemy_scenes: Dictionary[String, PackedScene] = {}
@export var spawn_points: Array[Node2D] = []

var _current_spawn_index: int = 0
var current_wave_index: int = 0
var timer: float = 0.0
var waiting_for_next_wave: bool = false

# 修改波次数据：spawn_time 现在代表“前一波清空后等待的时间”
var waves: Array[Dictionary] = [
	{ "spawn_time": 20.0, "spawn_list": { "tank": 2 } },
	{ "spawn_time": 10.0, "spawn_list": { "tank": 1 } },
	{ "spawn_time": 10.0, "spawn_list": { "tank": 3 } }
]

func _process(delta: float) -> void:
	if current_wave_index >= waves.size():
		return

	# 核心逻辑：如果场上没怪了，开始倒计时
	if _get_enemy_count() == 0:
		if not waiting_for_next_wave and current_wave_index > 0:
			# 刚刚清空完一波，发放奖励
			_on_wave_completed()
			waiting_for_next_wave = true
			timer = 0.0 # 重置计时器开始等待下波间隔
		
		timer += delta
		
		# 如果达到了配置的等待时间
		if timer >= waves[current_wave_index]["spawn_time"]:
			_spawn_wave(waves[current_wave_index]["spawn_list"])
			current_wave_index += 1
			waiting_for_next_wave = false
			timer = 0.0

# 发放奖励
func _on_wave_completed() -> void:
	ResourceManager.add_currency(10)
	print("波次完成！获得10特殊货币。当前：", ResourceManager.special_currency)

# 获取当前存活敌人数量
func _get_enemy_count() -> int:
	# 假设你的敌人都在特定的 Group 里，或者直接统计子节点
	# 如果你的敌人生成后是 add_child(enemy_instance)，可以用下面这行：
	return get_child_count() 

func _spawn_wave(spawn_list: Dictionary) -> void:
	for enemy_type in spawn_list.keys():
		for i in range(spawn_list[enemy_type]):
			_spawn_single_enemy(enemy_type)

func _spawn_single_enemy(enemy_type: String) -> void:
	if not enemy_scenes.has(enemy_type) or enemy_scenes[enemy_type] == null:
		return
		
	var scene: PackedScene = enemy_scenes[enemy_type]
	var enemy_instance = scene.instantiate()
	
	if spawn_points.size() > 0:
		var target_point = spawn_points[_current_spawn_index % spawn_points.size()]
		enemy_instance.global_position = target_point.global_position
		_current_spawn_index += 1
	else:
		enemy_instance.global_position = self.global_position
		
	add_child(enemy_instance)
