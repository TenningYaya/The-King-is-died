#building.gd
extends Area2D
class_name Building

@export var data: BuildingData # 每个建筑实体都持有一份数据引用

var current_progress: float = 0.0
var is_active: bool = true

@onready var progress_pie = $UIContainer/ProgressBar

func _process(delta):
	if not is_active or data == null:
		return
	_tick_production(delta)

# 共有机制：进度条旋转
func _tick_production(delta):
	current_progress += delta / data.production_time
	if progress_pie:
		progress_pie.value = current_progress * 100
	
	if current_progress >= 1.0:
		current_progress = 0.0
		_on_cycle_complete() # 钩子函数

# 虚函数：留给子类实现
func _on_cycle_complete():
	pass
