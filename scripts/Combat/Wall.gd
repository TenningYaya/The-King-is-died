class_name Wall
extends Unit_General

# --- 节点引用 ---
@onready var shield_anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hp_label: Label = $Sprite2D/HPLabel
var is_playing_hit: bool = false

func _on_ready_override() -> void:
	faction = Faction.PLAYER
	add_to_group("player_units")
	add_to_group("structures")
	max_hp = 100000000
	current_hp = max_hp
	
	if shield_anim:
		shield_anim.animation_finished.connect(_on_animation_finished)
		shield_anim.visible = true
		shield_anim.rotation_degrees = 0
		shield_anim.play("birth")
	
	_update_hp_ui()

# --- 受击逻辑优化 ---
func take_damage(amount: float) -> void:
	current_hp -= amount
	_update_hp_ui()
	
	if shield_anim:
		# 【关键判断】如果当前正在播 hit，且还没播完，就不要重新播放
		# 这样能保证每一次闪烁动画都是完整的
		if not is_playing_hit:
			is_playing_hit = true
			shield_anim.visible = true
			shield_anim.rotation_degrees = 180
			
			shield_anim.offset = Vector2(-30, -25)
			
			shield_anim.play("hit")
	
	if current_hp <= 0:
		_on_death_override()

# --- 动画结束回调 ---
func _on_animation_finished() -> void:
	if shield_anim.animation == "hit":
		# 只有当 hit 真正播完时，才释放状态锁
		is_playing_hit = false
		shield_anim.visible = false
		shield_anim.rotation_degrees = 0
		
		shield_anim.offset = Vector2.ZERO
		shield_anim.rotation_degrees = 0
	
	elif shield_anim.animation == "birth":
		shield_anim.visible = false
		shield_anim.rotation_degrees = 0

# --- UI 更新 ---
func _update_hp_ui() -> void:
	if hp_label:
		# 1. 先用 ceil 向上取整 (返回 float)
		# 2. 再用 int() 强转为整数 (去掉 .0)
		# 3. 最后转为 str 赋值给 Label
		hp_label.text = str(int(ceil(current_hp)))

# --- 覆盖逻辑 ---
func _physics_process(_delta: float) -> void:
	# 完全覆盖父类逻辑，城墙坚如磐石，原地不动
	pass

func _on_death_override() -> void:
	# 城墙破，宗门灭
	get_tree().change_scene_to_file("res://Scene/system/gameover_lose.tscn")
