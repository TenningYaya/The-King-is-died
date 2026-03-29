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

	# 防止超出右边和下边
	var px := mouse.x + offset.x
	var py := mouse.y + offset.y
	if px + s.x > screen.x:
		px = mouse.x - s.x - offset.x
	if py + s.y > screen.y:
		py = mouse.y - s.y - offset.y

	global_position = Vector2(px, py)

func update_display(data: BuildingData):
	for child in cost_list.get_children():
		child.queue_free()

	if data.cost.is_empty():
		_add_line(null, "free")
	else:
		for res_index in data.cost.keys():
			var res_name = BuildingData.get_resource_id_name(res_index)
			var amount = data.cost[res_index]
			var icon_path = "res://art_assets/product_resource/%s.webp" % res_name
			var tex = null
			if ResourceLoader.exists(icon_path):
				tex = load(icon_path)
			_add_line(tex, " x " + str(amount))

	# 显示描述
	if data.description != "":
		var desc_lbl = Label.new()
		desc_lbl.text = data.description
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_lbl.custom_minimum_size = Vector2(200, 0)
		desc_lbl.add_theme_font_size_override("font_size", 18)
		desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		desc_lbl.add_theme_font_override("font", load("res://fonts/Stacked pixel.ttf"))
		cost_list.add_child(desc_lbl)

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
