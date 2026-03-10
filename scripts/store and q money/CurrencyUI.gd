# CurrencyUI.gd
extends Label

func _ready() -> void:
	# 1. 初始显示当前拥有的货币（从全局单例读取）
	_update_display(ResourceManager.special_currency)
	
	# 2. 链接信号：当货币变动时，自动更新文字
	ResourceManager.special_currency_changed.connect(_update_display)

func _update_display(new_amount: int) -> void:
	# 只显示数字，因为图标已经在左边了
	text = str(new_amount)
