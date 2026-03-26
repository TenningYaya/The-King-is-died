extends PanelContainer

@onready var cost_list = $MarginContainer/VBoxContainer

# 预设：如果以后想做更复杂的行，可以把 HBoxContainer 存成一个 PackedScene
# 简单起见，我们直接用代码生成

func _ready():
	# 1. 初始彻底隐藏
	hide()
	# 3. 确保它不会拦截开局的点击
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
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
	h_box.alignment = BoxContainer.ALIGNMENT_CENTER # 让图标和文字对齐更整齐
	
	if icon_tex:
		var rect = TextureRect.new()
		rect.texture = icon_tex
		rect.custom_minimum_size = Vector2(40, 40) # 稍微调小一点点更精致
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h_box.add_child(rect)
	
	var lbl = Label.new()
	lbl.text = text
	
	# --- 核心改动：注入样式 ---
	# 1. 修改字号 (Godot 4 语法)
	lbl.add_theme_font_size_override("font_size", 24) 
	# 2. 修改颜色 (可选)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	# 3. 如果您有自定义字体文件 (.ttf / .otf)
	lbl.add_theme_font_override("font", load("res://fonts/Stacked pixel.ttf"))
	
	h_box.add_child(lbl)
	cost_list.add_child(h_box)

#func _process(_delta):
	## 随鼠标潜行，稍微偏移 20 像素避免遮挡
	#global_position = get_global_mouse_position() + Vector2(20, 20)
