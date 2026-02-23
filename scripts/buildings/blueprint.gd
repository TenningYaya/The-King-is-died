# blueprint.gd
extends Area2D

var data: BuildingData 
var building_scene: PackedScene 
var is_dragging: bool = false 
var current_slot: Area2D = null 

@onready var sprite: Sprite2D = $Sprite2D

func setup_blueprint(building_data: BuildingData):
	self.data = building_data
	if data.base_scene_path != "":
		self.building_scene = load(data.base_scene_path)
	
	if sprite and data.icon:
		sprite.texture = data.icon
	
	# 视觉：保持原色，仅设置透明度
	modulate = Color(1, 1, 1, 0.7) 

func _ready():
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _process(_delta):
	if is_dragging:
		# 实时跟随鼠标
		global_position = get_global_mouse_position()
		
		# 放置合法性视觉反馈
		if current_slot == null:
			modulate = Color(1, 0.3, 0.3, 0.7) # 红色遮罩表示不能放
		else:
			modulate = Color(1, 1, 1, 0.7) # 原色表示可以放

func _input(event):
	if is_dragging and event is InputEventMouseButton:
		# 只要监听到左键松开（not event.pressed）
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			print("监听到全局松手！")
			_on_release()
			
func _on_release():
	is_dragging = false
	if current_slot:
		_start_working()
	else:
		# 不能放置：直接消失，由于没调用 consume_blueprint，库存不会减
		print("放置无效，蓝图已回退")
		queue_free()

func _start_working():
	if building_scene == null or data == null:
		print("错误：蓝图缺失数据！")
		queue_free()
		return

	# 1. 实例化真实的建筑（如 Production.tscn）
	var new_building = building_scene.instantiate()
	
	# 2. 核心修复：注入数据！
	# 这一步必须在 add_child 之前，这样建筑的 _ready() 运行时间才能读取到数据并启动进度条
	if "data" in new_building:
		new_building.data = self.data 
		print("数据注入成功：", data.building_name, " 生产周期：", data.production_time)
	
	# 3. 将建筑添加到世界层（Game 节点）
	get_parent().add_child(new_building)
	new_building.global_position = current_slot.global_position
	
	# 4. 锁定地块并传递格子引用
	current_slot.set_meta("is_occupied", true)
	if "current_slot" in new_building:
		new_building.current_slot = current_slot
			
	# 5. 扣除 UI 蓝图数量
	var bp_ui = get_node_or_null("/root/Game/BlueprintUI")
	if bp_ui and bp_ui.has_method("consume_blueprint"):
		bp_ui.consume_blueprint(self.data)
			
	queue_free()

func _on_area_entered(area):
	if area.is_in_group("slots") and not area.get_meta("is_occupied", false):
		current_slot = area

func _on_area_exited(area):
	if area == current_slot:
		current_slot = null
