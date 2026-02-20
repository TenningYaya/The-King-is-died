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
var rotation := 0

var gaze: Array[Vector2i]
# 
func _ready() -> void:
	pass 

#负责管各种input（左键按住拖动和右键旋转）
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		#左键按住拖动逻辑
		if mouse.pressed:
			

#判断鼠标是否在凝视范围里
func mouse_inside_gaze() -> bool:
	var mousePos := get_global_mouse_position()
	var top :=
