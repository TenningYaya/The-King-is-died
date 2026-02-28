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

func _input(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		match event.keycode:
			KEY_SPACE:
				# 核心逻辑：如果是暂停状态，按空格回到 1 倍速；否则进入暂停
				if Engine.time_scale == SPEED_PAUSE:
					_on_speed_changed(SPEED_NORMAL)
				else:
					_on_speed_changed(SPEED_PAUSE)
			KEY_1:
				_on_speed_changed(SPEED_NORMAL)
			KEY_2:
				_on_speed_changed(SPEED_FAST)
			KEY_3:
				_on_speed_changed(SPEED_SUPER)

func _on_speed_changed(speed_value: float):
	Engine.time_scale = speed_value
	_update_button_visuals(speed_value)

func _update_button_visuals(current_speed: float):
	# 更新按钮高亮
	$PauseBtn.modulate = Color.YELLOW if current_speed == SPEED_PAUSE else Color.WHITE
	$Speed1Btn.modulate = Color.YELLOW if current_speed == SPEED_NORMAL else Color.WHITE
	$Speed2Btn.modulate = Color.YELLOW if current_speed == SPEED_FAST else Color.WHITE
	$Speed3Btn.modulate = Color.YELLOW if current_speed == SPEED_SUPER else Color.WHITE
