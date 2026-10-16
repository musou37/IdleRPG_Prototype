class_name EquipmentData
extends Resource

enum SlotType { WEAPON, ARMOR, ACCESSORY }

@export var id: String = ""
@export var item_name: String = "未命名裝備"
@export var slot: SlotType = SlotType.WEAPON
@export var level: int = 1

@export var base_atk: int = 0
@export var base_def: int = 0
@export var base_hp: int = 0
@export var base_aspd: float = 0.0

# 隨強化等級自動晉升品質階級 (每 5 等進階一次外觀品質與稱號)
func get_tier() -> int:
	if level >= 15:
		return 4 # 傳說 (金)
	elif level >= 10:
		return 3 # 史詩 (紫)
	elif level >= 5:
		return 2 # 稀有 (藍)
	return 1 # 初始 (白)

func get_display_name() -> String:
	var tier := get_tier()
	match slot:
		SlotType.WEAPON:
			var names := {1: "新手鐵劍", 2: "精鋼長劍", 3: "秘銀魔刃", 4: "龍血聖劍"}
			return names.get(tier, item_name)
		SlotType.ARMOR:
			var names := {1: "旅行皮甲", 2: "精鋼重鎧", 3: "秘銀戰甲", 4: "龍鱗神鎧"}
			return names.get(tier, item_name)
		SlotType.ACCESSORY:
			var names := {1: "初心銅戒", 2: "精鋼護符", 3: "秘銀魔戒", 4: "龍魂聖戒"}
			return names.get(tier, item_name)
	return item_name

func get_atk() -> int:
	if base_atk <= 0:
		return 0
	return int(round(base_atk * (1.0 + (level - 1) * 0.35)))

func get_def() -> int:
	if base_def <= 0:
		return 0
	return int(round(base_def * (1.0 + (level - 1) * 0.35)))

func get_hp() -> int:
	if base_hp <= 0:
		return 0
	return int(round(base_hp * (1.0 + (level - 1) * 0.35)))

func get_aspd() -> float:
	if base_aspd <= 0.0:
		return 0.0
	return snappedf(base_aspd * (1.0 + (level - 1) * 0.15), 0.01)

# 升級所需的對應專屬素材數量
func get_upgrade_material_cost() -> int:
	return 2 + int(level * 1.5)

func get_material_name() -> String:
	match slot:
		SlotType.WEAPON: return "鋒利鐵礦"
		SlotType.ARMOR: return "堅韌甲片"
		SlotType.ACCESSORY: return "星輝魔晶"
	return "未知素材"

func get_slot_name() -> String:
	match slot:
		SlotType.WEAPON: return "武器"
		SlotType.ARMOR: return "防具"
		SlotType.ACCESSORY: return "飾品"
	return "未知"

func get_rarity_color() -> Color:
	match get_tier():
		1: return Color(0.85, 0.88, 0.92) # 普通白
		2: return Color(0.35, 0.72, 1.0)  # 稀有藍
		3: return Color(0.82, 0.45, 1.0)  # 史詩紫
		_: return Color(1.0, 0.75, 0.22)  # 傳說金

func get_summary_text() -> String:
	var parts: Array[String] = []
	if get_atk() > 0:
		parts.append("攻擊+%d" % get_atk())
	if get_def() > 0:
		parts.append("防禦+%d" % get_def())
	if get_hp() > 0:
		parts.append("生命+%d" % get_hp())
	if get_aspd() > 0.0:
		parts.append("攻速+%.2f" % get_aspd())
	return " / ".join(parts)
