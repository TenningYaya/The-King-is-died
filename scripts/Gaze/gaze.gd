#对于5*5的完整地块，本script统一称为field。
#对于每个单独格子，本script统一称为grid。
extends Node2D
class_name GazeController

#设置grid，大小，整个field
const grid_size := 120
const field_grid := 5
const field_size := 600

@export var min_level := 3
@export var max_level := 6
@export var start_level := 3
#资源文件夹
@export var gaze_folder := "res://art_assets/gaze/"

@onready var sprite: Sprite2D = $Sprite2D

var level : int
var dragging := false
var drag_offset := Vector2.ZERO

#旋转角度0/90/180/270
var rotation_degree := 0

#整个凝视的集合array（以格子的形式，0,0 这种）
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
# 
func _ready() -> void:
	# ✅ 让 sprite 以纹理中心为旋转中心（自转）
	sprite.centered = true
	sprite.position = Vector2.ZERO

	level = clampi(start_level, min_level, max_level)
	refresh_level()
	set_top_left(Vector2.ZERO)

func _process(_delta: float) -> void:
	if dragging and not Input.is_action_pressed("drag_gaze"):
		dragging = false

#负责管各种input（左键按住拖动和右键旋转）
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("drag_gaze"):
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


#判断鼠标是否在凝视范围里
func mouse_inside_gaze() -> bool:
	# Node2D 原点在“包围盒中心”，所以 local(0,0) 是中心
	# 转成“左上角为(0,0)”的坐标：
	var local := to_local(get_global_mouse_position())
	var mousePos := local + get_pixel_size() * 0.5

	if mousePos.x < 0 or mousePos.y < 0:
		return false

	var gx := int(floor(mousePos.x / grid_size))
	var gy := int(floor(mousePos.y / grid_size))

	# 注意是 >=
	if gx < 0 or gy < 0 or gx >= width or gy >= height:
		return false

	return Vector2i(gx, gy) in gaze
	
func get_top_left() -> Vector2:
	var size_px := get_pixel_size()
	return global_position - size_px * 0.5

func set_top_left(target_top_left: Vector2) -> void:
	# 吸附到 120px 网格
	var snapped := target_top_left.snapped(Vector2(grid_size, grid_size))
	# clamp 到 600×600 内（基于形状包围盒尺寸）
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

	# ✅ sprite 自转：只转 sprite，不改 sprite.position
	sprite.rotation = rotation_degree * PI * 0.5

	# ✅ 位置仍然按你的逻辑：保持中心不变，再用 top_left 做 snap + clamp
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
	# base_cells 必须是 0-based
	var out: Array[Vector2i] = []

	# 先拿 base 的 bbox（用于旋转公式）
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
			1: # 90 CW
				rx = bh - 1 - y
				ry = x
			2: # 180
				rx = bw - 1 - x
				ry = bh - 1 - y
			3: # 270 CW
				rx = y
				ry = bw - 1 - x
		out.append(Vector2i(rx, ry))

	# ✅ 关键：旋转后再 normalize，让形状回到左上角(0,0)
	out = normalize_to_0based(out)

	gaze = out
	_update_bbox(gaze)
	
func update_sprite_offset() -> void:
	# Sprite2D centered=false，所以它 position 是“绘制左上角”
	# 我们要让 Node2D 的原点始终在“包围盒中心”，这样旋转好用
	var size_px := get_pixel_size()
	sprite.position = -size_px * 0.5

func refresh_level() -> void:
	apply_texture_for_level(level)
	rotation_degree = rotation_degree % 4
	refresh_shape()

	# ✅ centered=true 后不需要 update_sprite_offset()
	sprite.rotation = rotation_degree * PI * 0.5

func apply_texture_for_level(n: int) -> void:
	var path := "%s%dgrid.png" % [gaze_folder, n]
	var tex := load(path)
	if tex == null:
		push_error("Gaze texture not found: " + path)
		return
	sprite.texture = tex
