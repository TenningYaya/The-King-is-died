# building.gd
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
var is_in_demolish_mode: bool = false

@onready var progress_pie = $UIContainer/ProgressBar
@export var target_display_size: Vector2 = Vector2(110, 110) # 你希望建筑在地图上显示的像素大小
@export var popup_scene: PackedScene = preload("res://Scene/ui/production_popup.tscn")

func _ready():
	add_to_group("buildings")
	input_pickable = true 
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if data:
		_setup_visuals()
		
		if progress_pie:
			progress_pie.value = 0

# 被 DemolishButton 远程调用
func enter_demolish_mode():
	is_in_demolish_mode = true

func exit_demolish_mode():
	is_in_demolish_mode = false
	modulate = Color(1, 1, 1) # 恢复原色

func _on_mouse_entered():
	if is_in_demolish_mode:
		# 高亮显示：比如变蓝或变白发光
		modulate = Color(2.0, 0.5, 0.5)

func _on_mouse_exited():
	modulate = Color(1, 1, 1)
	
func _process(delta):
	if not is_active or data == null:
		return
	
	if is_moving:
		global_position = get_global_mouse_position()
	else:
		_update_penalty_timer(delta)
		_tick_production(delta)

func _update_penalty_timer(delta):
	if is_under_penalty:
		penalty_timer -= delta
		if penalty_timer <= 0:
			is_under_penalty = false
			print("[%s] 效率恢复正常" % data.building_name)

# 共有机制：进度条逻辑
func _tick_production(delta):
	var gaze_node = get_tree().get_first_node_in_group("gaze_controller")
	var is_covered = false
	if gaze_node:
		is_covered = gaze_node.is_position_covered(global_position)
	
	if is_covered:
		var multiplier = get_current_speed_multiplier()
		current_progress += (delta * multiplier) / data.production_time
		
		if progress_pie:
			progress_pie.value = current_progress * 100
		
		if current_progress >= 1.0:
			current_progress = 0.0
			# --- 关键修复：进度满了，调用产出函数 ---
			_on_production_finished() 
	else:
		pass

# 虚函数：由子类（如 ProducerBuilding）重写具体逻辑
func _on_production_finished():
	pass

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and Input.is_key_pressed(KEY_SHIFT):
				_start_moving()
				get_viewport().set_input_as_handled()
			elif not event.pressed and is_moving:
				_stop_moving()
	if is_in_demolish_mode and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_execute_demolish()
			# 阻止点击穿透到地块或背景
			get_viewport().set_input_as_handled()

func _start_moving():
	is_moving = true
	original_pos = global_position
	modulate.a = 0.5
	z_index = 100

func _stop_moving():
	is_moving = false
	modulate.a = 1.0
	z_index = 0
	
	var areas = get_overlapping_areas()
	var target_slot = null
	for a in areas:
		if a.is_in_group("slots"):
			var occupied = a.get_meta("is_occupied", false)
			if not occupied:
				target_slot = a
				break
	
	if target_slot:
		if current_slot:
			current_slot.set_meta("is_occupied", false)
		global_position = target_slot.global_position
		target_slot.set_meta("is_occupied", true)
		current_slot = target_slot
		_on_moved_to_new_slot()
	else:
		global_position = original_pos
		
func set_initial_slot(slot_node: Area2D):
	current_slot = slot_node
	current_slot.set_meta("is_occupied", true)
	global_position = slot_node.global_position
	
func _on_moved_to_new_slot():
	if data:
		penalty_timer = data.production_time * data.move_penalty_duration_factor
		is_under_penalty = true
		print("[%s] 搬迁完成，进入生产惩罚期" % data.building_name)

func get_current_speed_multiplier() -> float:
	if is_under_penalty:
		return data.move_penalty_multiplier
	return 1.0

func _setup_visuals():
	if has_node("Sprite2D") and data.icon:
		var sprite = $Sprite2D
		sprite.texture = data.icon
		
		# --- 核心缩放逻辑 ---
		var tex_size = data.icon.get_size() # 获取原始图片的像素大小
		if tex_size.x > 0 and tex_size.y > 0:
			# 计算缩放比例：目标尺寸 / 原始尺寸
			var scale_factor_x = target_display_size.x / tex_size.x
			var scale_factor_y = target_display_size.y / tex_size.y
			
			# 取最小值进行等比例缩放，防止拉伸变形
			var final_scale = min(scale_factor_x, scale_factor_y)
			sprite.scale = Vector2(final_scale, final_scale)

func _execute_demolish():
	# 1. 特殊逻辑检查：如果是灵力泉 (elixir_spring)
	if data and data.building_name == "ElixirSpring":
		_return_blueprint()
	
	# 2. 清理地块占用状态
	if current_slot:
		current_slot.set_meta("is_occupied", false)
	
	# 3. 退出拆除模式并销毁建筑
	var dem_btn = get_tree().get_first_node_in_group("demolish_button_node")
	if dem_btn:
		dem_btn.reset_mode()
	
	print("建筑已拆除: ", name)
	queue_free()

func _return_blueprint():
	# 找到蓝图管理器并增加一个灵力泉蓝图
	var bp_ui = get_tree().get_first_node_in_group("blueprint_manager")
	if bp_ui and bp_ui.has_method("add_blueprint"):
		bp_ui.add_blueprint(self.data)
		print("已返还灵力泉蓝图")

func show_production_popup(res_id: String, amount: int):
	var manager = get_tree().get_first_node_in_group("level_manager")
	if not manager: return
	
	# 实例化提示 UI
	var popup = popup_scene.instantiate()
	add_child(popup)
	
	# 计算初始位置：建筑图标的正中心
	var sprite_size = $Sprite2D.texture.get_size() * $Sprite2D.scale
	popup.position = Vector2(-popup.size.x / 2, -popup.size.y / 2) # 居中
	
	# 获取图标并启动动画
	var icon_tex = manager.get_resource_icon(res_id)
	# 飘动距离：建筑中心到建筑顶部的距离（y 轴一半）
	var travel_distance = sprite_size.y / 2
	
	popup.start_animation(icon_tex, amount, travel_distance)

func get_save_data() -> Dictionary:
	return {
		"node_name": name,
		"res_path": data.resource_path,
		"pos_x": global_position.x,
		"pos_y": global_position.y,
		"progress": current_progress,
		"is_active": is_active,
		# --- 补全：寿命、惩罚状态、剩余时间 ---
		"total_produced": get("total_produced") if "total_produced" in self else 0,
		"is_under_penalty": is_under_penalty,
		"penalty_timer": penalty_timer,
		# 市场特有配置
		"market_target": get("current_target_resource") if has_method("_run_market_logic") else ""
	}
