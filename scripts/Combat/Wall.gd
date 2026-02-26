class_name Wall
extends Unit_General

func _on_ready_override() -> void:
	faction = Faction.PLAYER
	add_to_group("player_units")
	add_to_group("structures")

	max_hp = 500.0
	current_hp = max_hp

	# 城墙不移动不攻击
	move_speed = 0.0
	attack_damage = 0.0
	attack_range = 0.0

func _physics_process(_delta: float) -> void:
	# 完全覆盖父类逻辑，城墙什么都不做
	pass

func _on_death_override() -> void:
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")
