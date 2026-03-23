class_name Unit_General
extends CharacterBody2D

# ─────────────────────────────────────────
#  枚举
# ─────────────────────────────────────────
enum Faction { PLAYER, ENEMY }
enum AttackType { SINGLE, AOE }
enum AttackPreference { NEAREST, LOWEST_HP, HIGHEST_HP, FRONTMOST, STRUCTURE }

# ─────────────────────────────────────────
#  基础数值（在子类中用 @export 覆盖）
# ─────────────────────────────────────────
@export var faction: Faction = Faction.PLAYER

@export_group("战斗数值")
@export var max_hp: float = 100.0
@export var attack_damage: float = 10.0
@export var attack_range: float = 60.0          # 进入此范围后停止移动并攻击
@export var attack_aoe_radius: float = 0.0      # AOE 半径，0 = 单体
@export var attack_type: AttackType = AttackType.SINGLE
@export var attack_preference: AttackPreference = AttackPreference.NEAREST
@export var projectile_scene: PackedScene = null # 非空则发射弹体

@export_group("移动")
@export var move_speed: float = 80.0
var creator_building_name: String = ""

# ─────────────────────────────────────────
#  全局共享攻击速度（可在 ProjectSettings 或 Autoload 里统一管理）
# ─────────────────────────────────────────
const ATTACK_INTERVAL: float = 0.5             # 0.5s = 2次/s

# ─────────────────────────────────────────
#  运行时状态
# ─────────────────────────────────────────
var current_hp: float
var attack_timer: float = 0.0
var current_target: Unit_General = null
var is_dead: bool = false

# ─────────────────────────────────────────
#  节点引用（子类场景里需有对应节点名）
# ─────────────────────────────────────────
@onready var nav_agent: NavigationAgent2D = get_node_or_null("NavigationAgent2D")
@onready var attack_area: Area2D = get_node_or_null("AttackArea")
@onready var hp_bar: ProgressBar = get_node_or_null("ProgressBar")
@onready var anim: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

# ─────────────────────────────────────────
#  初始化
# ─────────────────────────────────────────
func _ready() -> void:
	_setup_attack_area()
	_on_ready_override()
	_apply_upgrades()
	current_hp = max_hp
	_setup_hp_bar()

func _apply_upgrades() -> void:
	if faction != Faction.PLAYER:
		return
	attack_damage = UpgradeManager.apply("attack_1", "attack_3", attack_damage)
	attack_damage += UpgradeManager.get_flat("attack_2")
	max_hp = UpgradeManager.apply("hp_1", "hp_3", max_hp)
	max_hp += UpgradeManager.get_flat("hp_2")

func _setup_hp_bar() -> void:
	if hp_bar == null:
		return
	hp_bar.max_value = max_hp
	hp_bar.value = max_hp
	# 友方绿色，敌方红色
	var style := StyleBoxFlat.new()
	style.bg_color = Color.GREEN if faction == Faction.PLAYER else Color.RED
	hp_bar.add_theme_stylebox_override("fill", style)

func _setup_attack_area() -> void:
	if attack_area == null:
		return
	var shape := attack_area.get_node("CollisionShape2D") as CollisionShape2D
	if shape and shape.shape is CircleShape2D:
		(shape.shape as CircleShape2D).radius = attack_range

# ─────────────────────────────────────────
#  主循环
# ─────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	attack_timer -= delta

	current_target = _find_target()
	var dist = global_position.distance_to(current_target.global_position) if current_target else -1.0
	var in_range = _in_attack_range(current_target) if current_target else false
	print("[%s] 目标:%s 距离:%.1f 射程:%.1f 在射程内:%s attack_timer:%.2f" % [name, current_target, dist, attack_range, in_range, attack_timer])

	if current_target and _in_attack_range(current_target):
		velocity = Vector2.ZERO
		if attack_timer <= 0.0:
			attack_timer = ATTACK_INTERVAL
			_play_anim("attack")
			_perform_attack(current_target)
		elif not _is_playing("attack"):
			_play_anim("idle")
	else:
		_move_toward_target(delta)
		if velocity.length() > 0:
			_play_anim("walk")
		else:
			_play_anim("idle")

	# 根据移动方向翻转sprite
	if anim and velocity.x != 0:
		anim.flip_h = velocity.x < 0

	move_and_slide()

# ─────────────────────────────────────────
#  寻路移动
# ─────────────────────────────────────────
func _move_toward_target(_delta: float) -> void:
	if current_target == null:
		velocity = Vector2.ZERO
		return
	nav_agent.target_position = current_target.global_position
	var next_pos: Vector2 = nav_agent.get_next_path_position()
	print("[%s] 当前位置:%s 目标位置:%s 下一步:%s 速度:%s" % [name, global_position, current_target.global_position, next_pos, velocity])
	velocity = (next_pos - global_position).normalized() * move_speed

# ─────────────────────────────────────────
#  目标搜索
# ─────────────────────────────────────────
func _find_target() -> Unit_General:
	# STRUCTURE 偏好：优先找城墙，找不到再找最近的敌人
	if attack_preference == AttackPreference.STRUCTURE:
		var structures := _get_structures()
		if not structures.is_empty():
			return _get_nearest(structures)
	
	var enemies := _get_enemies_in_scene()
	if enemies.is_empty():
		return null
	return _apply_preference(enemies)

