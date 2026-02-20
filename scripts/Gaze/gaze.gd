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
@export var gaze_folder := "res://ArtAssets/Gaze/"

@onready var sprite: Sprite2D = $Sprite2D

var level : int
var dragging := false
var drag_offset := Vector2.ZERO

#旋转角度0/90/180/270
var rotation_degree := 0

#整个凝视的集合array（以格子的形式，0,0 这种）
var gaze: Array[Vector2i] = []
const shape := {
	3: [Vector2i(1,1), Vector2i(1,2), Vector2i(2,2)],
	4: [Vector2i(1,1), Vector2i(1,2), Vector2i(2,1), Vector2i(2,2)],
	5: [Vector2i(1,1), Vector2i(1,2), Vector2i(2,1), Vector2i(2,2), Vector2i(3,2)],
	6: [Vector2i(1,1), Vector2i(1,2), Vector2i(2,1), Vector2i(2,2), Vector2i(3,1), Vector2i(3,2)],
}

var width := 1
var height := 1
# 
func _ready() -> void:
	pass 

#负责管各种input（左键按住拖动和右键旋转）
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		#左键按住
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				if mouse_inside_gaze():
					dragging = true
					drag_offset = get_global_mouse_position() - get_top_left()
					get_viewport().set_input_as_handled()
			else:
				dragging = false
		#右键点击旋转
		if mouse.button_index == MOUSE_BUTTON_RIGHT and mouse.pressed:
			if mouse_inside_gaze():
				rotate_90()
				get_viewport().set_input_as_handled()
			
	elif event is InputEventMouseMotion:
		if dragging:
			var target := get_global_mouse_position() - drag_offset

#判断鼠标是否在凝视范围里
func mouse_inside_gaze() -> bool:
	var mousePos := get_global_mouse_position() - get_top_left()
	#防止0到-1的小数
	if mousePos.x < 0 or mousePos.y < 0:
		return false
	#得到mouse的position处在哪个格子
	var mouseXPosGridFromTopLeft := int(floor(mousePos.x/grid_size))
	var mouseYPosGridFromTopLeft := int(floor(mousePos.y/grid_size))
	#节省算力，先粗略检测
	if mouseXPosGridFromTopLeft < 0 or mouseYPosGridFromTopLeft < 0 or mouseXPosGridFromTopLeft > width or mouseYPosGridFromTopLeft > height:
		return false
	#精确检测，判断在格子里
	return Vector2i(mouseXPosGridFromTopLeft, mouseYPosGridFromTopLeft) in gaze
	
func get_top_left() -> Vector2:
	var size_px := get_pixel_size()
	return global_position - size_px * 0.5

func set_top_left() -> Vector2:
	

func get_pixel_size() -> Vector2:
	return Vector2(float(width * grid_size), float(height * grid_size))

func rotate_90() -> void:
	rotation_degree = (rotation_degree + 1) % 4
	refresh_shape()
	_update_sprite_offset()
	
	


func refresh_shape() -> void:
	var base_1based: Array[Vector2i] = shape.get(level, []) 
	var base := normalize_to_0based(base_1based)
	apply_rotation_from_base(base)
	
func normalize_to_0based(cells_1based: Array[Vector2i]) -> Array[Vector2i]:
	# 输入是 1-based 且只是形状描述，我们要：
	# 1) 先整体减1 -> 0-based
	# 2) 再把最小 x/y 平移到 0（保证形状左上从(0,0)开始）
	var tmp: Array[Vector2i] = []
	var min_x := INF
	var min_y := INF
	for c in cells_1based:
		var z := c - Vector2i.ONE
		tmp.append(z)
		min_x = mini(min_x, z.x)
		min_y = mini(min_y, z.y)
	var out: Array[Vector2i] = []
	for z in tmp:
		out.append(Vector2i(z.x - min_x, z.y - min_y))
	return out

func apply_rotation_from_base(base_cells: Array[Vector2i]) -> void:
	# 先算 base 的width和height
	var max_x := 0
	var max_y := 0
	for c in base_cells:
		max_x = maxi(max_x, c.x)
		max_y = maxi(max_y, c.y)
	var bw := max_x + 1
	var bh := max_y + 1
	var out: Array[Vector2i] = []
	for c in base_cells:
		var x := c.x
		var y := c.y
		var rx := x
		var ry := y
		match rotation_degree:
			0:
				rx = x; ry = y
				width = bw; height = bh
			1: # 90° CW: (x,y)->(h-1-y, x)
				rx = bh - 1 - y
				ry = x
				width = bh; height = bw
			2: # 180°
				rx = bw - 1 - x
				ry = bh - 1 - y
				width = bw; height = bh
			3: # 270° CW
				rx = y
				ry = bw - 1 - x
				width = bh; height = bw
		out.append(Vector2i(rx, ry))
	gaze = out

func _update_sprite_offset() -> void:
	# Sprite2D centered=false，所以它 position 是“绘制左上角”
	# 我们要让 Node2D 的原点始终在“包围盒中心”，这样旋转好用
	var size_px := get_pixel_size()
	sprite.position = -size_px * 0.5
