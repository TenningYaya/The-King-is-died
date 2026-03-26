# main_menu_button.gd
extends TextureButton

# 1. 【修正重点】@onready 必须在 var 之前，且后面要跟具体的路径 $Label
@onready var label_node = $Label

# 2. 这是暴露在 Inspector 里的“传音筒”
@export var button_text: String = "新游戏":
	set(value):
		button_text = value
		# 如果场景还没进入树（比如刚在编辑器里摆放），label_node 还是空的
		# 所以我们要加一个判断，防止它“走火入魔”崩溃
		if is_node_ready():
			label_node.text = value

func _ready():
	# 当按钮真正出生（进入场景）时，把预设的字刻上去
	label_node.text = button_text
