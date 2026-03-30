# building.gd
extends Area2D
class_name Building

@export var data: BuildingData
var current_slot: Area2D = null
var original_pos: Vector2

var current_progress: float = 0.0
var penalty_timer: float = 0.0

var is_active: bool = true
var is_under_penalty: bool = false
var is_moving: bool = false
var is_in_demolish_mode: bool = false

@onready var progress_pie = $UIContainer/ProgressBar
@export var target_display_size: Vector2 = Vector2(110, 110)
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

func enter_demolish_mode():
	is_in_demolish_mode = true
	print(name, " 进入状态 is_in_demolish_mode 的状态是: ", is_in_demolish_mode)

func exit_demolish_mode():
	is_in_demolish_mode = false
	modulate = Color(1, 1, 1)

func _on_mouse_entered():
	if is_in_demolish_mode:
		modulate = Color(1.0, 0.5, 0.5)

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

func _tick_production(delta):
	var gaze_node = get_tree().get_first_node_in_group("gaze_controller")
	var is_covered = false
	if gaze_node:
		is_covered = gaze_node.is_position_covered(global_position)

	if is_covered:
		# 读取资源速度加成
		var speed_bonus: float = 1.0 + UpgradeManager.get_percent("resource_speed_1") + UpgradeManager.get_percent("resource_speed_2")
		var multiplier = get_current_speed_multiplier() * speed_bonus
		current_progress += (delta * multiplier) / data.production_time

		if progress_pie:
			progress_pie.value = current_progress * 100

		if current_progress >= 1.0:
			current_progress = 0.0
			_on_production_finished()

func _on_production_finished():
	pass

func _input(event):
	# 1. 只有在左键按下时才处理
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		
		# --- 情况 A：拆除模式（强行矩形区域扫描） ---
		if is_in_demolish_mode:
			var mouse_pos = get_global_mouse_position()
			
			# 计算鼠标与建筑中心的偏移量
			var diff = (mouse_pos - global_position).abs()
			
			# 判定：如果 X 和 Y 的偏移都在 60 像素以内（总边长 120）
			if diff.x <= 60.0 and diff.y <= 60.0:
				print("【正方形捕获】强制命中，执行爆破: ", name)
				_execute_demolish()
				# 斩断信号传播
				get_viewport().set_input_as_handled()
				return

# --- 情况 B：正常/搬迁模式（依赖物理碰撞） ---
# 只有在非拆除模式下，才走这个精准物理判定
func _input_event(_viewport, event, _shape_idx):
	if is_in_demolish_mode: return # 拆除逻辑已在 _input 处理，这里直接无视

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and Input.is_key_pressed(KEY_SHIFT):
			_start_moving()
			get_viewport().set_input_as_handled()
		elif not event.pressed and is_moving:
			_stop_moving()
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

func get_current_speed_multiplier() -> float:
	if is_under_penalty:
		return data.move_penalty_multiplier
	return 1.0

func _setup_visuals():
	if has_node("Sprite2D") and data.icon:
		var sprite = $Sprite2D
		sprite.texture = data.icon
		var tex_size = data.icon.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			var scale_factor_x = target_display_size.x / tex_size.x
			var scale_factor_y = target_display_size.y / tex_size.y
			var final_scale = min(scale_factor_x, scale_factor_y)
			sprite.scale = Vector2(final_scale, final_scale)

func _execute_demolish():
	if data and data.building_name == "ElixirSpring":
		_return_blueprint()
	if current_slot:
		current_slot.set_meta("is_occupied", false)
	var dem_btn = get_tree().get_first_node_in_group("demolish_button_node")
	if dem_btn:
		dem_btn.reset_mode()
	queue_free()

func _return_blueprint():
	var bp_ui = get_tree().get_first_node_in_group("blueprint_manager")
	if bp_ui and bp_ui.has_method("add_blueprint"):
		bp_ui.add_blueprint(self.data)

func show_production_popup(res_id: String, amount: int):
	var manager = get_tree().get_first_node_in_group("level_manager")
	if not manager: return
	var popup = popup_scene.instantiate()
	add_child(popup)
	var sprite_size = $Sprite2D.texture.get_size() * $Sprite2D.scale
	popup.position = Vector2(-popup.size.x / 2, -popup.size.y / 2)
	var icon_tex = manager.get_resource_icon(res_id)
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
		"total_produced": get("total_produced") if "total_produced" in self else 0,
		"is_under_penalty": is_under_penalty,
		"penalty_timer": penalty_timer,
		"market_target": get("current_target_resource") if has_method("_run_market_logic") else ""
	}
