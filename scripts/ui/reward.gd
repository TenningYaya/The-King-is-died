extends CanvasLayer

# 1. 奖励池
var item_pool = [
	["仙草圃", "res://art_assets/buildings/herb_garden.png", "每秒产出 2 药草"],
	["灵脉", "res://art_assets/buildings/spirit_vein.jpg", "每秒产出 2 灵精"],
	["不老泉", "res://art_assets/buildings/elixir_spring.jpg", "每秒产出 2 灵铁"],
	["玄铁矿", "res://art_assets/buildings/mystic_iron_ore.jpg", "每秒产出 2 灵气"],
	["演武台", "res://art_assets/buildings/martial_arena.jpg", "招募近战单位"],
	["万剑碑", "res://art_assets/buildings/sword_monument.jpg", "招募远程单位"],
	["抱元阁", "res://art_assets/buildings/origin_pavilion.png", "招募AOE"],
	["炼丹房", "res://art_assets/buildings/alchemy_lab.jpg", "招募奶"],
	["市场", "res://art_assets/buildings/market.png", "用于资源交换"]
]

@onready var right_content = $MainContainer/MainHBox/RightContent
@onready var reward_content = $MainContainer

@export var blueprint_manager: LevelBlueprintManager

func _ready():
	refresh_rewards()

func refresh_rewards():
	var temp_pool = item_pool.duplicate()
	temp_pool.shuffle()
	var selected = temp_pool.slice(0, 4)

	for i in range(4):
		if i < right_content.get_child_count():
			var card_node = right_content.get_child(i)
			_setup_card(card_node, selected[i])

func _setup_card(card, data):
	var name_lbl = card.find_child("ItemName", true, false)
	var icon_tex = card.find_child("ItemIcon", true, false)
	var desc_lbl = card.find_child("Description", true, false)
	var select_btn = card.find_child("ChoseButton", true, false)
	var sold_out = card.find_child("SoldOutOverlay", true, false)

	if name_lbl:
		name_lbl.text = data[0]

	if icon_tex:
		icon_tex.texture = load(data[1])

	if desc_lbl:
		desc_lbl.text = data[2]

	if select_btn:
		select_btn.text = "选择"
		
		if select_btn.pressed.is_connected(_on_select_pressed):
			select_btn.pressed.disconnect(_on_select_pressed)
		select_btn.pressed.connect(_on_select_pressed.bind(data))

	if sold_out:
		sold_out.hide()

func _on_select_pressed(data):
	var item_name = data[0]

	print("玩家选择了奖励：", item_name)
	_grant_reward(item_name)
	_close_reward_ui()

func _grant_reward(item_name: String) -> void:
	var reward_map := {
		"仙草圃": "res://resources/herb_garden.tres",
		"灵脉": "res://resources/spirit_vein.tres",
		"不老泉": "res://resources/elixir_spring.tres",
		"玄铁矿": "res://resources/mystic_iron_ore.tres",
		"演武台": "res://resources/martial_arena.tres",
		"万剑碑": "res://resources/sword_monument.tres",
		"抱元阁": "res://resources/origin_pavilion.tres",
		"炼丹房": "res://resources/alchemy_lab.tres",
		"市场": "res://resources/market.tres"
	}

	if not reward_map.has(item_name):
		push_error("奖励映射表里找不到这个物品: " + item_name)
		return

	var res_path: String = reward_map[item_name]

	if not ResourceLoader.exists(res_path):
		push_error("奖励资源不存在: " + res_path)
		return

	var building_data = load(res_path) as BuildingData
	if building_data == null:
		push_error("奖励资源加载失败，或不是 BuildingData: " + res_path)
		return
	if blueprint_manager == null:
		# 如果你还没加 group，就用固定路径找
		blueprint_manager = get_node_or_null("/root/Game/BlueprintUI")

	if blueprint_manager == null:
		push_error("找不到 Blueprint Manager，无法发放奖励")
		return

	if blueprint_manager.has_method("add_blueprint"):
		blueprint_manager.add_blueprint(building_data)
		print("已发放蓝图奖励: ", item_name, " -> ", res_path)
	else:
		push_error("Blueprint Manager 没有 add_blueprint 方法")
	
func _close_reward_ui() -> void:
	print("点击了finish按钮")
	self.visible = false
	get_tree().paused = false
