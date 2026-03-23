extends Node

const SAVE_PATH := "user://upgrades.cfg"

const UPGRADE_DEFS := {
	"attack_1": {
		"label": "攻击力强化 I",
		"description": "每级提升 +5 攻击力",
		"flat_per_level": 5.0,
		"percent_per_level": 0.0,
		"max_level": 5,
		"cost_base": 100,
		"cost_growth": 50,
		"requires": ""
	},
	"attack_2": {
		"label": "攻击力强化 II",
		"description": "每级提升 +10 攻击力",
		"flat_per_level": 10.0,
		"percent_per_level": 0.0,
		"max_level": 5,
		"cost_base": 150,
		"cost_growth": 75,
		"requires": "attack_1"
	},
	"attack_3": {
		"label": "攻击力精通",
		"description": "每级提升 +5% 攻击力",
		"flat_per_level": 0.0,
		"percent_per_level": 0.05,
		"max_level": 5,
		"cost_base": 200,
		"cost_growth": 100,
		"requires": "attack_2"
	},
	"hp_1": {
		"label": "生命值强化 I",
		"description": "每级提升 +20 生命值",
		"flat_per_level": 20.0,
		"percent_per_level": 0.0,
		"max_level": 5,
		"cost_base": 100,
		"cost_growth": 50,
		"requires": ""
	},
	"hp_2": {
		"label": "生命值强化 II",
		"description": "每级提升 +40 生命值",
		"flat_per_level": 40.0,
		"percent_per_level": 0.0,
		"max_level": 5,
		"cost_base": 150,
		"cost_growth": 75,
		"requires": "hp_1"
	},
	"hp_3": {
		"label": "生命值精通",
		"description": "每级提升 +5% 生命值",
		"flat_per_level": 0.0,
		"percent_per_level": 0.05,
		"max_level": 5,
		"cost_base": 200,
		"cost_growth": 100,
		"requires": "hp_2"
	},
	"resource_speed_1": {
		"label": "资源加速 I",
		"description": "每级提升 +10% 资源产生速度",
		"flat_per_level": 0.0,
		"percent_per_level": 0.1,
		"max_level": 5,
		"cost_base": 200,
		"cost_growth": 100,
		"requires": ""
	},
	"resource_speed_2": {
		"label": "资源加速 II",
		"description": "每级提升 +20% 资源产生速度",
		"flat_per_level": 0.0,
		"percent_per_level": 0.2,
		"max_level": 5,
		"cost_base": 250,
		"cost_growth": 125,
		"requires": "resource_speed_1"
	},
	"resource_amount_1": {
		"label": "资源丰收 I",
		"description": "每级提升 +1 资源产生数量",
		"flat_per_level": 1.0,
		"percent_per_level": 0.0,
		"max_level": 5,
		"cost_base": 200,
		"cost_growth": 100,
		"requires": "resource_speed_1"
	},
	"resource_amount_2": {
		"label": "资源丰收 II",
		"description": "每级提升 +2 资源产生数量",
		"flat_per_level": 2.0,
		"percent_per_level": 0.0,
		"max_level": 5,
		"cost_base": 250,
		"cost_growth": 125,
		"requires": "resource_amount_1"
	},
}

var levels: Dictionary = {}

func _ready() -> void:
	for key in UPGRADE_DEFS:
		levels[key] = 0
	save_upgrades()  # 临时加这行，重置存档
	load_upgrades()

func is_unlocked(key: String) -> bool:
	var req: String = UPGRADE_DEFS[key]["requires"]
	if req == "":
		return true
	return levels.get(req, 0) >= 1

func is_maxed(key: String) -> bool:
	return levels[key] >= UPGRADE_DEFS[key]["max_level"]

func get_flat(key: String) -> float:
	return UPGRADE_DEFS[key]["flat_per_level"] * levels.get(key, 0)

func get_percent(key: String) -> float:
	return UPGRADE_DEFS[key]["percent_per_level"] * levels.get(key, 0)

func apply(key_flat: String, key_percent: String, base: float) -> float:
	return base * (1.0 + get_percent(key_percent)) + get_flat(key_flat)

func get_cost(key: String) -> int:
	var def: Dictionary = UPGRADE_DEFS[key]
	return def["cost_base"] + def["cost_growth"] * levels[key]

func save_upgrades() -> void:
	var cfg := ConfigFile.new()
	for key in levels:
		cfg.set_value("upgrades", key, levels[key])
	cfg.save(SAVE_PATH)

func load_upgrades() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for key in levels:
		levels[key] = cfg.get_value("upgrades", key, 0)
