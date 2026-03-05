# button_sell_blueprint.gd
extends Button

@export var sell_cursor: Texture2D = preload("res://art_assets/ui/button_sell_blueprint.png")

func _ready():
	add_to_group("sell_button_node")
	pressed.connect(_on_toggle_sell_mode)

func _on_toggle_sell_mode():
	# 切换指针
	Input.set_custom_mouse_cursor(sell_cursor, Input.CURSOR_ARROW)
	# 让所有格子进入变红待命状态
	get_tree().call_group("blueprint_slots", "enter_sell_mode")

func reset_mode():
	Input.set_custom_mouse_cursor(null)
	get_tree().call_group("blueprint_slots", "exit_sell_mode")

# 监听全局点击：点在空白处自动退出模式
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		# 如果点到了没被 accept_event() 的地方，说明点到了外面
		get_tree().process_frame.connect(reset_mode, CONNECT_ONE_SHOT)
