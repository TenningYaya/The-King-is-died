# Tank.gd
class_name Tank
extends Unit_General

func _on_ready_override() -> void:
	# 设置默认数值，也可直接在 Inspector 里改
	max_hp = 300.0
	attack_damage = 15.0
	attack_type = AttackType.SINGLE
	move_speed = 50.0
	current_hp = max_hp
	add_to_group("player_units")  # 或 "enemy_units"

func _on_death_override() -> void:
	# 播放死亡动画等
	pass
