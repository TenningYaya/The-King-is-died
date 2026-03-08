extends VBoxContainer

# --- 配置：三次升级所需的具体材料 ---
const UPGRADE_LEVELS_COST = [
	{ "spirit_stone": 10, "q_coin": 5 },
	{ "spirit_stone": 25, "mystic_iron": 10 },
	{ "spirit_stone": 50, "aether_crystal": 5 }
]

@onready var main_hbox = $MainHBox
@onready var level_label = $MainHBox/LevelLabel
@onready var upgrade_button = $MainHBox/UpgradeButton
@onready var requirement_popup = $RequirementPopup
@onready var requirements_list = $RequirementPopup/RequirementsList

var gaze_ctrl: GazeController = null
var resource_manager = null

func _ready():
	gaze_ctrl = get_tree().get_first_node_in_group("gaze_controller") 
	resource_manager = get_tree().get_first_node_in_group("level_manager")
	
	# 连接信号
	main_hbox.mouse_filter = Control.MOUSE_FILTER_STOP
	main_hbox.mouse_entered.connect(_on_mouse_entered)
	main_hbox.mouse_exited.connect(_on_mouse_exited)
	
	if not upgrade_button.pressed.is_connected(_on_upgrade_pressed):
		upgrade_button.pressed.connect(_on_upgrade_pressed)
	
	# --- 关键修改 ---
	# 1. 保持 visible 为 true，这样它永远占据 VBoxContainer 里的 50px 空间
	requirement_popup.visible = true
	# 2. 初始透明度设为 0，实现“隐身但占位”
	requirement_popup.modulate.a = 0.0
	
	_update_display()

func _process(_delta):
	_check_availability()
	# 如果当前提示框处于显示状态，实时刷新文字颜色（红/白）
	if requirement_popup.modulate.a > 0.5:
		_refresh_requirement_colors()

func _get_current_cost():
	if not gaze_ctrl: return null
	# 对应 3, 4, 5 级时的升级消耗索引
	var index = gaze_ctrl.level - 3
	return UPGRADE_LEVELS_COST[index] if (index >= 0 and index < UPGRADE_LEVELS_COST.size()) else null

func _on_mouse_entered():
	var cost = _get_current_cost()
	if cost == null: return
	
	# 1. 清空并重新生成需求列表
	for child in requirements_list.get_children():
		child.queue_free()
	
	for res_id in cost:
		_create_requirement_item(res_id, cost[res_id])
	
	# 2. 渐现动画：淡入
	var tween = create_tween()
	tween.tween_property(requirement_popup, "modulate:a", 1.0, 0.15)

func _on_mouse_exited():
	# 3. 渐现动画：淡出（依然保持占位）
	var tween = create_tween()
	tween.tween_property(requirement_popup, "modulate:a", 0.0, 0.15)

func _create_requirement_item(res_id, amount):
	var container = HBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER # 居中对齐
	
	var tex_rect = TextureRect.new()
	tex_rect.texture = resource_manager.get_resource_icon(res_id)
# --- 修改这里 ---
	# 1. 设定一个固定的正方形大小
	tex_rect.custom_minimum_size = Vector2(20, 20)
	# 2. 允许忽略原始尺寸进行缩放
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# 3. 核心：设置拉伸模式为“保持比例并居中”，防止变扁
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var label = Label.new()
	label.text = str(amount)
	label.name = res_id # 方便后续颜色刷新查找
	
	container.add_child(tex_rect)
	container.add_child(label)
	requirements_list.add_child(container)

# 实时刷新颜色逻辑
func _refresh_requirement_colors():
	var cost = _get_current_cost()
	if not cost: return
	
	for container in requirements_list.get_children():
		var label = container.get_child(1) as Label
		var res_id = label.name
		if resource_manager.get_amount(res_id) < cost[res_id]:
			label.add_theme_color_override("font_color", Color.RED)
		else:
			label.add_theme_color_override("font_color", Color.WHITE)

func _check_availability():
	if not resource_manager or not gaze_ctrl: return
	var cost = _get_current_cost()
	
	if cost == null: # 满级
		upgrade_button.disabled = true
		upgrade_button.self_modulate = Color(0.4, 0.4, 0.4)
		return

	var can_afford = true
	for id in cost:
		if resource_manager.get_amount(id) < cost[id]:
			can_afford = false
			break
	
	upgrade_button.disabled = !can_afford
	# 按钮视觉反馈：没钱变灰
	upgrade_button.self_modulate = Color.WHITE if can_afford else Color(0.4, 0.4, 0.4)

func _on_upgrade_pressed():
	var cost = _get_current_cost()
	if not cost: return
	
	# 扣除资源
	for id in cost:
		resource_manager.consume_resource(id, cost[id])
	
	# 调用队友接口升级
	gaze_ctrl.level += 1
	gaze_ctrl.refresh_level()
	_update_display()

func _update_display():
	if gaze_ctrl:
		level_label.text = str(gaze_ctrl.level) + " | " + str(gaze_ctrl.max_level)
