#gaze_upgrade.gd
extends VBoxContainer

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
@export var custom_font: Font = null

var gaze_ctrl: GazeController = null
var resource_manager = null

func _ready():
	requirement_popup.custom_minimum_size = Vector2(100, 40)
	gaze_ctrl = get_tree().get_first_node_in_group("gaze_controller")
	resource_manager = get_tree().get_first_node_in_group("level_manager")

	main_hbox.mouse_filter = Control.MOUSE_FILTER_STOP
	main_hbox.mouse_entered.connect(_on_mouse_entered)
	main_hbox.mouse_exited.connect(_on_mouse_exited)

	if not upgrade_button.pressed.is_connected(_on_upgrade_pressed):
		upgrade_button.pressed.connect(_on_upgrade_pressed)

	requirement_popup.visible = true
	requirement_popup.modulate.a = 0.0

	_update_display()

func _process(_delta):
	_check_availability()
	if requirement_popup.modulate.a > 0.5:
		_refresh_requirement_colors()

func _get_current_cost():
	if not gaze_ctrl: return null
	var index = gaze_ctrl.level - 3
	return UPGRADE_LEVELS_COST[index] if (index >= 0 and index < UPGRADE_LEVELS_COST.size()) else null

func _get_amount(res_id: String) -> int:
	if res_id == "q_coin":
		return ResourceManager.get_currency()
	return resource_manager.get_amount(res_id)

func _consume(res_id: String, amount: int) -> bool:
	if res_id == "q_coin":
		return ResourceManager.spend_currency(amount)
	return resource_manager.consume_resource(res_id, amount)

func _on_mouse_entered():
	var cost = _get_current_cost()
	if cost == null: return

	# 1. 暴力清理并添加
	for child in requirements_list.get_children():
		child.free() # 比 queue_free 更快，立即释放

	for res_id in cost:
		_create_requirement_item(res_id, cost[res_id])

	# 2. 强行显示并刷新
	requirement_popup.modulate.a = 1.0 # 别用 Tween 了，直接亮
	requirement_popup.show()
	
	# 关键：手动触发一次尺寸更新
	requirement_popup.reset_size() 
	print("Popup尺寸现在是: ", requirement_popup.size) # 看看控制台输出是不是 (0,0)

	
func _on_mouse_exited():
	var tween = create_tween()
	tween.tween_property(requirement_popup, "modulate:a", 0.0, 0.15)

func _create_requirement_item(res_id, amount):
	var container = HBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER

	var tex_rect = TextureRect.new()
	tex_rect.texture = resource_manager.get_resource_icon(res_id)
	tex_rect.custom_minimum_size = Vector2(50, 50)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var label = Label.new()
	label.text = "x " + str(amount)
	label.name = res_id
	label.add_theme_font_size_override("font_size", 30)
	var font_path = "res://fonts/Stacked pixel.ttf"
	var dynamic_font = load(font_path)
	label.add_theme_font_override("font", dynamic_font)
		
	container.add_child(tex_rect)
	container.add_child(label)
	requirements_list.add_child(container)

func _refresh_requirement_colors():
	var cost = _get_current_cost()
	if not cost: return

	for container in requirements_list.get_children():
		var label = container.get_child(1) as Label
		var res_id = label.name
		if _get_amount(res_id) < cost[res_id]:
			label.add_theme_color_override("font_color", Color.RED)
		else:
			label.add_theme_color_override("font_color", Color.WHITE)

func _check_availability():
	if not resource_manager or not gaze_ctrl: return
	var cost = _get_current_cost()

	if cost == null:
		upgrade_button.disabled = true
		upgrade_button.self_modulate = Color(0.4, 0.4, 0.4)
		return

	var can_afford = true
	for id in cost:
		if _get_amount(id) < cost[id]:
			can_afford = false
			break

	upgrade_button.disabled = !can_afford
	upgrade_button.self_modulate = Color.WHITE if can_afford else Color(0.4, 0.4, 0.4)

func _on_upgrade_pressed():
	var cost = _get_current_cost()
	if not cost: return

	for id in cost:
		_consume(id, cost[id])

	gaze_ctrl.level += 1
	gaze_ctrl.refresh_level()
	_update_display()

func _update_display():
	if gaze_ctrl:
		level_label.text = str(gaze_ctrl.level) + " | " + str(gaze_ctrl.max_level)
