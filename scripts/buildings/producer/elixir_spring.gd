#elixir_spring.gd
extends ProducerBuilding
class_name ElixirSpring

func _on_cycle_complete():
	super._on_cycle_complete() # 先执行父类的产出逻辑
	# 在这里可以添加麦田特有的表现，比如播放音效
