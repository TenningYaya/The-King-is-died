class_name EnemySpawner
extends Node2D

# 建议去掉 [String, PackedScene] 类型限制，因为在部分 Godot 4.x 版本中
# 强类型字典可能会导致解析报错，写成 Dictionary 兼容性最好。
@export var enemy_scenes: Dictionary = {}
@export var spawn_points: Array[Node2D] = []
@export var shop_ui: CanvasLayer
@export var reward_ui: CanvasLayer
@export var reward_button: BaseButton


var _current_spawn_index: int = 0
var current_wave_index: int = 0
var timer: float = 0.0

var waves: Array[Dictionary] = [
	{ "spawn_time": 90.0, "spawn_list": { "tank": 1 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 2 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 3 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 1, "mage": 2 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 3, "mage": 3 } },
	{ "spawn_time": 60.0, "spawn_list": { "assassin": 2 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 3, "assassin": 3 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 2, "assassin": 2, "mage": 3 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 2, "assassin": 2, "mage": 3 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 2, "assassin": 2, "mage": 3 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 2, "assassin": 2, "mage": 3 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 2, "assassin": 2, "mage": 3 } },
	# 建议把这里的 spawn_time 改小一点（比如 5.0），这样清完上一波后 Boss 能更快出场
	{ "spawn_time": 60.0, "spawn_list": { "boss": 1 } } 
]

func _ready() -> void:
	add_to_group("save_required")
	
	# --- 读档逻辑 ---
	if GamedataManager.is_loading_save:
		var data = GamedataManager.get_data_for_node(self.name)
		if not data.is_empty():
			current_wave_index = data.get("current_wave_index", 0)
			timer = data.get("timer", 0.0)

	if reward_button:
		reward_button.visible = false
		if not reward_button.pressed.is_connected(_on_reward_button_pressed):
			reward_button.pressed.connect(_on_reward_button_pressed)

func _process(delta: float) -> void:
	if current_wave_index >= waves.size():
		return

	timer += delta
	if timer >= waves[current_wave_index]["spawn_time"]:
		var is_boss_wave = (current_wave_index == waves.size() - 1)
		
		# 1. 生成敌人
		_spawn_wave(waves[current_wave_index]["spawn_list"])
		
		# 2. 如果是普通波次，给奖励；如果是Boss波次，不弹奖励UI以免打断节奏
		if not is_boss_wave:
			_on_wave_completed(current_wave_index)
		else:
			print("最终 Boss 已生成！")
			
		# 3. 推进进度并重置计时器
		current_wave_index += 1
		timer = 0.0

func _on_wave_completed(wave_number: int) -> void:
	ResourceManager.add_currency(10)
	
	if wave_number == 4 or wave_number == 8:
		_open_shop()
	
	if reward_button:
		reward_button.visible = true

func _go_to_win_scene() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scene/system/win.tscn")

func _open_shop() -> void:
	if shop_ui:
		shop_ui.visible = true
		get_tree().paused = true

func _on_reward_button_pressed() -> void:
	if reward_ui:
		if reward_ui.has_method("refresh_rewards"):
			reward_ui.refresh_rewards()
		reward_ui.visible = true
		get_tree().paused = true
		if reward_button:
			reward_button.visible = false

func _spawn_wave(spawn_list: Dictionary) -> void:
	for enemy_type in spawn_list.keys():
		for i in range(spawn_list[enemy_type]):
			_spawn_single_enemy(enemy_type)

func _spawn_single_enemy(enemy_type: String) -> void:
	if not enemy_scenes.has(enemy_type) or enemy_scenes[enemy_type] == null:
		push_error("找不到敌人类型: " + enemy_type + "。请务必检查 Inspector 面板中的 enemy_scenes 字典是否添加了该键名！")
		return

	var enemy_instance = enemy_scenes[enemy_type].instantiate()
	add_child(enemy_instance)

	# --- 核心修复：监听 Boss 死亡 ---
	if enemy_type == "boss":
		enemy_instance.tree_exited.connect(_on_boss_defeated)

	if spawn_points.size() > 0:
		var target_point = spawn_points[_current_spawn_index % spawn_points.size()]
		var offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
		enemy_instance.global_position = target_point.global_position + offset
		_current_spawn_index += 1
	else:
		enemy_instance.global_position = global_position

func _on_boss_defeated() -> void:
	print("Boss 被击败了！准备进入胜利界面！")
	# 使用 call_deferred 可以防止在 Godot 清理物理帧/节点树时直接切场景导致报错崩溃
	call_deferred("_go_to_win_scene")
			
func get_save_data() -> Dictionary:
	return {
		"current_wave_index": current_wave_index,
		"timer": timer
	}
