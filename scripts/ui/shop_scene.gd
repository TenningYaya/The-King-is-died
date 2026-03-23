extends CanvasLayer

# 1. 物品池
var item_pool = [
	["草药园", "res://art_assets/buildings/herb_garden.png", "每秒产出 2 药草", 100],
	["灵泉", "res://art_assets/buildings/elixir_spring.jpg", "每秒产出 2 灵精", 150],
	["灵铁矿", "res://art_assets/buildings/mystic_iron_ore.jpg", "每秒产出 2 灵铁", 120],
	["灵气脉", "res://art_assets/buildings/spirit_vein.jpg", "每秒产出 2 灵气", 200],
	["步兵营", "res://icon.svg", "招募近战单位", 180],
	["弓兵营", "res://icon.svg", "招募远程单位", 220],
	["骑兵营", "res://icon.svg", "招募冲锋单位", 250],
	["法师塔", "res://icon.svg", "招募魔法单位", 300],
	["市场", "res://art_assets/buildings/market.png", "用于资源交换", 150]
]

# 2. 修正后的节点引用
@onready var right_content = $MainContainer/MainHBox/RightContent
@onready var shop_content = $MainContainer

var current_q_money = 500 

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
		buy_btn.text = "购买 " + str(price) + " Q币"
		buy_btn.disabled = (current_q_money < price)
		
		if buy_btn.pressed.is_connected(_on_buy_pressed):
			buy_btn.pressed.disconnect(_on_buy_pressed)
		buy_btn.pressed.connect(_on_buy_pressed.bind(card, price))
	
	if sold_out: sold_out.hide()

func _on_buy_pressed(card, price):
	if current_q_money >= price:
		current_q_money -= price
		print("购买成功！剩余 Q 币：", current_q_money)
		
		var sold_out = card.find_child("SoldOutOverlay", true, false)
		var buy_btn = card.find_child("BuyButton", true, false)
		
		if sold_out: sold_out.show()
		if buy_btn: buy_btn.disabled = true

func _on_hide_button_pressed() -> void:
	shop_content.hide()

func _on_finish_button_pressed() -> void:
	get_tree().paused = false
	self.queue_free()
