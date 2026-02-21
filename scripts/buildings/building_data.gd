#building_data.gd
extends Resource
class_name BuildingData

@export_group("视觉配置")
@export var icon: Texture2D # 蓝图和建筑共用的图标
@export var preview_color: Color = Color(0, 1, 0, 0.5) # 蓝图预览时的颜色

@export_group("基础配置")
@export var building_name: String = "新建筑"
@export var cost: Dictionary = {"Gold": 10}
@export var sell_value: int = 5

@export_group("生产配置")
@export var product_type: String = "小麦"
@export var amount_per_cycle: int = 1
@export var production_time: float = 2.0
@export var max_production: int = 100

@export_group("搬迁惩罚配置")
@export var move_penalty_multiplier: float = 0.5
@export var move_penalty_duration_factor: float = 2.0
