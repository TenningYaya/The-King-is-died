extends CanvasLayer

# 1. 物品池
var item_pool = [
	["Herb Garden", "res://art_assets/buildings/final_buildings/Herb Garden.webp", "Produces 2 Herbs per second", 100],
	["Spirit Vein", "res://art_assets/buildings/final_buildings/Spirit Vein.webp", "Produces 2 Spirit Stones per second", 150],
	["Elixir Spring", "res://art_assets/buildings/final_buildings/Elixir Spring.webp", "Produces 2 Elixirs per second", 120],
	["Mystic Iron Ore", "res://art_assets/buildings/final_buildings/Mystic Iron Ore.webp", "Produces 2 Mystic Irons per second", 200],
	["Martial Arena", "res://art_assets/buildings/final_buildings/martial_arena.webp", "Recruit Body Cultivators (Tank)", 180],
	["Sword Monument", "res://art_assets/buildings/final_buildings/sword_monument.webp", "Recruit Sword Cultivators (Assassin)", 220],
	["Origin Pavilion", "res://art_assets/buildings/final_buildings/origin_pavilion.webp", "Recruit Talisman Cultivators (Mage)", 250],
	["Alchemy Lab", "res://art_assets/buildings/final_buildings/alchemy_lab.webp", "Recruit Alchemy Cultivators (Priest)", 300],
	["Market", "res://art_assets/buildings/final_buildings/Market.webp", "Used for resource exchange", 150]
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
		buy_btn.text = "BUY (" + str(price) + " coin)"
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


func _on_finish_button_pressed() -> void:
	print("点击了finish按钮")
	get_tree().paused = false
	self.queue_free()
