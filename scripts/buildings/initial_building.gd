# initial_building.gd
class_name InitialBuilding
extends Node

@export_category("References")
# 只有管理器本身还需要在 Inspector 里指定（或者你也可以用代码 get_node 获取）
@export var blueprint_manager: LevelBlueprintManager

# --- 请在这里把路径替换成你项目里真实的 .tres 文件路径 ---
const ELIXIR_SPRING_PATH = "res://resources/elixir_spring.tres"
const HERB_GARDEN_PATH = "res://resources/herb_garden.tres"
const MYSTIC_IRON_ORE_PATH = "res://resources/mystic_iron_ore.tres"
const MARTIAL_ARENA_PATH = "res://resources/martial_arena.tres"
const MARKET_PATH = "res://resources/market.tres"

func _ready() -> void:
	# 如果是从存档加载，不要发放初始建筑
	if GamedataManager.is_loading_save:
		return
		
	# 等待所有节点准备完毕后再发放
	call_deferred("_give_initial_buildings")

func _give_initial_buildings() -> void:
	if not blueprint_manager:
		push_error("[InitialBuilding] 错误：未绑定 LevelBlueprintManager 节点！")
		return
		
	# 通过代码动态加载资源
	var elixir_spring = load(ELIXIR_SPRING_PATH) as BuildingData
	var herb_garden = load(HERB_GARDEN_PATH) as BuildingData
	var mystic_iron_ore = load(MYSTIC_IRON_ORE_PATH) as BuildingData
	var martial_arena = load(MARTIAL_ARENA_PATH) as BuildingData
	var market = load(MARKET_PATH) as BuildingData
	
	# 检查路径是否写对，文件是否成功加载
	if not elixir_spring or not herb_garden or not mystic_iron_ore or not market or not martial_arena:
		push_error("[InitialBuilding] 错误：有建筑资源未能加载，请检查上方的 res:// 路径是否正确！")
		return
		
	# 给3个 elixir_spring
	for i in range(3):
		blueprint_manager.add_blueprint(elixir_spring)
		
	# 给3个 herb_garden
	for i in range(3):
		blueprint_manager.add_blueprint(herb_garden)
		
	# 给3个 mystic_iron_ore
	for i in range(3):
		blueprint_manager.add_blueprint(mystic_iron_ore)
		
	# 给1个 market
	blueprint_manager.add_blueprint(market)
	
	blueprint_manager.add_blueprint(martial_arena)
	
	print("[InitialBuilding] 初始建筑已通过代码直接加载并调用 add_blueprint 发放完毕！")
