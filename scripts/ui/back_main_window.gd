#back_main_window.gd
extends PanelContainer

var pre_popup_speed = 1.0
@onready var overlay = $"../Overlay"

func _ready():
	# 初始隐藏
	visible = false
	overlay.visible = false
# 【核心设置】确保弹窗自己在游戏暂停时也能响应点击
	# 在编辑器里把它的 Process Mode 设为 "Always" 也可以
	process_mode = PROCESS_MODE_ALWAYS
	overlay.process_mode = PROCESS_MODE_ALWAYS

	# ... 原有代码
	# 强制让这个亮的 X 号排在最前面，无视任何遮挡
	$Control/CloseBtn.z_index = 100 
	# 或者尝试这个，看看到底是谁在接收点击

# 找到那个亮的 X 号
	var bright_x = $Control/CloseBtn
	
	# 【强制重连】不管面板连没连，代码里硬连一次
	if bright_x.pressed.is_connected(_on_close_pressed):
		bright_x.pressed.disconnect(_on_close_pressed) # 先断开旧的
	bright_x.pressed.connect(_on_close_pressed)     # 再连上新的
	
func open():
	pre_popup_speed = Engine.time_scale
	Engine.time_scale = 0.0
	
	overlay.show()
	show()

func _on_close_pressed():
	Engine.time_scale = 1.0
	overlay.hide()
	hide()
	
func _on_save_pressed():
	SaveManager.save_game()
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().call_deferred("change_scene_to_file", "res://Scene/system/main_menu.tscn")
	hide()

func _on_no_save_pressed():
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scene/system/main_menu.tscn")
	hide()
