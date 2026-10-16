class_name EquipmentData
extends Resource

enum SlotType { WEAPON, ARMOR, SHIELD }
enum Rarity {
	WHITE = 1,   # 普通 (白)
	GREEN = 2,   # 優良 (綠)
	BLUE = 3,    # 稀有 (藍)
	PURPLE = 4,  # 史詩 (紫)
	ORANGE = 5,  # 傳說 (橘)
	RAINBOW = 6  # 神話 (彩虹框)
}

@export var id: String = ""
@export var item_name: String = "未命名裝備"
@export var slot: SlotType = SlotType.WEAPON
@export var level: int = 1
@export var rarity: int = Rarity.WHITE # 1:白, 2:綠, 3:藍, 4:紫, 5:橘, 6:彩虹

@export var base_atk: int = 0
@export var base_hp: int = 0
@export var base_def: int = 0
@export var base_crit_rate: float = 0.0 # 基礎暴擊率加成 (例如 0.03 代表 +3%)
@export var base_crit_dmg: float = 0.0 # 基礎暴擊倍率加成 (例如 0.15 代表 +15% / +0.15x)

func get_rarity_multiplier() -> float:
	match rarity:
		Rarity.WHITE: return 1.0
		Rarity.GREEN: return 1.35
		Rarity.BLUE: return 1.80
		Rarity.PURPLE: return 2.40
		Rarity.ORANGE: return 3.20
		Rarity.RAINBOW: return 4.50
	return 1.0

func get_atk() -> int:
	return int(round(base_atk * (1.0 + (level - 1) * 0.25) * get_rarity_multiplier()))

func get_hp() -> int:
	return int(round(base_hp * (1.0 + (level - 1) * 0.25) * get_rarity_multiplier()))

func get_def() -> int:
	return int(round(base_def * (1.0 + (level - 1) * 0.25) * get_rarity_multiplier()))

func get_crit_rate() -> float:
	if base_crit_rate <= 0.0:
		return 0.0
	return snappedf(base_crit_rate * (1.0 + (level - 1) * 0.12) * (1.0 + (rarity - 1) * 0.20), 0.001)

func get_crit_dmg() -> float:
	if base_crit_dmg <= 0.0:
		return 0.0
	return snappedf(base_crit_dmg * (1.0 + (level - 1) * 0.15) * (1.0 + (rarity - 1) * 0.20), 0.01)

func get_upgrade_cost() -> int:
	return int(round(15 * pow(1.45, level - 1) * get_rarity_multiplier()))

func get_slot_name() -> String:
	match slot:
		SlotType.WEAPON: return "武器"
		SlotType.ARMOR: return "裝甲"
		SlotType.SHIELD: return "盾牌"
	return "未知"

func get_rarity_name() -> String:
	match rarity:
		Rarity.WHITE: return "普通"
		Rarity.GREEN: return "優良"
		Rarity.BLUE: return "稀有"
		Rarity.PURPLE: return "史詩"
		Rarity.ORANGE: return "傳說"
		Rarity.RAINBOW: return "神話"
	return "普通"

func is_rainbow() -> bool:
	return rarity >= Rarity.RAINBOW

func get_rarity_color() -> Color:
	match rarity:
		Rarity.WHITE: return Color(0.88, 0.88, 0.90) # 白
		Rarity.GREEN: return Color(0.35, 0.92, 0.45) # 綠
		Rarity.BLUE: return Color(0.32, 0.68, 1.0)   # 藍
		Rarity.PURPLE: return Color(0.78, 0.42, 1.0) # 紫
		Rarity.ORANGE: return Color(1.0, 0.60, 0.18) # 橘
		Rarity.RAINBOW: return Color(1.0, 0.45, 0.78) # 彩虹代表色 (UI 文字高亮粉金，圖示外框由 IconSlot 繪製動態彩虹框)
		_: return Color(0.88, 0.88, 0.90)

func get_power_score() -> int:
	return (
		get_atk() * 10
		+ get_def() * 12
		+ get_hp() * 2
		+ int(round(get_crit_rate() * 100.0)) * 18
		+ int(round(get_crit_dmg() * 100.0)) * 6
	)

func get_summary_text() -> String:
	var parts: Array[String] = []
	if get_atk() > 0:
		parts.append("攻擊+%d" % get_atk())
	if get_hp() > 0:
		parts.append("血量+%d" % get_hp())
	if get_def() > 0:
		parts.append("防禦+%d" % get_def())
	if get_crit_rate() > 0.0:
		parts.append("暴率+%.1f%%" % (get_crit_rate() * 100.0))
	if get_crit_dmg() > 0.0:
		parts.append("暴傷+%d%%" % int(round(get_crit_dmg() * 100.0)))
	return " / ".join(parts)