func _get_structures() -> Array[Unit_General]:
	var result: Array[Unit_General] = []
	for node in get_tree().get_nodes_in_group("structures"):
		if node is Unit_General and not node.is_dead:
			result.append(node)
	return result

func _get_nearest(candidates: Array[Unit_General]) -> Unit_General:
	var nearest: Unit_General = null
	var min_dist := INF
	for u in candidates:
		var d := global_position.distance_to(u.global_position)
		if d < min_dist:
			min_dist = d
			nearest = u
	return nearest

func _get_enemies_in_scene() -> Array[Unit_General]:
	# 遍历场景中所有 Unit_General，筛选敌对阵营且未死亡的单位
	var result: Array[Unit_General] = []
	for node in get_tree().get_nodes_in_group(_enemy_group()):
		if node is Unit_General and not node.is_dead:
			result.append(node)
	return result

func _enemy_group() -> String:
	return "enemy_units" if faction == Faction.PLAYER else "player_units"

func _apply_preference(candidates: Array[Unit_General]) -> Unit_General:
	match attack_preference:
		AttackPreference.NEAREST:
			candidates.sort_custom(func(a, b): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
		AttackPreference.LOWEST_HP:
			candidates.sort_custom(func(a, b): return a.current_hp < b.current_hp)
		AttackPreference.HIGHEST_HP:
			candidates.sort_custom(func(a, b): return a.current_hp > b.current_hp)
		AttackPreference.FRONTMOST:
			# 根据阵营决定"最前"方向，Player 单位取 x 最大，Enemy 取 x 最小
			var sign_val := 1 if faction == Faction.PLAYER else -1
			candidates.sort_custom(func(a, b): return a.global_position.x * sign_val > b.global_position.x * sign_val)
	return candidates[0]

# ─────────────────────────────────────────
#  射程判断
# ─────────────────────────────────────────
func _in_attack_range(target: Unit_General) -> bool:
	return global_position.distance_to(target.global_position) <= attack_range

# ─────────────────────────────────────────
#  攻击执行
# ─────────────────────────────────────────
func _perform_attack(target: Unit_General) -> void:
	print("[%s] 攻击 [%s]，目标剩余血量：%.1f" % [name, target.name, target.current_hp])
	if projectile_scene:
		_fire_projectile(target)  # 纯视觉
	_melee_attack(target)  # 伤害始终在这里结算
	_on_attack_override(target)

func _melee_attack(target: Unit_General) -> void:
	match attack_type:
		AttackType.SINGLE:
			target.take_damage(attack_damage)
		AttackType.AOE:
			_deal_aoe_damage(target.global_position)

func _deal_aoe_damage(center: Vector2) -> void:
	var hit_count := 0
	for unit in _get_enemies_in_scene():
		var d := center.distance_to(unit.global_position)
		print("[AOE] 检测单位:%s 距离:%.1f 半径:%.1f" % [unit.name, d, attack_aoe_radius])
		if d <= attack_aoe_radius:
			unit.take_damage(attack_damage)
			hit_count += 1
	print("[AOE] 共命中 %d 个单位" % hit_count)

func _fire_projectile(target: Unit_General) -> void:
	if projectile_scene == null:
		push_error("[%s] projectile_scene 为空" % name)
		return
	var proj = projectile_scene.instantiate()
	if proj == null:
		push_error("[%s] 弹体实例化失败" % name)
		return
	print("[%s] 弹体类型: %s" % [name, proj.get_class()])
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	if proj.has_method("init"):
		proj.init(target, attack_damage, faction)
	else:
		push_error("[%s] 弹体没有 init 方法" % name)

# ─────────────────────────────────────────
#  受伤 / 死亡
# ─────────────────────────────────────────
func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_hp -= amount
	if hp_bar:
		hp_bar.value = current_hp
	print("[%s] 受到 %.1f 伤害，剩余血量：%.1f / %.1f" % [name, amount, current_hp, max_hp])
	_on_damage_override(amount)
	if current_hp <= 0.0:
		_die()

func _die() -> void:
	is_dead = true
	print("[%s] 已死亡" % name)
	_play_anim("death")
	_on_death_override()
	# 等死亡动画播完再删除
	if anim:
		await anim.animation_finished
	queue_free()

# ─────────────────────────────────────────
#  动画辅助
# ─────────────────────────────────────────
func _play_anim(anim_name: String) -> void:
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation(anim_name):
		if anim.animation != anim_name:
			anim.play(anim_name)

func _is_playing(anim_name: String) -> bool:
	return anim != null and anim.animation == anim_name and anim.is_playing()

# ─────────────────────────────────────────
#  子类扩展钩子（override 这些而不是覆盖核心方法）
# ─────────────────────────────────────────
func _on_ready_override() -> void: pass
func _on_attack_override(_target: Unit_General) -> void: pass
func _on_damage_override(_amount: float) -> void: pass
func _on_death_override() -> void: pass
