# button_demolish.gd
extends Button

@export var demolish_cursor: Texture2D

func _ready():
	add_to_group("demolish_button_node")
	pressed.connect(_on_pressed)

func _on_pressed():
	Input.set_custom_mouse_cursor(demolish_cursor, Input.CURSOR_ARROW, Vector2(40, 40))
	# 2. 全局通知：进入拆除模式
	get_tree().call_group("buildings", "enter_demolish_mode")

func reset_mode():
	Input.set_custom_mouse_cursor(null)
	get_tree().call_group("buildings", "exit_demolish_mode")

# 点击空白处退出模式
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		get_tree().process_frame.connect(reset_mode, CONNECT_ONE_SHOT)
