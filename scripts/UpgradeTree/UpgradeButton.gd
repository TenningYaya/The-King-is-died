@tool
class_name UpgradeButton
extends Button

@export_enum("attack_1", "attack_2", "attack_3", "hp_1", "hp_2", "hp_3", "resource_speed_1", "resource_speed_2", "resource_amount_1", "resource_amount_2") var upgrade_key: String = "attack_1":
	set(v):
		upgrade_key = v
		if Engine.is_editor_hint():
			_sync_from_key()

@export var required_button_path: NodePath = NodePath()
@export var max_level: int = 5
@export var flat_per_level: float = 0.0
@export var percent_per_level: float = 0.0

@onready var level_label: Label = get_node_or_null("LevelLabel")
@onready var desc_label: Label = get_node_or_null("DescLabel")

var required_button: UpgradeButton = null

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if required_button_path != NodePath():
		required_button = get_node_or_null(required_button_path) as UpgradeButton
	pressed.connect(_on_pressed)
	refresh()

func _sync_from_key() -> void:
	var defs := {
		"attack_1":          [5, 5.0,  0.0],
		"attack_2":          [5, 10.0, 0.0],
		"attack_3":          [5, 0.0,  0.05],
		"hp_1":              [5, 20.0, 0.0],
		"hp_2":              [5, 40.0, 0.0],
		"hp_3":              [5, 0.0,  0.05],
		"resource_speed_1":  [5, 0.0,  0.1],
		"resource_speed_2":  [5, 0.0,  0.2],
		"resource_amount_1": [5, 1.0,  0.0],
		"resource_amount_2": [5, 2.0,  0.0],
	}
	if defs.has(upgrade_key):
		var d: Array = defs[upgrade_key]
		max_level = d[0]
		flat_per_level = d[1]
		percent_per_level = d[2]
		notify_property_list_changed()

func refresh() -> void:
	if upgrade_key == "" or not UpgradeManager.UPGRADE_DEFS.has(upgrade_key):
		return

	var def: Dictionary = UpgradeManager.UPGRADE_DEFS[upgrade_key]
	var lvl: int = UpgradeManager.levels.get(upgrade_key, 0)

	if level_label:
		level_label.text = "%d / %d" % [lvl, max_level]
	if desc_label:
		desc_label.text = def.get("description", "")

	var unlocked := true
	if required_button != null:
		unlocked = UpgradeManager.levels.get(required_button.upgrade_key, 0) >= 1

	var maxed := lvl >= max_level

	if not unlocked:
		disabled = true
		modulate = Color(0.5, 0.5, 0.5)
		if desc_label:
			desc_label.text = "需要先满级：" + required_button.text
	elif maxed:
		disabled = true
		modulate = Color(1.0, 0.85, 0.0)
	else:
		disabled = false
		modulate = Color.WHITE

func _on_pressed() -> void:
	if upgrade_key == "":
		return
	var lvl: int = UpgradeManager.levels.get(upgrade_key, 0)
	if lvl < max_level:
		UpgradeManager.levels[upgrade_key] += 1
		UpgradeManager.save_upgrades()
		for btn in get_tree().get_nodes_in_group("upgrade_buttons"):
			var ub := btn as UpgradeButton
			if ub != null:
				ub.refresh()
