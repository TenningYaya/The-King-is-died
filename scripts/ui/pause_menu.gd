#pause_menu.gd
extends CanvasLayer

@onready var menu_box = $ScreenOverlay/MenuBox
@onready var close_btn = $ScreenOverlay/MenuBox/CloseBtn
@onready var _master_bus_index = AudioServer.get_bus_index("Master")
@onready var volume = $ScreenOverlay/HSlider

# --- 新增引用 ---
@onready var quit_btn = $ScreenOverlay/Quit
@onready var back_confirm_window = $BackMainWindow

func _ready():
	# 初始隐藏菜单
	hide()
	# 点击窗口右上角的 X 关闭菜单
	close_btn.pressed.connect(close_menu)
	var current_db = AudioServer.get_bus_volume_db(_master_bus_index)
	volume.value = db_to_linear(current_db) # 将分贝转回 0-1 的线性值
	
func _on_quit_pressed():
	# 唤醒确认弹窗
	if back_confirm_window:
		back_confirm_window.open()
		
func _input(event):
	# 检测按下 ESC 键
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if visible:
			close_menu()
		else:
			open_menu()

func open_menu():
	show()
	# 弹出菜单时，游戏世界应该暂停
	# 注意：PauseMenu 节点的 Process Mode 必须设为 "Always"，否则它也会被自己停掉
	get_tree().paused = true

func close_menu():
	hide()
	# 关闭菜单，游戏恢复运行
	get_tree().paused = false

func _on_h_slider_value_changed(value: float) -> void:
	# 核心黑科技：linear_to_db
	# 音量不能直接用百分比加减，必须用这个函数转成符合人类听觉的分贝(dB)
	var db_value = linear_to_db(value)
	
	AudioServer.set_bus_volume_db(_master_bus_index, db_value)
	
	# 如果拉到最左边，直接静音防止杂音
	if value <= 0.05:
		AudioServer.set_bus_mute(_master_bus_index, true)
	else:
		AudioServer.set_bus_mute(_master_bus_index, false)
