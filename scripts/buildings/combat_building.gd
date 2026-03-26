extends Building
class_name CombatBuilding

var active_minions: Array = []
var old_progress: float = 0.0
var _debug_timer: float = 0.0

func _ready():
	super._ready()
	if data and data.amount_per_cycle <= 0:
		data.amount_per_cycle = 1

func _process(delta):
	_cleanup_minions()
	super._process(delta)

func _tick_production(delta):
	if not data: 
		print("[%s] data 为空，跳过生产" % name)
		return

	_debug_timer -= delta
	if _debug_timer <= 0.0:
		_debug_timer = 1.0
		print("[%s] active_minions:%d 上限:%d current_progress:%.2f old_progress:%.2f" % [
			name, active_minions.size(), data.amount_per_cycle, current_progress, old_progress
		])

	if active_minions.size() >= data.amount_per_cycle:
		if progress_pie:
			progress_pie.value = 0
		current_progress = 0.0
		return

	super._tick_production(delta)

	if current_progress <= 0.0 and old_progress > 0.9:
		print("[%s] 进度条触发！准备产兵" % name)
		_spawn_minion()

func _physics_process(_delta):
	old_progress = current_progress

func _spawn_minion():
	if data == null or data.minion_scene == null:
		print("[%s] 错误：minion_scene 为空" % name)
		return

	var minion = data.minion_scene.instantiate()
	get_parent().add_child(minion)

	var spawn_pos = self.global_position + Vector2(50, 0)
	var spawn_point = get_tree().get_first_node_in_group("spawn_point")
	if spawn_point:
		spawn_pos = spawn_point.global_position
	else:
		print("[%s] 警告：找不到 spawn_point" % name)

	var offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
	minion.global_position = spawn_pos + offset
	active_minions.append(minion)
	print("[%s] 产兵成功，当前场内: %d/%d" % [name, active_minions.size(), data.amount_per_cycle])

func _cleanup_minions():
	active_minions = active_minions.filter(func(m): return is_instance_valid(m))

func get_save_data() -> Dictionary:
	var dict = super.get_save_data()
	var minion_names = []
	for m in active_minions:
		if is_instance_valid(m):
			minion_names.append(m.name)
	dict["minion_names"] = minion_names
	return dict
