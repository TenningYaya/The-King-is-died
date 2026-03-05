extends Control

# --- 1. 配置数据：在这里定义每一波有哪些怪物 ---
# 每一项的格式：[怪物图片路径, 怪物数量]
var wave_monster_data = {
	"Point1": [
		["res://art_assets/buildings/herb_garden.png", 3],
		["res://art_assets/buildings/spirit_vein.jpg", 2]
	],
	"Point2": [
		["res://art_assets/buildings/mystic_iron_ore.jpg", 5]
	],
	"Point3": [
		["res://art_assets/buildings/elixir_spring.jpg", 4],
		["res://art_assets/buildings/herb_garden.png", 1]
	],
	"PointBoss": [
		["res://icon.svg", 1] # 这里的图片路径请根据你实际的资源修改
	]
}

# --- 2. 定义时间变量 ---
@export var total_time: float = 60.0 # 走完进度条总共需要多少秒
var elapsed_time: float = 0.0

# --- 3. 引用节点 ---
@onready var timer_bar = $TimerBar
@onready var tooltip = $MonsterTooltip
@onready var content_container = $MonsterTooltip/ContentContainer

func _ready():
	# 初始化进度条
	timer_bar.max_value = total_time
	timer_bar.value = 0
	tooltip.hide() # 初始隐藏提示框
	
	# 批量连接四个点的鼠标信号
	# 请确保你的四个点分别叫 Point1, Point2, Point3, PointBoss
	_connect_point_signals("Point1")
	_connect_point_signals("Point2")
	_connect_point_signals("Point3")
	_connect_point_signals("PointBoss")

func _process(delta):
	# 让进度条随着时间自动推进
	if elapsed_time < total_time:
		elapsed_time += delta
		timer_bar.value = elapsed_time

# 连接信号的辅助函数
func _connect_point_signals(point_name: String):
	var point_node = get_node("TimerBar/Markers/" + point_name)
	if point_node:
		point_node.mouse_entered.connect(_on_mouse_entered_point.bind(point_name))
		point_node.mouse_exited.connect(_on_mouse_exited_point)

# --- 4. 鼠标悬停逻辑 ---
func _on_mouse_entered_point(point_id: String):
	# 1. 先清空上一次显示的旧怪物内容
	for child in content_container.get_children():
		child.queue_free()
	
	# 2. 根据数据动态创建每一行（图片 + 数量）
	var monsters = wave_monster_data[point_id]
	for data in monsters:
		var row = HBoxContainer.new() # 创建横向排列的一行
		
		# 创建图片预览
		var img = TextureRect.new()
		img.texture = load(data[0])
		img.custom_minimum_size = Vector2(30, 30) # 怪物图标大小
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# 创建“×几”文字
		var lbl = Label.new()
		lbl.text = " × " + str(data[1])
		
		row.add_child(img)
		row.add_child(lbl)
		content_container.add_child(row)
	
	# 3. 定位提示框的位置（放在当前点下方）
	var point_node = get_node("TimerBar/Markers/" + point_id)
	tooltip.global_position = point_node.global_position + Vector2(-40, 30)
	tooltip.show()

func _on_mouse_exited_point():
	tooltip.hide()
