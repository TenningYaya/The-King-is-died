#对于5*5的完整地块，本script统一称为field。
#对于每个单独格子，本script统一称为grid。
extends Node2D
class_name GazeController

#设置grid，大小，整个field
const grid_size := 120
const field_grid := 5
const field_size := 600

#资源文件夹
@export var gaze_folder := "res://ArtAssets/Gaze/"

@onready var sprite: Sprite2D = $Sprite2D

var grid_count : int
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
		#左键按住拖动逻辑
		if mouse.pressed:
			if mouse_inside_gaze():
				dragging = true
				drag_offset = get_global_mouse_position() - get_top_left()
				get_viewport().set_input_as_handled()
		else:
			dragging = false
			

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

func get_pixel_size() -> Vector2:
	return Vector2(float(width * grid_size), float(height * grid_size))
