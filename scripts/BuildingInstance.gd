extends Node2D
class_name BuildingInstance

var def: BuildingDef
var cell: Vector2i

var _acc := 0.0

func setup(_def: BuildingDef, _cell: Vector2i) -> void:
	def = _def
	cell = _cell

func tick(dt: float, active: bool, state: State, spawn_farmer_cb: Callable) -> void:
	if def.requires_gaze and not active:
		return

	# Farm: +wheat each second
	if def.wheat_per_sec > 0:
		_acc += dt
		while _acc >= 1.0:
			_acc -= 1.0
			state.wheat += def.wheat_per_sec

	# Hut: spend wheat to spawn farmers (as long as you have enough)
	if def.spawn_farmer_cost > 0:
		while state.wheat >= def.spawn_farmer_cost:
			state.wheat -= def.spawn_farmer_cost
			spawn_farmer_cb.call()
