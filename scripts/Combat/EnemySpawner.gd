class_name EnemySpawner
extends Node2D

# ─────────────────────────────────────────
#  配置（在 Inspector 里设置）
# ─────────────────────────────────────────
# key: 敌人类型字符串（如 "tank"），value: 对应场景
@export var enemy_scenes: Dictionary[String, PackedScene] = {}
# 刷怪点，在场景里放 Marker2D 然后拖进来
@export var spawn_points: Array[Node2D] = []

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
			_spawn_single(enemy_type)

func _spawn_single(enemy_type: String) -> void:
	if not enemy_scenes.has(enemy_type) or enemy_scenes[enemy_type] == null:
		push_error("EnemySpawner: 未找到敌人类型 -> " + enemy_type)
		return

	var enemy = enemy_scenes[enemy_type].instantiate()
	get_tree().current_scene.add_child(enemy)

	if spawn_points.size() > 0:
		var offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
		enemy.global_position = spawn_points.pick_random().global_position + offset
	else:
		enemy.global_position = global_position
