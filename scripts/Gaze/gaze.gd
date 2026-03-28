#对于5*5的完整地块，本script统一称为field。
#对于每个单独格子，本script统一称为grid。
#gaze.gd
extends Node2D
class_name GazeController

const grid_size := 120
const field_grid := 5
const field_size := 600

@export var min_level := 3
@export var max_level := 6
@export var start_level := 3
@export var gaze_folder := "res://art_assets/gaze/"

@onready var sprite: Sprite2D = $Sprite2D

var level : int
var dragging := false
var drag_offset := Vector2.ZERO
var rotation_degree := 0
var gaze: Array[Vector2i] = []

const SHAPE_3: Array[Vector2i] = [Vector2i(1,1), Vector2i(2,1), Vector2i(2,2)]
const SHAPE_4: Array[Vector2i] = [Vector2i(1,1), Vector2i(1,2), Vector2i(2,1), Vector2i(2,2)]
const SHAPE_5: Array[Vector2i] = [Vector2i(1,1), Vector2i(1,2), Vector2i(2,1), Vector2i(2,2), Vector2i(2,3)]
const SHAPE_6: Array[Vector2i] = [Vector2i(1,1), Vector2i(1,2), Vector2i(2,1), Vector2i(2,2), Vector2i(3,1), Vector2i(3,2)]

const shape := {
	3: SHAPE_3,
	4: SHAPE_4,
	5: SHAPE_5,
	6: SHAPE_6,
}

var width := 1
var height := 1

func _ready() -> void:
	sprite.centered = true
	sprite.position = Vector2.ZERO
	
	var my_data = GamedataManager.get_data_for_node(name)
	if my_data and not my_data.is_empty():
		load_save_data(my_data)
	else:
		level = clampi(start_level, min_level, max_level)
		rotation_degree = 0
		refresh_level()
		set_top_left(Vector2.ZERO)

func _process(_delta: float) -> void:
	if dragging and not Input.is_action_pressed("drag_gaze"):
		dragging = false

func _input(event: InputEvent) -> void:
	if get_viewport().gui_get_hovered_control() != null:
		return
	
	if event.is_action_pressed("drag_gaze"):
		if Input.is_key_pressed(KEY_SHIFT) and _mouse_over_building():
			return
		if mouse_inside_gaze():
			dragging = true
			drag_offset = get_global_mouse_position() - get_top_left()
			get_viewport().set_input_as_handled()

	if event.is_action_released("drag_gaze"):
		dragging = false

	if event.is_action_pressed("rotate_gaze"):
		if mouse_inside_gaze():
			rotate_90()
			get_viewport().set_input_as_handled()

	if event is InputEventMouseMotion and dragging:
		var target := get_global_mouse_position() - drag_offset
		set_top_left(target)
		get_viewport().set_input_as_handled()

func mouse_inside_gaze() -> bool:
	var local := to_local(get_global_mouse_position())
	var mousePos := local + get_pixel_size() * 0.5

	if mousePos.x < 0 or mousePos.y < 0:
		return false

	var gx := int(floor(mousePos.x / grid_size))
	var gy := int(floor(mousePos.y / grid_size))

	if gx < 0 or gy < 0 or gx >= width or gy >= height:
		return false

	return Vector2i(gx, gy) in gaze

func get_top_left() -> Vector2:
	var size_px := get_pixel_size()
	return global_position - size_px * 0.5

func set_top_left(target_top_left: Vector2) -> void:
	var snapped := target_top_left.snapped(Vector2(grid_size, grid_size))
	var size_px := get_pixel_size()
	var max_top_left := Vector2(field_size - size_px.x, field_size - size_px.y)
	var clamped := Vector2(
		clampf(snapped.x, 0.0, max_top_left.x),
		clampf(snapped.y, 0.0, max_top_left.y)
	)
	global_position = clamped + size_px * 0.5

func get_pixel_size() -> Vector2:
	return Vector2(float(width * grid_size), float(height * grid_size))

