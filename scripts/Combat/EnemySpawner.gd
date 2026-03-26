class_name EnemySpawner
extends Node2D

@export var enemy_scenes: Dictionary[String, PackedScene] = {}
@export var spawn_points: Array[Node2D] = []
@export var shop_ui: CanvasLayer
@export var reward_ui: CanvasLayer
@export var reward_button: BaseButton

var _current_spawn_index: int = 0
var current_wave_index: int = 0
var timer: float = 0.0
var waiting_for_next_wave: bool = false
var _debug_timer: float = 0.0

var waves: Array[Dictionary] = [
	{ "spawn_time": 90.0, "spawn_list": { "tank": 1 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 2 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 3 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 1 , "mage":2 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 3 , "mage":3 } },
	{ "spawn_time": 60.0, "spawn_list": { "assassin": 2 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 3 , "assassin":3 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 2 , "assassin":2 , "mage":3 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 2 , "assassin":2 , "mage":3 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 2 , "assassin":2 , "mage":3 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 2 , "assassin":2 , "mage":3 } },
	{ "spawn_time": 60.0, "spawn_list": { "tank": 2 , "assassin":2 , "mage":3 } },
	{ "spawn_time": 60.0, "spawn_list": { "boss": 1 } }
]

func _ready() -> void:
	if reward_button:
		reward_button.visible = false
		if not reward_button.pressed.is_connected(_on_reward_button_pressed):
			reward_button.pressed.connect(_on_reward_button_pressed)

func _process(delta: float) -> void:
	if current_wave_index >= waves.size():
		return

	_debug_timer -= delta
	if _debug_timer <= 0.0:
		_debug_timer = 1.0
		print("wave:%d enemy_count:%d timer:%.1f waiting:%s 子节点列表:%s" % [
			current_wave_index,
			_get_enemy_count(),
			timer,
			waiting_for_next_wave,
			get_children().map(func(c): return c.name)
		])

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
	if reward_button:
		reward_button.visible = true
	else:
		push_error("未找到 reward_button 节点")
	if current_wave_index == 2:
		if shop_ui:
			shop_ui.visible = true
			get_tree().paused = true
		else:
			push_error("未找到 shop_ui 节点")

func _on_reward_button_pressed() -> void:
	if reward_ui:
		if reward_ui.has_method("refresh_rewards"):
			reward_ui.refresh_rewards()
		reward_ui.visible = true
		get_tree().paused = true
		reward_button.visible = false
	else:
		push_error("未找到 reward_ui 节点")

func _get_enemy_count() -> int:
	return get_tree().get_nodes_in_group("active_enemies").size()

func _spawn_wave(spawn_list: Dictionary) -> void:
	for enemy_type in spawn_list.keys():
		for i in range(spawn_list[enemy_type]):
			_spawn_single_enemy(enemy_type)

func _spawn_single_enemy(enemy_type: String) -> void:
	if not enemy_scenes.has(enemy_type) or enemy_scenes[enemy_type] == null:
		return

	var scene: PackedScene = enemy_scenes[enemy_type]
	var enemy_instance = scene.instantiate()
	add_child(enemy_instance)
	enemy_instance.add_to_group("active_enemies")

	if spawn_points.size() > 0:
		var target_point = spawn_points[_current_spawn_index % spawn_points.size()]
		var offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
		enemy_instance.global_position = target_point.global_position + offset
		_current_spawn_index += 1
	else:
		enemy_instance.global_position = global_position
