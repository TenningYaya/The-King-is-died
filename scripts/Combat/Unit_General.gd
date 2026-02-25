class_name Unit_General
extends CharacterBody2D

# ─────────────────────────────────────────
#  枚举
# ─────────────────────────────────────────
enum Faction { PLAYER, ENEMY }
enum AttackType { SINGLE, AOE }
enum AttackPreference { NEAREST, LOWEST_HP, HIGHEST_HP, FRONTMOST }

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
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var attack_area: Area2D = $AttackArea          # 检测射程内敌人

# ─────────────────────────────────────────
#  初始化
# ─────────────────────────────────────────
func _ready() -> void:
	current_hp = max_hp
	_setup_attack_area()
	_on_ready_override()   # 供子类扩展

func _setup_attack_area() -> void:
	# 动态设置 AttackArea 的碰撞圆半径 = attack_range
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
		# 在射程内：停止移动，尝试攻击
		velocity = Vector2.ZERO
		if attack_timer <= 0.0:
			attack_timer = ATTACK_INTERVAL
			_perform_attack(current_target)
	else:
		# 不在射程内：向目标移动
		_move_toward_target(delta)

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
	velocity = (next_pos - global_position).normalized() * move_speed

# ─────────────────────────────────────────
#  目标搜索
# ─────────────────────────────────────────
func _find_target() -> Unit_General:
	var enemies := _get_enemies_in_scene()
	if enemies.is_empty():
		return null
	return _apply_preference(enemies)

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
		_fire_projectile(target)
	else:
		_melee_attack(target)
	_on_attack_override(target)   # 供子类扩展

func _melee_attack(target: Unit_General) -> void:
	match attack_type:
		AttackType.SINGLE:
			target.take_damage(attack_damage)
		AttackType.AOE:
			_deal_aoe_damage()

func _deal_aoe_damage() -> void:
	for unit in _get_enemies_in_scene():
		if global_position.distance_to(unit.global_position) <= attack_aoe_radius:
			unit.take_damage(attack_damage)

func _fire_projectile(target: Unit_General) -> void:
	# 弹体逻辑由单独脚本处理，此处仅实例化并传递目标
	var proj = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	if proj.has_method("init"):
		proj.init(target, attack_damage, faction)

# ─────────────────────────────────────────
#  受伤 / 死亡
# ─────────────────────────────────────────
func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_hp -= amount
	print("[%s] 受到 %.1f 伤害，剩余血量：%.1f / %.1f" % [name, amount, current_hp, max_hp])
	_on_damage_override(amount)
	if current_hp <= 0.0:
		_die()

func _die() -> void:
	is_dead = true
	print("[%s] 已死亡" % name)
	_on_death_override()
	queue_free()

# ─────────────────────────────────────────
#  子类扩展钩子（override 这些而不是覆盖核心方法）
# ─────────────────────────────────────────
func _on_ready_override() -> void: pass
func _on_attack_override(_target: Unit_General) -> void: pass
func _on_damage_override(_amount: float) -> void: pass
func _on_death_override() -> void: pass
