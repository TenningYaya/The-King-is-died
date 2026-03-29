extends CanvasLayer

# 绑定UI节点
@onready var text_label = $DialogueBox/TextLabel
@onready var dialogue_box = $DialogueBox
@onready var tutorial_image = $TutorialImage
@onready var skip_button = $SkipButton
@onready var click_btn = $ClickAnywhereBtn
@onready var npc_figure = $DialogueBox/NPCFigure

# 【新增】导出变量，让你可以在右侧面板直接把图片拖进来！
@export var portrait_sect_master: Texture2D # 掌门的立绘
@export var portrait_narrator: Texture2D    # 旁白的图片 (比如一个卷轴图标，或者干脆空着)

# 台词数据
var dialogue_lines = [
	{"speaker": "Sect Master", "text": "Ancestor! Wake up, the world has turned upside down!"},
	{"speaker": "Sect Master", "text": "I know you commanded us never to disturb your sacred seclusion unless the situation was dire..."},
	{"speaker": "Sect Master", "text": "Yet recently, Malevolent Qi erupted from the East. Without the sect, nothing lives. The land is barren."},
	{"speaker": "Sect Master", "text": "This is a battle for our very survival. I have transmitted all details regarding the sect through Divine Sense to you."},
	{"speaker": "IMAGE", "text": ""}, # 触发新手引导图
	{"speaker": "Sect Master", "text": "Please, Ancestor, we all await your decree!"},
	{"speaker": "Narrator", "text": "You can press ESC at any time and click on 'Controls' to review this beautiful guide."},
	{"speaker": "Narrator", "text": "You have now totally mastered the game. Go save the world!"}
]

var current_index = 0

func _ready():
	GamedataManager.is_tutorial_active = true
	# 暂停游戏时间线
	get_tree().paused = true
	
	# 绑定点击事件
	skip_button.pressed.connect(end_tutorial)
	click_btn.pressed.connect(next_line)
	
	# 初始化
	tutorial_image.hide()
	npc_figure.hide()
	show_dialogue()

func show_dialogue():
	if current_index >= dialogue_lines.size():
		end_tutorial()
		return
		
	var line_data = dialogue_lines[current_index]
	
	# 检测是否到了展示教程图片的环节
	if line_data["speaker"] == "IMAGE":
		dialogue_box.hide()
		npc_figure.hide() # 【新增】展示引导图时，隐藏立绘
		tutorial_image.show()
	else:
		# 正常对话环节
		tutorial_image.hide()
		dialogue_box.show()
		npc_figure.show() # 【新增】显示立绘
		text_label.text = line_data["text"]
		
		# 【新增】根据说话人，切换对应的立绘图片
		if line_data["speaker"] == "Sect Master":
			npc_figure.texture = portrait_sect_master
		elif line_data["speaker"] == "Narrator":
			npc_figure.texture = portrait_narrator

func next_line():
	current_index += 1
	show_dialogue()

func end_tutorial():
	GamedataManager.is_tutorial_active = false
	# 恢复时间线，销毁引导UI
	get_tree().paused = false
	queue_free()
