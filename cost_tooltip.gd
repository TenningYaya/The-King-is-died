extends PanelContainer

@onready var cost_list = $MarginContainer/VBoxContainer

func _ready():
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta):
	if not visible:
		return
	var mouse := get_global_mouse_position()
	var offset := Vector2(20, 20)
	var screen := get_viewport_rect().size
	var s := size

	var px := mouse.x + offset.x
	var py := mouse.y + offset.y
	if px + s.x > screen.x:
		px = mouse.x - s.x - offset.x
	if py + s.y > screen.y:
		py = mouse.y - s.y - offset.y

	global_position = Vector2(px, py)

func update_display(data: BuildingData):
	# 1. 清空旧内容
	for child in cost_list.get_children():
		child.queue_free()

	# 2. 消耗部分 (COST)
	if not data.cost.is_empty():
		var head_lbl = Label.new()
		head_lbl.text = "COST"
		head_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		head_lbl.add_theme_font_size_override("font_size", 24)
		head_lbl.add_theme_color_override("font_color", Color(1, 0.4, 0.4)) # 淡红
		head_lbl.add_theme_font_override("font", load("res://fonts/Stacked pixel.ttf"))
		cost_list.add_child(head_lbl)
		
		for res_index in data.cost.keys():
			var res_name = BuildingData.get_resource_id_name(res_index)
			var amount = data.cost[res_index]
			var icon_path = "res://art_assets/product_resource/%s.webp" % res_name
			var tex = load(icon_path) if ResourceLoader.exists(icon_path) else null
			_add_line(tex, " x " + str(amount))
	else:
		_add_line(null, "free")

	# 3. 产出部分 (PRODUCE)
	if data.description != "" or data.description_icon != null:
		var spacer = Control.new()
		spacer.custom_minimum_size.y = 8
		cost_list.add_child(spacer)

		var prod_head = Label.new()
		prod_head.text = "PRODUCE"
		prod_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prod_head.add_theme_font_size_override("font_size", 24)
		prod_head.add_theme_color_override("font_color", Color(0.4, 1, 0.4)) # 淡绿
		prod_head.add_theme_font_override("font", load("res://fonts/Stacked pixel.ttf"))
		cost_list.add_child(prod_head)

		var prod_row = HBoxContainer.new()
		prod_row.alignment = BoxContainer.ALIGNMENT_CENTER

		if data.description_icon != null:
			var rect = TextureRect.new()
			rect.texture = data.description_icon
			rect.custom_minimum_size = Vector2(40, 40) # 统一尺寸
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			prod_row.add_child(rect)

		if data.description != "":
			var prod_lbl = Label.new()
			prod_lbl.text = data.description
			prod_lbl.add_theme_font_size_override("font_size", 24)
			prod_lbl.add_theme_color_override("font_color", Color.WHITE)
			prod_lbl.add_theme_font_override("font", load("res://fonts/Stacked pixel.ttf"))
			prod_row.add_child(prod_lbl)
		
		cost_list.add_child(prod_row)

# --- 核心修复：确保这个函数存在 ---
func _add_line(icon_tex: Texture2D, text: String):
	var h_box = HBoxContainer.new()
	h_box.alignment = BoxContainer.ALIGNMENT_CENTER

	if icon_tex:
		var rect = TextureRect.new()
		rect.texture = icon_tex
		rect.custom_minimum_size = Vector2(40, 40)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h_box.add_child(rect)

	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_font_override("font", load("res://fonts/Stacked pixel.ttf"))
	h_box.add_child(lbl)
	cost_list.add_child(h_box)
