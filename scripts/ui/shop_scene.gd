extends CanvasLayer

# 1. 物品池
var item_pool = [
	["Herb Garden", "res://art_assets/buildings/final_buildings/Herb Garden.webp", "Produces 2 Herbs per second", 10],
	["Spirit Vein", "res://art_assets/buildings/final_buildings/Spirit Vein.webp", "Produces 2 Spirit Stones per second", 15],
	["Elixir Spring", "res://art_assets/buildings/final_buildings/Elixir Spring.webp", "Produces 2 Elixirs per second", 12],
	["Mystic Iron Ore", "res://art_assets/buildings/final_buildings/Mystic Iron Ore.webp", "Produces 2 Mystic Irons per second", 20],
	["Martial Arena", "res://art_assets/buildings/final_buildings/martial_arena.webp", "Recruit Body Cultivators (Tank)", 18],
	["Sword Monument", "res://art_assets/buildings/final_buildings/sword_monument.webp", "Recruit Sword Cultivators (Assassin)", 22],
	["Origin Pavilion", "res://art_assets/buildings/final_buildings/origin_pavilion.webp", "Recruit Talisman Cultivators (Mage)", 25],
	["Alchemy Lab", "res://art_assets/buildings/final_buildings/alchemy_lab.webp", "Recruit Alchemy Cultivators (Priest)", 30],
	["Market", "res://art_assets/buildings/final_buildings/Market.webp", "Used for resource exchange", 15]
]

# 2. 修正后的节点引用
@onready var right_content = $MainContainer/MainHBox/RightContent
@onready var shop_content = $MainContainer

@export var blueprint_manager: LevelBlueprintManager

func _ready():
	refresh_shop()

func refresh_shop():
	var temp_pool = item_pool.duplicate()
	temp_pool.shuffle()
	var selected = temp_pool.slice(0, 4)
	
	# 这里直接找 RightContent 下的孩子节点 (Option1, 2, 3, 4)
	for i in range(4):
		if i < right_content.get_child_count():
			var card_node = right_content.get_child(i)
			_setup_card(card_node, selected[i])

func _setup_card(card, data):
	# 使用 find_child 自动匹配，不再纠结层级
	var name_lbl = card.find_child("ItemName", true, false)
	var icon_tex = card.find_child("ItemIcon", true, false)
	var desc_lbl = card.find_child("Description", true, false)
	var buy_btn = card.find_child("BuyButton", true, false)
	var sold_out = card.find_child("SoldOutOverlay", true, false)

	if name_lbl: name_lbl.text = data[0]
	if icon_tex: icon_tex.texture = load(data[1])
	if desc_lbl: desc_lbl.text = data[2]
	
	if buy_btn:
		var price = data[3]
		var item_name = data[0] # <--- 提取当前的物品名称
		
		buy_btn.text = "BUY (" + str(price) + " coin)"
		
		# 使用 ResourceManager 获取当前 Q 币来决定按钮是否可用
		var current_coins = ResourceManager.get_currency()
		var is_disabled = (current_coins < price)

		#print(">>> 生成商品卡片: ", data[0])
		#print(">>> 售价: ", price, " | 商店读取到的Q币: ", current_coins)
		#print(">>> 按钮因此被禁用(disabled)? : ", is_disabled)
		
		if buy_btn.pressed.is_connected(_on_buy_pressed):
			buy_btn.pressed.disconnect(_on_buy_pressed)
			
		# 关键修改：通过 bind 把 item_name 一起传给 _on_buy_pressed
		buy_btn.pressed.connect(_on_buy_pressed.bind(card, price, item_name))
	
	if sold_out: sold_out.hide()

func _on_buy_pressed(card, price, item_name):
	# 必须把发放奖励的逻辑放在 if 里面，确保只有扣除 Q 币成功才给奖励
	if ResourceManager.spend_currency(price):
		print("购买成功！剩余 Q 币：", ResourceManager.get_currency())
		
		var sold_out = card.find_child("SoldOutOverlay", true, false)
		var buy_btn = card.find_child("BuyButton", true, false)
		
		if sold_out: sold_out.show()
		if buy_btn: buy_btn.disabled = true
		
		_grant_reward(item_name)
		
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
		print("已发放蓝图奖励: ", item_name, " -> ", res_path)
	else:
		push_error("Blueprint Manager 没有 add_blueprint 方法")

func _on_finish_button_pressed() -> void:
	print("点击了finish按钮")
	get_tree().paused = false
	self.queue_free()
