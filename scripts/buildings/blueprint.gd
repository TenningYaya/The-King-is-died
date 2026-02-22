#blueprint.gd
extends Area2D

# 核心修改：蓝图现在持有该建筑的数据配置
@export var data: BuildingData 
# 对应的建筑模板场景（例如 ProducerBuilding.tscn）
@export var building_scene: PackedScene 

var is_dragging = false
var original_position : Vector2
var current_slot = null 

@onready var sprite = $Sprite2D # 假设蓝图也有个显示图片

func setup_blueprint(building_data: BuildingData, scene_to_spawn: PackedScene):
	self.data = building_data
	self.building_scene = scene_to_spawn
	
	# 自动更新外观
	if sprite and data.icon:
		sprite.texture = data.icon
	modulate = data.preview_color # 使用配置的预览颜色
	
func _ready():
	original_position = global_position
	# 信号连接保持不变
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	# 根据数据初始化蓝图外观
	if data:
		# 设置半透明虚影感
		modulate.a = 0.5 
		# 如果你在 BuildingData 里定义了 icon，这里可以同步
		# if data.icon: sprite.texture = data.icon

func _process(_delta):
	if is_dragging:
		global_position = get_global_mouse_position()

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
		else:
			_on_release()

func _on_release():
	is_dragging = false
	if current_slot:
		_start_working()
	else:
		# 放置失败弹回原位
		global_position = original_position

# 建议使用 Group 判定，比 name.begins_with 更稳健
func _on_area_entered(area):
	if area.is_in_group("slots"):
		# ✅ 检查元数据：只有没被占用的地块才会被记录
		if not area.get_meta("is_occupied", false):
			current_slot = area
			
func _on_area_exited(area):
	if area == current_slot:
		current_slot = null

func _start_working():
	if building_scene == null or data == null:
		print("错误：蓝图缺少场景引用或数据配置！")
		return

	# 1. 实例化真正的建筑（通常是层级二或层级三的实例）
	var new_building = building_scene.instantiate()
	
	# 2. 关键：将蓝图的数据传递给生成的建筑实体
	# 这样生成的建筑才知道自己是“麦田”还是“灵药泉”
	new_building.data = self.data 
	
	# 3. 将建筑添加到场景中
	get_parent().add_child(new_building)
	
	# 4. 对齐位置
	new_building.global_position = current_slot.global_position
	
	current_slot.set_meta("is_occupied", true)
	if "current_slot" in new_building:
		new_building.current_slot = current_slot
			
	# 5. 移除蓝图虚影
	queue_free()
