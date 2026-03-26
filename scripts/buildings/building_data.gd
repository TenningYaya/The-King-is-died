# building_data.gd
extends Resource
class_name BuildingData
# ==============================================================================
# 【配置字段含义说明书】
#
# [视觉配置]
# - icon: 建筑的缩略图
# - preview_color: 可能是测试时用的，现在已经不重要了，可删可不删
#
# [基础配置]
# - building_name: 建筑名，大写开头，如AlchemyLab
# - type: 建筑的功能属性（生产/战斗/市场）。
# - base_scene_path: 建筑场景文件路径，也是只有三种（生产/战斗/市场）
# - cost: 建造此物需消耗的各类资源，
#         注意！！！添加或者修改了键值对后，
#         最好点一下下面的+Add Key/Value Pair，
#         不然最新填写的键值对不会保存
# - sell_value: 建筑蓝图被售卖时，返还给老祖的 Q 币
#
# [生产配置]
# - product_type: 产出的灵物 ID（如："spirit_stone"）。
# - amount_per_cycle: 
#		  对生产建筑和市场来说，是每轮进度条走完后产出的资源数量，一般为1
#		  对战斗建筑来说，是能存储的小兵上限。一般为3。
#		  战斗建筑默认每轮进度条结束只生产一个小兵
# - production_time: 一个生产周期所需时间，即进度条转一圈的时间
# - max_production: 
#		  生产建筑可生产的资源上限，生产为这个值的资源后，建筑自动销毁
#		  当填写0时，此建筑没有可生产资源上限，永不会被系统拆除
#		  对elixir_spring和战斗建筑来说，这个值无效，因此一律填0
# - minion_scene: 战斗建筑生产的unit，需拖入对应scene
#
# [搬迁惩罚配置]
# - move_penalty_multiplier: 移动建筑后，移动惩罚期间建筑生产速度倍率。
# - move_penalty_duration_factor: 
#		  移动惩罚时间等于这个值*一个生产周期所需的时间
#		  penalty_timer = data.production_time * data.move_penalty_duration_factor


#
# 1. amount_per_cycle (单次循环产量/效果):
#    - PRODUCTION (生产): 进度条走满一次，仓库增加该数量的资源。
#    - MARKET (市场): 每次交易卖出的货物基数，或单次换取的灵石数量。
#    - COMBAT (战斗): 每次攻击造成的伤害值，或单次射击消耗的弹药数。
#
# 2. max_production (最大总量上限):
#    - PRODUCTION (生产): 资源点枯竭上限。总产出达到此值后，建筑可能废弃或需充能。
#    - MARKET (市场): 摊位容量上限。当前库存达到此值后，停止进货。
#    - COMBAT (战斗): 建筑耐久度或弹药库总量。
#
# 3. production_time (循环周期/速率):
#    - PRODUCTION/MARKET: 进度条从 0 到 100% 所需的秒数。
#    - COMBAT: 两次攻击之间的间隔时间（攻击冷却）。
#
# 4. product_type (产出物标识):
#    - PRODUCTION: 产出的资源 ID（如 "herb", "elixir"）。
#    - MARKET: 赚取的货币 ID（通常固定为 "spirit_stone"）。
#    - COMBAT: 攻击附带的状态效果 ID 或子弹类型 ID。
# ==============================================================================

# 用于 UI 页签筛选的枚举
enum BuildingType { PRODUCTION, COMBAT, MARKET }
enum ResourceType {
	elixir,
	herb,
	aether_crystal,
	mystic_iron,
	spirit_stone
}

@export_group("视觉配置")
@export var icon: Texture2D # 蓝图图标、Slot 图标、建筑图标共用
@export var preview_color: Color = Color(0, 1, 0, 0.5) # 蓝图虚影预览时的颜色

@export_group("基础配置")
@export var building_name: String = "新建筑"
@export var type: BuildingType = BuildingType.PRODUCTION
@export_file("*.tscn") var base_scene_path: String = "res://Scene/buildings/blueprint.tscn"
@export var cost: Dictionary[ResourceType, int] = {}
@export var sell_value: int = 5

@export_group("生产配置")
@export var product_type: String = "spirit_stone"
@export var amount_per_cycle: int = 1
@export var production_time: float = 2.0
@export var max_production: int = 100
@export var minion_scene: PackedScene 

@export_group("搬迁惩罚配置")
@export var move_penalty_multiplier: float = 0.5
@export var move_penalty_duration_factor: float = 2.0

static func get_resource_id_name(type_index: int) -> String:
	# ResourceType.keys() 会返回 ["elixir", "herb", ...]
	# 使用索引拿到对应的键名，然后转为小写以防万一
	return ResourceType.keys()[type_index].to_lower()

static func get_resource_icon_path(type_index: int) -> String:
	var res_name = get_resource_id_name(type_index)
	# 这里的路径请改为您存放图标的实际文件夹路径
	return "res://art_assets/icons/resources/%s.png" % res_name
