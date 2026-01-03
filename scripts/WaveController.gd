extends Node
class_name WaveController

@onready var board: GridBoard = get_parent().get_node("GridBoard")

var in_wave: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start_wave") and not in_wave:
		start_next_wave()

func start_next_wave() -> void:
	in_wave = true
	board.state.wave_index += 1

	var wave: int = board.state.wave_index

	# Simple scaling (numbers are ints)
	var enemy_hp: int = 20 + wave * 15
	var enemy_dps: int = 4 + wave * 2

	# Your power
	# 如果你已经改成“农民数量”，就用农民数量替代 soldiers
	var farmer_count: int = get_tree().current_scene.get_node("Combat/Farmers").get_child_count()
	var soldier_dps: int = farmer_count * 4  # 这里让每个农民按4dps算，先简单
	var duration_limit: float = 10.0 + float(wave) * 1.5

	if soldier_dps <= 0:
		_apply_wall_damage(int(ceil(float(enemy_dps) * duration_limit)))
		_end_wave()
		return

	var ttk: float = float(enemy_hp) / float(soldier_dps)

	if ttk <= duration_limit:
		# win reward
		board.state.wheat += 3 + wave
	else:
		_apply_wall_damage(int(ceil(float(enemy_dps) * duration_limit)))

	_end_wave()

func _apply_wall_damage(dmg: int) -> void:
	board.state.wall_hp -= dmg
	board.state.wall_hp = max(0, board.state.wall_hp)

func _end_wave() -> void:
	in_wave = false
	if board.state.wall_hp <= 0:
		# quick reset
		board.state.wall_hp = 50
		board.state.wheat = 0
		board.state.wave_index = 0
