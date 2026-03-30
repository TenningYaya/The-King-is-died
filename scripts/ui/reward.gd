#reward.gd
extends CanvasLayer

# 1. 奖励池
var item_pool = [
	["Herb Garden", "res://art_assets/buildings/final_buildings/Herb Garden.webp", "Produces 1 Herbs per second"],
	["Spirit Vein", "res://art_assets/buildings/final_buildings/Spirit Vein.webp", "Produces 1 Spirit Stones per second"],
	["Elixir Spring", "res://art_assets/buildings/final_buildings/Elixir Spring.webp", "Produces 1 Elixirs per second"],
	["Mystic Iron Ore", "res://art_assets/buildings/final_buildings/Mystic Iron Ore.webp", "Produces 1 Mystic Irons per second"],
	["Martial Arena", "res://art_assets/buildings/final_buildings/martial_arena.webp", "Recruit Body Cultivators"],
	["Sword Monument", "res://art_assets/buildings/final_buildings/sword_monument.webp", "Recruit Sword Cultivators"],
	["Origin Pavilion", "res://art_assets/buildings/final_buildings/origin_pavilion.webp", "Recruit Talisman Cultivators"],
	["Alchemy Lab", "res://art_assets/buildings/final_buildings/alchemy_lab.webp", "Recruit Alchemy Cultivators"],
	["Market", "res://art_assets/buildings/final_buildings/Market.webp", "Used for resource exchange"]
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
		select_btn.text = "Chose"
		
		if select_btn.pressed.is_connected(_on_select_pressed):
			select_btn.pressed.disconnect(_on_select_pressed)
		select_btn.pressed.connect(_on_select_pressed.bind(data))

	if sold_out:
		sold_out.hide()

func _on_select_pressed(data):
	var item_name = data[0]

	_grant_reward(item_name)
	_close_reward_ui()

func _grant_reward(item_name: String) -> void:
	# 映射表同步改为英文 Key
	var reward_map := {
		"Herb Garden": "res://resources/herb_garden.tres",
		"Spirit Vein": "res://resources/spirit_vein.tres",
		"Elixir Spring": "res://resources/elixir_spring.tres",
		"Mystic Iron Ore": "res://resources/mystic_iron_ore.tres",
		"Martial Arena": "res://resources/martial_arena.tres",
		"Sword Monument": "res://resources/sword_monument.tres",
		"Origin Pavilion": "res://resources/origin_pavilion.tres",
		"Alchemy Lab": "res://resources/alchemy_lab.tres",
		"Market": "res://resources/market.tres"
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
	else:
		push_error("Blueprint Manager 没有 add_blueprint 方法")
	
func _close_reward_ui() -> void:
	self.visible = false
	get_tree().paused = false
	
	# --- 核心修复：强制重置所有交互状态 ---
	# 1. 重置 Gaze
	var gaze = get_tree().get_first_node_in_group("gaze_controller")
	if gaze and gaze.has_method("force_reset_interaction"):
		gaze.force_reset_interaction()
	
	# 2. 重置所有建筑（通过组）
	# 假设你的建筑都在 "structures" 组
	for building in get_tree().get_nodes_in_group("buildings"):
		if building.has_method("force_reset_interaction"):
			building.force_reset_interaction()
	
	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner:
		focus_owner.release_focus()
		
	print("交互状态已强制重置")
