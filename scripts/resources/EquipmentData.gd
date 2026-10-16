class_name EquipmentData
extends Resource

enum SlotType { WEAPON, ARMOR, SHIELD }

@export var id: String = ""
@export var item_name: String = "未命名裝備"
@export var slot: SlotType = SlotType.WEAPON
@export var level: int = 1
@export var rarity: int = 1 # 1: 普通, 2: 稀有, 3: 史詩

@export var base_atk: int = 0
@export var base_hp: int = 0
@export var base_def: int = 0

func get_atk() -> int:
	return int(base_atk * (1.0 + (level - 1) * 0.25) * rarity)

func get_hp() -> int:
	return int(base_hp * (1.0 + (level - 1) * 0.25) * rarity)

func get_def() -> int:
	return int(base_def * (1.0 + (level - 1) * 0.25) * rarity)

func get_upgrade_cost() -> int:
	return int(15 * pow(1.45, level - 1) * rarity)

func get_slot_name() -> String:
	match slot:
		SlotType.WEAPON: return "武器"
		SlotType.ARMOR: return "裝甲"
		SlotType.SHIELD: return "盾牌"
	return "未知"

func get_rarity_color() -> Color:
	match rarity:
		1: return Color(0.85, 0.85, 0.85)
		2: return Color(0.35, 0.7, 1.0)
		3: return Color(0.8, 0.45, 1.0)
		_: return Color(1.0, 0.65, 0.2)

func get_power_score() -> int:
	return get_atk() * 10 + get_def() * 12 + get_hp() * 2

func get_summary_text() -> String:
	var parts: Array[String] = []
	if get_atk() > 0:
		parts.append("攻擊+%d" % get_atk())
	if get_hp() > 0:
		parts.append("血量+%d" % get_hp())
	if get_def() > 0:
		parts.append("防禦+%d" % get_def())
	return " / ".join(parts)
