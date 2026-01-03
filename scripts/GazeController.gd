extends Node2D
class_name GazeController

@export var origin: Vector2i = Vector2i(5, 5)
var rot_idx := 0 # 0..3

var active_cells: Dictionary = {}

# L-shape offsets (including origin)
const SHAPE := [
	Vector2i(0,0), Vector2i(1,0), Vector2i(2,0),
	Vector2i(0,1), Vector2i(0,2)
]

@onready var board: GridBoard = get_parent().get_node("GridBoard")

func _ready() -> void:
	rebuild()

func _unhandled_input(event: InputEvent) -> void:
	# Drag gaze with LMB
	if event.is_action_pressed("drag_gaze") or (event is InputEventMouseMotion and Input.is_action_pressed("drag_gaze")):
		var cell := board.world_to_cell(board.get_global_mouse_position())
		if board.in_bounds(cell):
			origin = cell
			rebuild()

	# Rotate (optional)
	if event.is_action_pressed("rotate_left"):
		rot_idx = (rot_idx + 3) % 4
		rebuild()
	elif event.is_action_pressed("rotate_right"):
		rot_idx = (rot_idx + 1) % 4
		rebuild()

func rebuild() -> void:
	active_cells.clear()
	for off in SHAPE:
		var r := rotate_cell(off, rot_idx)
		active_cells[origin + r] = true

func is_active(cell: Vector2i) -> bool:
	return active_cells.has(cell)

static func rotate_cell(v: Vector2i, rot: int) -> Vector2i:
	match rot:
		0: return v
		1: return Vector2i(-v.y, v.x)
		2: return Vector2i(-v.x, -v.y)
		3: return Vector2i(v.y, -v.x)
	return v
