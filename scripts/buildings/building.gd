#building.gd
extends Area2D
class_name Building

@export var data: BuildingData # 每个建筑实体都持有一份数据引用
var current_slot: Area2D = null

var current_progress: float = 0.0
var is_active: bool = true
var penalty_timer: float = 0.0
var is_under_penalty: bool = false

var is_moving: bool = false
var original_pos: Vector2

@onready var progress_pie = $UIContainer/ProgressBar

func _ready():
	if data:
		if has_node("Sprite2D") and data.icon:
			$Sprite2D.texture = data.icon
		
		if progress_pie:
			progress_pie.value = 0
			
func _process(delta):
	if not is_active or data == null:
		return
	
	if is_moving:
		# 状态 1：正在挪动中
		global_position = get_global_mouse_position()
		# 挪动时如s果按住 Shift 的逻辑通常由 _input 触发开始，这里负责跟随
	else:
		# 状态 2：正常状态（可能包含惩罚期）
		_update_penalty_timer(delta) # 更新惩罚倒计时
		_tick_production(delta)      # 处理生产/进度逻辑

func _update_penalty_timer(delta):
	if is_under_penalty:
		penalty_timer -= delta
		if penalty_timer <= 0:
			is_under_penalty = false
			print("[%s] 效率恢复正常" % data.building_name)

# 共有机制：进度条旋转
func _tick_production(delta):
	var gaze_node = get_tree().get_first_node_in_group("gaze_controller")
	var is_covered = false
	if gaze_node:
		is_covered = gaze_node.is_position_covered(global_position)
	
	if is_covered:
		var multiplier = data.move_penalty_multiplier if is_under_penalty else 1.0
		current_progress += (delta * multiplier) / data.production_time
		
		if progress_pie:
			progress_pie.value = current_progress * 100
		
		if current_progress >= 1.0:
			current_progress = 0.0
	else:
		pass

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and Input.is_key_pressed(KEY_SHIFT):
				_start_moving()
			elif not event.pressed and is_moving:
				_stop_moving()

func _start_moving():
	is_moving = true
	original_pos = global_position
	modulate.a = 0.5 # 变成半透明虚影
	z_index = 100

func _stop_moving():
	is_moving = false
	modulate.a = 1.0
	z_index = 0
	
	# 检查是否有新地块（利用你之前蓝图里相同的 Group 逻辑）
	var areas = get_overlapping_areas()
	var target_slot = null
	for a in areas:
		if a.is_in_group("slots"):
			# ✅ 使用元数据检测占用，如果没设置过 meta，默认设为 false
			var occupied = a.get_meta("is_occupied", false)
			if not occupied:
				target_slot = a
				break
	
	if target_slot:
		# 释放旧格子
		if current_slot:
			current_slot.set_meta("is_occupied", false)
		
		# 占领新格子
		global_position = target_slot.global_position
		target_slot.set_meta("is_occupied", true)
		current_slot = target_slot
		_on_moved_to_new_slot()
	else:
		global_position = original_pos # 挪动失败回位
		
func set_initial_slot(slot_node: Area2D):
	current_slot = slot_node
	current_slot.set_meta("is_occupied", true)
	global_position = slot_node.global_position
	
func _on_moved_to_new_slot():
	if data:
		# 时间 = 生产周期 * 惩罚因子
		penalty_timer = data.production_time * data.move_penalty_duration_factor
		is_under_penalty = true
		print("[%s] 搬迁完成，当前生产效率：%d%%" % [data.building_name, data.move_penalty_multiplier * 100])

## 获取当前环境下的生产速度修正值
func get_current_speed_multiplier() -> float:
	if is_under_penalty:
		return data.move_penalty_multiplier
	return 1.0
