## level_game_scene.gd
extends Node2D

# 1. 预加载你的引导界面场景（注意替换为你实际保存的文件路径！）
const TUTORIAL_SCENE = preload("res://Scene/ui/tutorial_layer.tscn")

func _ready():
	if GamedataManager.is_loading_save:
		# ========== 这是【读档】的逻辑（你原有的代码） ==========
		# 2. 塞兵逻辑
		SaveManager.load_game_from_dict(GamedataManager.full_save_dict)
		
		# 3. 【核心点火】全场建筑，统一开工！
		get_tree().call_group("buildings", "set_active_status", true)
		
		GamedataManager.is_loading_save = false
	else:
		# ========== 这是【新游戏】的逻辑 ==========
		start_new_game_tutorial()

# 新游戏开场逻辑
func start_new_game_tutorial() -> void:
	# 实例化刚才做好的新手引导 UI
	var tutorial = TUTORIAL_SCENE.instantiate()
	
	# 将引导 UI 添加到当前游戏场景中
	add_child(tutorial)
	
	# 注：因为你在 TutorialUI 的脚本 _ready() 里已经写了 get_tree().paused = true，
	# 所以这里 add_child 一执行，游戏时间线就会立刻冻结，怪物不会动，只有对话在进行！
