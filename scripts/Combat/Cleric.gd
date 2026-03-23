class_name Cleric
extends Unit_General

@export var heal_amount: float = 30.0

var _debug_timer: float = 0.0
var _is_healing: bool = false

func _on_ready_override() -> void:
	faction = Faction.PLAYER
	add_to_group("player_units")
	attack_preference = AttackPreference.LOWEST_HP

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	attack_timer -= delta
	_debug_timer -= delta
	current_target = _find_heal_target()

	if current_target and _in_attack_range(current_target):
		velocity = Vector2.ZERO
		if attack_timer <= 0.0 and not _is_healing:
			attack_timer = ATTACK_INTERVAL
			_do_heal(current_target)
		elif not _is_healing:
			_play_anim("idle")
		if _debug_timer <= 0.0:
			_debug_timer = 1.0
			print("[%s] 在射程内 attack_timer:%.2f 目标:%s hp:%.1f" % [name, attack_timer, current_target.name, current_target.current_hp])
	else:
		if _debug_timer <= 0.0:
			_debug_timer = 1.0
			print("[%s] 没有目标或不在射程内" % name)
		_move_toward_target(delta)
		if velocity.length() > 0:
			_play_anim("walk")
		else:
			_play_anim("idle")

	if anim and velocity.x != 0:
		anim.flip_h = velocity.x < 0

	move_and_slide()

func _find_heal_target() -> Unit_General:
	var allies: Array[Unit_General] = []
	for node in get_tree().get_nodes_in_group("player_units"):
		if node is Unit_General and not node.is_dead and node != self:
			if node.current_hp < node.max_hp:
				allies.append(node)
	if allies.is_empty():
		return null
	allies.sort_custom(func(a, b): return a.current_hp < b.current_hp)
	return allies[0]

func _do_heal(target: Unit_General) -> void:
	_is_healing = true
	if anim:
		anim.play("heal")
		await anim.animation_finished
	print("valid:%s dead:%s" % [is_instance_valid(target), target.is_dead if is_instance_valid(target) else "N/A"])
	if is_instance_valid(target) and not target.is_dead:
		target.current_hp = minf(target.current_hp + heal_amount, target.max_hp)
		if target.hp_bar:
			target.hp_bar.value = target.current_hp
		print("[%s] 治疗成功 +%.1f 目标血量:%.1f/%.1f" % [name, heal_amount, target.current_hp, target.max_hp])
	_is_healing = false