func rotate_90() -> void:
	var old_center := global_position
	rotation_degree = (rotation_degree + 1) % 4
	refresh_shape()
	sprite.rotation = rotation_degree * PI * 0.5
	var new_top_left := old_center - get_pixel_size() * 0.5
	set_top_left(new_top_left)

func refresh_shape() -> void:
	var base_1based: Array[Vector2i] = shape[level] if shape.has(level) else ([] as Array[Vector2i])
	var base := normalize_to_0based(base_1based)
	apply_rotation_from_base(base)

func normalize_to_0based(cells: Array[Vector2i]) -> Array[Vector2i]:
	var min_x := 1_000_000_000
	var min_y := 1_000_000_000
	for c in cells:
		min_x = mini(min_x, c.x)
		min_y = mini(min_y, c.y)
	var out: Array[Vector2i] = []
	for c in cells:
		out.append(Vector2i(c.x - min_x, c.y - min_y))
	return out

func _update_bbox(cells: Array[Vector2i]) -> void:
	var max_x := 0
	var max_y := 0
	for c in cells:
		max_x = maxi(max_x, c.x)
		max_y = maxi(max_y, c.y)
	width = max_x + 1
	height = max_y + 1

func apply_rotation_from_base(base_cells: Array[Vector2i]) -> void:
	var out: Array[Vector2i] = []
	var max_x := 0
	var max_y := 0
	for c in base_cells:
		max_x = maxi(max_x, c.x)
		max_y = maxi(max_y, c.y)
	var bw := max_x + 1
	var bh := max_y + 1

	for c in base_cells:
		var x := c.x
		var y := c.y
		var rx := x
		var ry := y
		match rotation_degree:
			0:
				rx = x; ry = y
			1:
				rx = bh - 1 - y
				ry = x
			2:
				rx = bw - 1 - x
				ry = bh - 1 - y
			3:
				rx = y
				ry = bw - 1 - x
		out.append(Vector2i(rx, ry))

	out = normalize_to_0based(out)
	gaze = out
	_update_bbox(gaze)

func update_sprite_offset() -> void:
	var size_px := get_pixel_size()
	sprite.position = -size_px * 0.5

func refresh_level() -> void:
	apply_texture_for_level(level)
	rotation_degree = rotation_degree % 4
	# 先记录旧的中心点
	var old_center := global_position
	# 再刷新形状（这会更新 width/height）
	refresh_shape()
	sprite.rotation = rotation_degree * PI * 0.5
	# 用旧中心点减去新的 half_size 得到新的 top_left，再 snap + clamp
	var new_top_left := old_center - get_pixel_size() * 0.5
	set_top_left(new_top_left)

func apply_texture_for_level(n: int) -> void:
	var path := "%s%dgrid.png" % [gaze_folder, n]
	var tex := load(path)
	if tex == null:
		push_error("Gaze texture not found: " + path)
		return
	sprite.texture = tex

func is_position_covered(global_pos: Vector2) -> bool:
	var local_pos = to_local(global_pos)
	var offset_pos = local_pos + get_pixel_size() * 0.5
	var gx = int(floor(offset_pos.x / grid_size))
	var gy = int(floor(offset_pos.y / grid_size))
	return Vector2i(gx, gy) in gaze

func _mouse_over_building() -> bool:
	var space := get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = get_global_mouse_position()
	params.collide_with_areas = true
	params.collide_with_bodies = true
	var hits := space.intersect_point(params, 32)
	for h in hits:
		var c = h.get("collider")
		if c and c.is_in_group("buildings"):
			return true
	return false

func get_save_data() -> Dictionary:
	return {
		"level": level,
		"rotation_degree": rotation_degree,
		"top_left_x": get_top_left().x,
		"top_left_y": get_top_left().y
	}

func load_save_data(data: Dictionary):
	if data.is_empty(): return
	level = data.get("level", start_level)
	rotation_degree = data.get("rotation_degree", 0)
	refresh_level()
	var tl = Vector2(data.get("top_left_x", 0.0), data.get("top_left_y", 0.0))
	set_top_left(tl)
	var ui = get_tree().get_first_node_in_group("gaze_upgrade_ui")
	if ui and ui.has_method("_update_display"):
		ui._update_display()
