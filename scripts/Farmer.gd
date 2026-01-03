extends CharacterBody2D
class_name Farmer

@export var max_hp: int = 30
@export var atk: int = 4
@export var attack_range: float = 26.0
@export var attack_cooldown: float = 0.6

var hp: int = 30
var _cd: float = 0.0

func _ready() -> void:
	hp = max_hp

func _physics_process(dt: float) -> void:
	_cd = max(0.0, _cd - dt)

	var enemy = _find_closest_enemy() # 不用 :=
	if enemy == null:
		return

	var d: float = global_position.distance_to(enemy.global_position)
	if d <= attack_range and _cd <= 0.0:
		_cd = attack_cooldown
		enemy.take_damage(atk)

func take_damage(dmg: int) -> void:
	hp -= dmg
	if hp <= 0:
		queue_free()

func _find_closest_enemy() -> Node2D:
	var enemies_node: Node = get_tree().current_scene.get_node("Combat/Enemies")
	var best: Node2D = null
	var best_d: float = INF

	for e in enemies_node.get_children():
		if e is Node2D and e.has_method("take_damage"):
			var d: float = global_position.distance_to((e as Node2D).global_position)
			if d < best_d:
				best_d = d
				best = e as Node2D

	return best
	#111
