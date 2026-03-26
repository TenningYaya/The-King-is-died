class_name EnemySpawner
extends Node2D

@export var enemy_scenes: Dictionary[String, PackedScene] = {}
@export var spawn_points: Array[Node2D] = []
@export var shop_ui: CanvasLayer
@export var reward_ui: CanvasLayer     # 挂载了 reward.gd 的奖励界面
@export var reward_button: BaseButton  # 你准备好的奖励按钮 (Button 或 TextureButton)

var _current_spawn_index: int = 0
var current_wave_index: int = 0
var timer: float = 0.0
var waiting_for_next_wave: bool = false

var waves: Array[Dictionary] = [
	{ "spawn_time": 90.0, "spawn_list": { "tank": 1 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 3 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 2 , "mage": 1 } },
	{ "spawn_time": 60.0, "spawn_list": { "assassin": 5 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 3, "assassin": 3 , "mage": 2 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 1, "assassin": 5 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 1, "assassin": 2 , "mage": 1 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 2, "assassin": 2 , "mage": 1 } },
	{ "spawn_time": 60.0, "spawn_list": { "boss": 1 } }
]

func _ready() -> void:
	# 确保按钮初始状态是隐藏的，并连接点击信号
	if reward_button:
		reward_button.visible = false
		if not reward_button.pressed.is_connected(_on_reward_button_pressed):
			reward_button.pressed.connect(_on_reward_button_pressed)

func _process(delta: float) -> void:
	if current_wave_index >= waves.size():
		return

	if _get_enemy_count() == 0:
		if not waiting_for_next_wave and current_wave_index > 0:
			_on_wave_completed()
			waiting_for_next_wave = true
			timer = 0.0 
		
		timer += delta
		
		if timer >= waves[current_wave_index]["spawn_time"]:
			_spawn_wave(waves[current_wave_index]["spawn_list"])
			current_wave_index += 1
			waiting_for_next_wave = false
			timer = 0.0

func _on_wave_completed() -> void:
	ResourceManager.add_currency(10)
	
	# 1. 每一波结束，显示主界面上的奖励按钮
	if reward_button:
		reward_button.visible = true
	else:
		push_error("未找到 reward_button 节点")
	
	# 2. 如果是第二波结束，额外弹出商店界面并暂停
	if current_wave_index == 2:
		if shop_ui:
			shop_ui.visible = true
			get_tree().paused = true # 暂停游戏
		else:
			push_error("未找到 shop_ui 节点")

# 当玩家点击主界面上的奖励按钮时触发
func _on_reward_button_pressed() -> void:
	if reward_ui:
		if reward_ui.has_method("refresh_rewards"):
			reward_ui.refresh_rewards()
		reward_ui.visible = true
		get_tree().paused = true # 打开奖励界面时暂停游戏
		reward_button.visible = false # 领奖界面打开后，隐藏按钮
	else:
		push_error("未找到 reward_ui 节点")

func _get_enemy_count() -> int:
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
