extends PanelContainer

@onready var cost_list = $MarginContainer/VBoxContainer

# 预设：如果以后想做更复杂的行，可以把 HBoxContainer 存成一个 PackedScene
# 简单起见，我们直接用代码生成

func update_display(data: BuildingData):
	# 1. 斩断旧因果（清空旧行）
	for child in cost_list.get_children():
		child.queue_free()
	
	if data.cost.is_empty():
		_add_line(null, "free")
		return

	# 2. 遍历数据里的 cost 字典
	for res_index in data.cost.keys():
		var res_name = BuildingData.get_resource_id_name(res_index)
		var amount = data.cost[res_index]
		var icon_path = "res://art_assets/product_resource/%s.webp" % res_name
		
		var tex = null
		if ResourceLoader.exists(icon_path):
			tex = load(icon_path)
			
		_add_line(tex, " x " + str(amount))

func _add_line(icon_tex: Texture2D, text: String):
	var h_box = HBoxContainer.new()
	
	if icon_tex:
		var rect = TextureRect.new()
		rect.texture = icon_tex
		rect.custom_minimum_size = Vector2(50, 50)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h_box.add_child(rect)
	
	var lbl = Label.new()
	lbl.text = text
	h_box.add_child(lbl)
	
	cost_list.add_child(h_box)

#func _process(_delta):
	## 随鼠标潜行，稍微偏移 20 像素避免遮挡
	#global_position = get_global_mouse_position() + Vector2(20, 20)
