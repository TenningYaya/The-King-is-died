extends Node
class_name EnemySpawner

@export var enemy_scene: PackedScene
@export var spawn_interval := 1.6

@export var spawn_x := 780.0
@export var spawn_y_min := 80.0
@export var spawn_y_max := 520.0

@export var wall_x := 40.0

@onready var enemies := get_parent().get_node("Combat/Enemies")

var _t := 0.0

func _process(dt: float) -> void:
	_t += dt
	if _t >= spawn_interval:
		_t -= spawn_interval
		spawn_enemy()

func spawn_enemy() -> void:
	if enemy_scene == null:
		return
	var e: Enemy = enemy_scene.instantiate()
	e.global_position = Vector2(spawn_x, randf_range(spawn_y_min, spawn_y_max))
	e.wall_x = wall_x
	enemies.add_child(e)
