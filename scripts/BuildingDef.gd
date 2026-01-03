extends Resource
class_name BuildingDef

@export var id: String = ""
@export var requires_gaze: bool = true

# Farm: produce wheat each second while active
@export var wheat_per_sec: int = 0

# Hut: while active, spend wheat to spawn farmers
@export var spawn_farmer_cost: int = 0
