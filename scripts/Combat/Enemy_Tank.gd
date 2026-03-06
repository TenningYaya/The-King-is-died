class_name Enemy_Tank
extends Unit_General

func _on_ready_override() -> void:
	faction = Faction.ENEMY
	add_to_group("enemy_units")
