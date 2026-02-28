extends CanvasLayer

@onready var menu_box = $ScreenOverlay/MenuBox
@onready var close_btn = $ScreenOverlay/MenuBox/CloseBtn

func _ready():
	# 初始隐藏菜单
	hide()
	# 点击窗口右上角的 X 关闭菜单
	close_btn.pressed.connect(close_menu)

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
