# producer_market.gd
extends Building
class_name MarketBuilding

@onready var select_button = $UIContainer/SelectButton
@onready var resource_list = $UIContainer/ResourceList
@export var void_icon : Texture2D = null

var current_target_resource: String = "" # 这一轮正在换的
var next_target_resource: String = ""    # 玩家刚刚点的（下一轮生效）

func _ready():
	super._ready() # 运行基类的视觉设置
	
	# 确保即便是在加载出的实例中，也能找到这些节点
	if has_node("UIContainer/ResourceList"):
		resource_list = $UIContainer/ResourceList
		resource_list.hide()
	
	if has_node("UIContainer/SelectButton"):
		select_button = $UIContainer/SelectButton
		# 如果还没连上信号，手动连一下
		if not select_button.pressed.is_connected(_on_select_button_pressed):
			select_button.pressed.connect(_on_select_button_pressed)
	
	_update_main_button_ui()
	
func _process(delta):
	if not is_active or data == null:
		return
	
	if is_moving:
		global_position = get_global_mouse_position()
	else:
		_update_penalty_timer(delta)
		
		# 只有选了资源才跑进度
		if current_target_resource != "":
			_run_market_logic(delta)

func _run_market_logic(delta):
	var gaze_node = get_tree().get_first_node_in_group("gaze_controller")
	var is_covered = gaze_node and gaze_node.is_position_covered(global_position)
	
	if is_covered:
		# --- 周期起点：尝试扣费 ---
		if current_progress == 0.0:
			if not _try_consume_input():
				return # 没钱/没货，进度条卡在 0% 不动
		
		# --- 推进进度 ---
		var multiplier = get_current_speed_multiplier()
		current_progress += (delta * multiplier) / data.production_time
		
		if progress_pie:
			progress_pie.value = current_progress * 100
		
		# --- 周期终点：发放 Spirit Stone ---
		if current_progress >= 1.0:
			current_progress = 0.0
			_on_cycle_finished()

func _try_consume_input() -> bool:
	var manager = get_tree().get_first_node_in_group("level_manager")
	if manager:
		# 使用你定义的 consume_resource 方法
		return manager.consume_resource(current_target_resource, 1)
	return false

func _on_cycle_finished():
	var manager = get_tree().get_first_node_in_group("level_manager")
	if manager:
		# 产出 Spirit Stone
		manager.add_resource("spirit_stone", 1)
		show_production_popup("spirit_stone", 1)
	
	# 重点：旧周期结束，现在更新为玩家选的新资源
	if current_target_resource != next_target_resource:
		current_target_resource = next_target_resource
		_update_main_button_ui()

# --- UI 交互 ---
func _on_select_button_pressed():
	if not resource_list:
		return

	resource_list.visible = !resource_list.visible
	
	if resource_list.visible:
		$UIContainer.z_index = 100
		_build_resource_menu()
		# 强制 UI 刷新布局
		resource_list.force_update_transform()
	else:
		$UIContainer.z_index = 0
		
func _build_resource_menu():
	# 清空旧按钮
	var count = 0
	for child in resource_list.get_children():
		child.queue_free()
		count += 1
	
	# 1. 强制添加测试按钮
	_add_menu_item("NONE", void_icon, "")
	
	# 2. 检查管理器资源
	var manager = get_tree().get_first_node_in_group("level_manager")
	for res_id in manager.current_resources.keys():
		if res_id == "spirit_stone" or res_id == "q_coin":
			continue 
		
		# 暂时移除库存判定，强制显示所有资源进行排查
		var icon = manager.get_resource_icon(res_id)
		_add_menu_item(res_id, icon, res_id)

func _add_menu_item(label: String, icon: Texture2D, res_id: String):
	var btn = Button.new()
	btn.icon = icon
	
	btn.custom_minimum_size = Vector2(40, 40) # 强行限制按钮底座
	btn.expand_icon = true                    # 允许图标缩放
	
	# 在 Button 中，图标对齐通常用这个（防止图标偏离中心）
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	
	btn.clip_contents = true 
	# ------------------
	btn.pressed.connect(func(): _on_resource_picked(res_id))
	resource_list.add_child(btn)
	
func _on_resource_picked(res_id: String):
	next_target_resource = res_id
	# 如果当前没在干活，立刻更新图标
	if current_progress == 0.0:
		current_target_resource = next_target_resource
		_update_main_button_ui()
	resource_list.hide()

func _update_main_button_ui():
	if select_button:
		select_button.custom_minimum_size = Vector2(30, 30) # 保持与下拉菜单一致
		select_button.expand_icon = true
		select_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		select_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		if current_target_resource == "":
			select_button.icon = void_icon
		else:
			var manager = get_tree().get_first_node_in_group("level_manager")
			if manager:
				select_button.icon = manager.get_resource_icon(current_target_resource)
				select_button.text = ""
