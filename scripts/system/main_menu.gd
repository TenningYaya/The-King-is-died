#main_menu.gd
extends CanvasLayer

@onready var resource_manager = get_node("/root/PathTo/LevelResourceManager")


func _on_new_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene/Game.tscn")


func _on_load_pressed() -> void:
	var success = SaveManager.load_game(resource_manager)
	if success:
		# 切换到游戏关卡场景
		get_tree().change_scene_to_file("res://Scene/Game.tscn")
		pass
	else:
		print("没有存档，请开始新游戏")
