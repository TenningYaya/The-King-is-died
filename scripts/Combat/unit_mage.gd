class_name Unit_Mage
extends Unit_General

func _on_ready_override() -> void:
	add_to_group("player_units")

func _on_death_override() -> void:
	pass
