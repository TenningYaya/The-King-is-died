extends Control

func start_animation(icon_tex: Texture2D, amount: int, target_y_offset: float):
	$Icon.texture = icon_tex
	$AmountLabel.text = str(amount)
	
	# 创建 Tween 动画
	var tween = create_tween()
	# 设定为并行执行（位置和透明度同时变化）
	tween.set_parallel(true)
	
	# 1. 向上偏移动画（目标是建筑的顶部）
	tween.tween_property(self, "position:y", position.y - target_y_offset, 1.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 2. 虚化动画（透明度从 1 到 0）
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	
	# 3. 动画结束后自动销毁
	tween.chain().tween_callback(queue_free)
