extends Node2D
class_name GridBoard

@export var grid_size := Vector2i(11, 11)
@export var cell_size := 48
@export var farmer_scene: PackedScene

var state := State.new()
var buildings: Dictionary = {} # Vector2i -> BuildingInstance
var defs := {}                 # id -> BuildingDef
var selected_id := "farm"

var _font: Font

@onready var gaze: GazeController = get_parent().get_node("GazeController")
@onready var farmers_node: Node2D = get_parent().get_node("Combat/Farmers")
@onready var status_label: Label = get_parent().get_node("UI/HUD/StatusLabel")

func _ready() -> void:
	_font = ThemeDB.fallback_font
	_build_defs()
	_update_status()

func _process(dt: float) -> void:
	# Tick buildings
	for cell in buildings.keys():
		var b: BuildingInstance = buildings[cell]
		var active := gaze.is_active(cell)
		b.tick(dt, active, state, Callable(self, "spawn_farmer"))

	_update_status()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	# Select building type
	if event.is_action_pressed("place_farm"):
		selected_id = "farm"
	elif event.is_action_pressed("place_hut"):
		selected_id = "hut"

	# RMB to place building (LMB is used for dragging gaze)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var cell := world_to_cell(get_global_mouse_position())
		_try_place(cell)

func _try_place(cell: Vector2i) -> void:
	if not in_bounds(cell):
		return
	if buildings.has(cell):
		return

	var def: BuildingDef = defs[selected_id]

	var inst := BuildingInstance.new()
	inst.setup(def, cell)
	inst.position = cell_to_world(cell) + Vector2(cell_size / 2.0, cell_size / 2.0)
	add_child(inst)
	buildings[cell] = inst

func spawn_farmer() -> void:
	if farmer_scene == null:
		return
	var f: Farmer = farmer_scene.instantiate()

	# Spawn farmers near the right side to defend
	# (Later: spawn next to the hut cell for more "original-like" feel)
	f.global_position = Vector2(grid_size.x * cell_size + 180, 300 + randf_range(-120, 120))
	farmers_node.add_child(f)

func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y

func world_to_cell(p: Vector2) -> Vector2i:
	return Vector2i(floor(p.x / cell_size), floor(p.y / cell_size))

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * cell_size, cell.y * cell_size)

func _build_defs() -> void:
	# Farm
	var farm := BuildingDef.new()
	farm.id = "farm"
	farm.requires_gaze = true
	farm.wheat_per_sec = 1

	# Farmer Hut
	var hut := BuildingDef.new()
	hut.id = "hut"
	hut.requires_gaze = true
	hut.spawn_farmer_cost = 8

	defs["farm"] = farm
	defs["hut"] = hut

func _update_status() -> void:
	status_label.text = "Wheat:%d  Farmers:%d  WallHP:%d  [1]Farm [2]Hut  RMB:Place  LMB:Drag Gaze  Q/E:Rotate" % [
		state.wheat,
		farmers_node.get_child_count(),
		state.wall_hp
	]

func _draw() -> void:
	# Draw grid + gaze overlay + building labels
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var cell := Vector2i(x, y)
			var rect := Rect2(Vector2(x * cell_size, y * cell_size), Vector2(cell_size, cell_size))

			if gaze.is_active(cell):
				draw_rect(rect, Color(1, 1, 0, 0.15), true)

			draw_rect(rect, Color(1, 1, 1, 0.08), false, 1.0)

			if buildings.has(cell):
				var b: BuildingInstance = buildings[cell]
				draw_string(_font, rect.position + Vector2(4, 16), b.def.id)
