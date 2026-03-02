extends CanvasLayer

# 1. 配置数据：这里定义每一波的怪物
# 格式：点名字: [[图片路径, 数量], [图片路径, 数量]]
var wave_info = {
	"Point1": [
		["res://art_assets/buildings/herb_garden.png", 3], 
		["res://art_assets/buildings/elixir_spring.jpg", 2]
	],
	"Point2": [
		["res://art_assets/buildings/spirit_vein.jpg", 5]
	],
	"Point3": [
		["res://art_assets/buildings/mystic_iron_ore.jpg", 4],
		["res://art_assets/buildings/herb_garden.png", 2]
	],
	"PointBoss": [
		["res://icon.svg", 1] # 假设这是Boss
	]
}

@export var total_time: float = 100.0 # 走完进度条需要的秒数
var elapsed_time: float = 0.0

@onready var timer_bar = $RoadmapContainer/TimerBar
@onready var tooltip = $MonsterTooltip
@onready var monster_list = $MonsterTooltip/VBoxContainer

func _ready():
	timer_bar.max_value = total_time
	timer_bar.value = 0
	tooltip.hide()
	
	# 为4个点绑定鼠标事件
	for point_name in wave_info.keys():
		var btn = get_node("RoadmapContainer/TimerBar/Markers/" + point_name)
		if btn:
			# 连接鼠标进入和退出信号
			btn.mouse_entered.connect(_show_tooltip.bind(point_name))
			btn.mouse_exited.connect(_hide_tooltip)

func _process(delta):
	if elapsed_time < total_time:
		elapsed_time += delta
		timer_bar.value = elapsed_time

# --- 核心：动态生成提示框内容 ---
func _show_tooltip(point_id):
	# 1. 清空旧内容
	for child in monster_list.get_children():
		child.queue_free()
	
	# 2. 根据数据生成新行
	var data = wave_info[point_id]
	for item in data:
		var row = HBoxContainer.new() # 创建一行
		
		# 创建怪物图片
		var img = TextureRect.new()
		img.texture = load(item[0])
		img.custom_minimum_size = Vector2(30, 30)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# 创建 "x 数量" 文字
		var lbl = Label.new()
		lbl.text = " × " + str(item[1])
		
		row.add_child(img)
		row.add_child(lbl)
		monster_list.add_child(row)
	
	# 3. 设置方框位置并显示
	var btn = get_node("RoadmapContainer/TimerBar/Markers/" + point_id)
	tooltip.global_position = btn.global_position + Vector2(-50, 40) # 显示在点下方
	tooltip.show()

func _hide_tooltip():
	tooltip.hide()
