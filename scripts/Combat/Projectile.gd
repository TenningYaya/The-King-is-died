class_name Projectile
extends Area2D

# ─────────────────────────────────────────
#  配置
# ─────────────────────────────────────────
@export var speed: float = 300.0

# ─────────────────────────────────────────
#  运行时状态
# ─────────────────────────────────────────
var target: Unit_General = null
var damage: float = 0.0
var faction: Unit_General.Faction

# ─────────────────────────────────────────
#  初始化（由 Unit_General._fire_projectile 调用）
# ─────────────────────────────────────────
func init(t: Unit_General, dmg: float, f: Unit_General.Faction) -> void:
	target = t
	damage = dmg
	faction = f

# ─────────────────────────────────────────
#  主循环
# ─────────────────────────────────────────
func _physics_process(delta: float) -> void:
	# 目标死亡或不存在时销毁弹体
	if not is_instance_valid(target) or target.is_dead:
		queue_free()
		return

	# 追踪目标移动
	var dir := (target.global_position - global_position).normalized()
	global_position += dir * speed * delta

	# 旋转朝向目标
	rotation = dir.angle()

	# 到达目标时造成伤害
	if global_position.distance_to(target.global_position) < 10.0:
		target.take_damage(damage)
		queue_free()
