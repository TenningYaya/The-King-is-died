extends CharacterBody2D
class_name Enemy

@export var max_hp: int = 20
@export var atk: int = 2
@export var speed: float = 70.0
@export var attack_range: float = 22.0
@export var attack_cooldown: float = 0.8

@export var wall_x: float = 40.0

var hp: int = 20
var _cd: float = 0.0

func _ready() -> void:
	hp = max_hp

func _physics_process(dt: float) -> void:
	_cd = max(0.0, _cd - dt)

	# Hit wall
	if global_position.x <= wall_x:
		var board: GridBoard = get_tree().current_scene.get_node("GridBoard")
		board.state.wall_hp -= 5
		queue_free()
		return

	var farmer = _find_closest_farmer() # 不用 :=
	if farmer != null:
		var d: float = global_position.distance_to(farmer.global_position)
		if d <= attack_range:
			velocity = Vector2.ZERO
			if _cd <= 0.0:
				_cd = attack_cooldown
				farmer.take_damage(atk)
		else:
			velocity = Vector2(-speed, 0)
	else:
		velocity = Vector2(-speed, 0)

	move_and_slide()

func take_damage(dmg: int) -> void:
	hp -= dmg
	if hp <= 0:
		queue_free()

func _find_closest_farmer() -> Node2D:
	var farmers_node: Node = get_tree().current_scene.get_node("Combat/Farmers")
	var best: Node2D = null
	var best_d: float = INF

	for f in farmers_node.get_children():
		if f is Node2D and f.has_method("take_damage"):
			var d: float = global_position.distance_to((f as Node2D).global_position)
			if d < best_d:
				best_d = d
				best = f as Node2D

	return best
