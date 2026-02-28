# building_data.gd
extends Resource
class_name BuildingData

# 用于 UI 页签筛选的枚举
enum BuildingType { PRODUCTION, COMBAT }

@export_group("视觉配置")
@export var icon: Texture2D # 蓝图图标、Slot 图标、建筑图标共用
@export var preview_color: Color = Color(0, 1, 0, 0.5) # 蓝图虚影预览时的颜色

@export_group("基础配置")
@export var building_name: String = "新建筑"
@export var type: BuildingType = BuildingType.PRODUCTION
@export_file("*.tscn") var base_scene_path: String = "res://Scene/buildings/blueprint.tscn"
@export var cost: Dictionary = {"Gold": 10}
@export var sell_value: int = 5

@export_group("生产配置")
@export var product_type: String = "小麦"
@export var amount_per_cycle: int = 1
@export var production_time: float = 2.0
@export var max_production: int = 100
@export var minion_scene: PackedScene 

@export_group("搬迁惩罚配置")
@export var move_penalty_multiplier: float = 0.5
@export var move_penalty_duration_factor: float = 2.0
