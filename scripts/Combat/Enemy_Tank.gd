class_name Enemy_Tank
extends Unit_General

func _on_ready_override() -> void:
	faction = Faction.ENEMY
	add_to_group("enemy_units")
	
	max_hp = 300.0
	current_hp = max_hp
	attack_damage = 15.0
	move_speed = 50.0
	attack_type = AttackType.SINGLE
