class_name SkillData
extends Resource

enum SkillType { ACTIVE_DAMAGE, ACTIVE_HEAL, PASSIVE_ATK, PASSIVE_ASPD }

@export var id: String = ""
@export var skill_name: String = "未命名技能"
@export var description: String = ""
@export var skill_type: SkillType = SkillType.ACTIVE_DAMAGE
@export var level: int = 0 # 0 代表尚未學習
@export var cooldown: float = 5.0
@export var base_value: float = 2.0 # 倍率或固定加成
@export var growth_per_level: float = 0.35
@export var base_cost: int = 30

var current_cd: float = 0.0

func is_learned() -> bool:
	return level > 0

func is_active_skill() -> bool:
	return skill_type == SkillType.ACTIVE_DAMAGE or skill_type == SkillType.ACTIVE_HEAL

func get_effect_value() -> float:
	if level <= 0:
		return 0.0
	return base_value + (level - 1) * growth_per_level

func get_upgrade_cost() -> int:
	return int(base_cost * pow(1.6, level))

func get_display_desc() -> String:
	var val := get_effect_value() if level > 0 else base_value
	var prefix := "[未學習] " if level == 0 else "Lv.%d " % level
	match skill_type:
		SkillType.ACTIVE_DAMAGE:
			return "%s每 %.1f 秒造成 %.0f%% 攻擊傷害" % [prefix, cooldown, val * 100.0]
		SkillType.ACTIVE_HEAL:
			return "%s每 %.1f 秒回復 %.0f%% 最大生命" % [prefix, cooldown, val * 100.0]
		SkillType.PASSIVE_ATK:
			return "%s被動提升 %.0f%% 總攻擊力" % [prefix, val * 100.0]
		SkillType.PASSIVE_ASPD:
			return "%s被動提升 %.0f%% 攻擊速度" % [prefix, val * 100.0]
	return description
