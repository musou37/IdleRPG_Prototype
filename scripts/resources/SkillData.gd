class_name SkillData
extends Resource

enum Category { BERSERK, IRON_GUARD, TACTICS }
enum SkillType {
	ACTIVE_DAMAGE,
	ACTIVE_HEAL,
	PASSIVE_ATK,
	PASSIVE_ASPD,
	PASSIVE_CRIT,
	PASSIVE_BLOCK
}

@export var id: String = ""
@export var skill_name: String = "未命名技能"
@export var description: String = ""
@export var category: Category = Category.BERSERK
@export var skill_type: SkillType = SkillType.ACTIVE_DAMAGE
@export var required_level: int = 1 # 學習此技能所需的勇者最低等級
@export var level: int = 0 # 0 代表尚未學習
@export var cooldown: float = 5.0
@export var base_value: float = 1.5 # 基礎值 (或最小倍率)
@export var max_value: float = 2.5 # 最大倍率 (用於浮動傷害技能，如魯莽 150%~250%)
@export var growth_per_level: float = 0.25
@export var base_cost: int = 1
var points_spent: int = 0

var current_cd: float = 0.0

func is_learned() -> bool:
	return level > 0

func is_active_skill() -> bool:
	return skill_type == SkillType.ACTIVE_DAMAGE or skill_type == SkillType.ACTIVE_HEAL

func get_category_name() -> String:
	match category:
		Category.BERSERK: return "🔥 狂暴系"
		Category.IRON_GUARD: return "🛡️ 鐵衛系"
		Category.TACTICS: return "⚡ 戰術系"
	return "未知"

func get_category_color() -> Color:
	match category:
		Category.BERSERK: return Color(1.0, 0.45, 0.35)
		Category.IRON_GUARD: return Color(0.35, 0.85, 0.55)
		Category.TACTICS: return Color(0.35, 0.78, 1.0)
	return Color.WHITE

func get_effect_value() -> float:
	if level <= 0:
		return 0.0
	return base_value + (level - 1) * growth_per_level

func get_max_effect_value() -> float:
	if level <= 0:
		return 0.0
	return max_value + (level - 1) * growth_per_level

func roll_damage_multiplier() -> float:
	if level <= 0:
		return 1.0
	return randf_range(get_effect_value(), get_max_effect_value())

func get_upgrade_cost() -> int:
	return base_cost

func get_display_desc() -> String:
	var val := get_effect_value() if level > 0 else base_value
	var prefix := ("[未學習 | 需 Lv.%d] " % required_level) if level == 0 else ("Lv.%d " % level)
	match skill_type:
		SkillType.ACTIVE_DAMAGE:
			var min_pct := (get_effect_value() if level > 0 else base_value) * 100.0
			var max_pct := (get_max_effect_value() if level > 0 else max_value) * 100.0
			return "%s每 %.1f 秒造成 %.0f%%~%.0f%% 攻擊傷害" % [prefix, cooldown, min_pct, max_pct]
		SkillType.ACTIVE_HEAL:
			return "%s每 %.1f 秒回復 %.1f%% 最大生命 (每級+0.5%%)" % [prefix, cooldown, val * 100.0]
		SkillType.PASSIVE_ATK:
			return "%s被動提升 %.0f%% 總攻擊力" % [prefix, val * 100.0]
		SkillType.PASSIVE_ASPD:
			return "%s被動提升 %.0f%% 攻擊速度" % [prefix, val * 100.0]
		SkillType.PASSIVE_CRIT:
			return "%s被動提升 %.0f%% 暴擊傷害 (每級+5%%)" % [prefix, val * 100.0]
		SkillType.PASSIVE_BLOCK:
			return "%s受擊時有 %.0f%% 機率格檔，減免 30%% 傷害 (每級+1%%機率)" % [prefix, val * 100.0]
	return description

func to_dict() -> Dictionary:
	return {
		"id": id,
		"level": level,
		"points_spent": points_spent
	}

func apply_dict(d: Dictionary) -> void:
	level = int(d.get("level", level))
	points_spent = int(d.get("points_spent", points_spent))
	current_cd = 0.0

