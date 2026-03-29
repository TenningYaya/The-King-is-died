extends HBoxContainer

# 定义速度常量
const SPEED_PAUSE = 0.0
const SPEED_NORMAL = 1.0
const SPEED_FAST = 2.0
const SPEED_SUPER = 3.0

# 用于记录暂停前的速度，以便恢复（可选，这里我们先按你的要求直接回 1.0）
var last_speed = SPEED_NORMAL

func _ready():
	# 信号连接保持不变
	$PauseBtn.pressed.connect(_on_speed_changed.bind(SPEED_PAUSE))
	$Speed1Btn.pressed.connect(_on_speed_changed.bind(SPEED_NORMAL))
	$Speed2Btn.pressed.connect(_on_speed_changed.bind(SPEED_FAST))
	$Speed3Btn.pressed.connect(_on_speed_changed.bind(SPEED_SUPER))
	
	_on_speed_changed(SPEED_NORMAL)

func _on_speed_changed(speed_value: float):
	# 【核心修改 1】只有在设置非 0 速度时，才记录为“上一次速度”
	if speed_value != SPEED_PAUSE:
		last_speed = speed_value
	
	Engine.time_scale = speed_value
	_update_button_visuals(speed_value)

func _input(event):
	# 【核心修改 2】确保只在按下那一瞬间触发，且不重复响应
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_SPACE:
			# 消耗掉输入，防止触发按钮的“确认”点击
			get_viewport().set_input_as_handled()
			
			if Engine.time_scale == SPEED_PAUSE:
				# 恢复到暂停前的速度（可能是 1.0, 2.0 或 3.0）
				_on_speed_changed(last_speed)
			else:
				# 记录当前速度并暂停
				_on_speed_changed(SPEED_PAUSE)
				
		# 数字键切换直接触发，会自动更新 last_speed
		match event.keycode:
			KEY_1: _on_speed_changed(SPEED_NORMAL)
			KEY_2: _on_speed_changed(SPEED_FAST)
			KEY_3: _on_speed_changed(SPEED_SUPER)

func _update_button_visuals(current_speed: float):
	# 更新按钮高亮
	$PauseBtn.modulate = Color.YELLOW if current_speed == SPEED_PAUSE else Color.WHITE
	$Speed1Btn.modulate = Color.YELLOW if current_speed == SPEED_NORMAL else Color.WHITE
	$Speed2Btn.modulate = Color.YELLOW if current_speed == SPEED_FAST else Color.WHITE
	$Speed3Btn.modulate = Color.YELLOW if current_speed == SPEED_SUPER else Color.WHITE
