#mouse_debugger.gd
extends Control

func _ready():
	# 确保这个调试点不会拦截任何点击
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 永远显示在最顶层
	z_index = 4096 

func _process(_delta):
	# 每一帧请求重绘
	queue_redraw()

func _draw():
	# 获取鼠标在屏幕上的真实逻辑坐标
	var mouse_pos = get_local_mouse_position()
	
	# 画一个半径为 3 的红点，这就是系统认定的“点击发生点”
	draw_circle(mouse_pos, 3, Color.RED)
	
	# 画一个十字架，方便十字对齐
	draw_line(mouse_pos + Vector2(-10, 0), mouse_pos + Vector2(10, 0), Color.GREEN, 1)
	draw_line(mouse_pos + Vector2(0, -10), mouse_pos + Vector2(0, 10), Color.GREEN, 1)
