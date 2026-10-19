class_name EquipmentData
extends Resource

enum SlotType { WEAPON, ARMOR, SHIELD }
enum Rarity {
	WHITE = 1,   # 普通 (白) - 0 項副屬性
	GREEN = 2,   # 優良 (綠) - 1 項副屬性
	BLUE = 3,    # 稀有 (藍) - 2 項副屬性
	PURPLE = 4,  # 史詩 (紫) - 3 項副屬性
	ORANGE = 5,  # 傳說 (橘) - 4 項副屬性
	RAINBOW = 6  # 神話 (彩虹框) - 5 項副屬性
}

const SUB_STAT_TYPES: Array[String] = ["atk", "def", "hp", "crit_rate", "crit_dmg"]

@export var id: String = ""
@export var item_name: String = "未命名裝備"
@export var slot: SlotType = SlotType.WEAPON
@export var level: int = 1
@export var rarity: int = Rarity.WHITE # 1:白, 2:綠, 3:藍, 4:紫, 5:橘, 6:彩虹

# 主屬性基礎值（僅主屬性會隨裝備強化等級 level 成長）
@export var base_atk: int = 0
@export var base_hp: int = 0
@export var base_def: int = 0

# 副屬性清單：每項為 {"type": String, "value": float}
# 項目數量與數值由裝備品階 (rarity) 決定，不隨裝備強化等級成長
@export var sub_stats: Array[Dictionary] = []

# 主屬性品階倍率
func get_rarity_multiplier() -> float:
	match rarity:
		Rarity.WHITE: return 1.0
		Rarity.GREEN: return 1.35
		Rarity.BLUE: return 1.80
		Rarity.PURPLE: return 2.40
		Rarity.ORANGE: return 3.20
		Rarity.RAINBOW: return 4.50
	return 1.0

# 副屬性數值品階倍率（由品階決定副屬性數值高低）
func get_sub_stat_rarity_multiplier() -> float:
	match rarity:
		Rarity.WHITE: return 0.0
		Rarity.GREEN: return 1.0
		Rarity.BLUE: return 1.35
		Rarity.PURPLE: return 1.80
		Rarity.ORANGE: return 2.40
		Rarity.RAINBOW: return 3.20
	return 1.0

# 依品階決定副屬性項目數量：白0、綠1、藍2、紫3、橘4、彩虹5
func get_target_sub_stat_count() -> int:
	return maxi(0, rarity - 1)

func get_main_stat_type() -> String:
	match slot:
		SlotType.WEAPON: return "atk"
		SlotType.ARMOR: return "hp"
		SlotType.SHIELD: return "def"
	return "atk"

# --- 主屬性計算（隨裝備等級 level 與品階成長） ---
func get_main_atk() -> int:
	if slot != SlotType.WEAPON or base_atk <= 0:
		return 0
	return int(round(base_atk * (1.0 + (level - 1) * 0.25) * get_rarity_multiplier()))

func get_main_hp() -> int:
	if slot != SlotType.ARMOR or base_hp <= 0:
		return 0
	return int(round(base_hp * (1.0 + (level - 1) * 0.25) * get_rarity_multiplier()))

func get_main_def() -> int:
	if slot != SlotType.SHIELD or base_def <= 0:
		return 0
	return int(round(base_def * (1.0 + (level - 1) * 0.25) * get_rarity_multiplier()))

# --- 副屬性加總計算（固定數值，不隨裝備等級 level 成長） ---
func get_sub_stat_total(stat_type: String) -> float:
	var total := 0.0
	for entry in sub_stats:
		if entry.get("type", "") == stat_type:
			total += float(entry.get("value", 0.0))
	return total

# --- 裝備總屬性（主屬性 + 副屬性，供角色總面板與戰力計算使用） ---
func get_atk() -> int:
	return get_main_atk() + int(round(get_sub_stat_total("atk")))

func get_hp() -> int:
	return get_main_hp() + int(round(get_sub_stat_total("hp")))

func get_def() -> int:
	return get_main_def() + int(round(get_sub_stat_total("def")))

func get_crit_rate() -> float:
	return snappedf(get_sub_stat_total("crit_rate"), 0.001)

func get_crit_dmg() -> float:
	return snappedf(get_sub_stat_total("crit_dmg"), 0.01)

# 依裝備品階與當前進度生成副屬性
# 規則：
# 1. 數量 = rarity - 1（白裝 0 項、綠裝 1 項 ... 彩虹 5 項）
# 2. 優先抽取不重複（且不與主屬性相同）的副屬性；當需要的項目數超過可用不重複屬性池時，才允許重複抽取
# 3. 數值由裝備品階 (rarity) 決定，且不會隨裝備等級成長
func roll_sub_stats(stage_tier: int, bonus_mult: float = 1.0) -> void:
	sub_stats.clear()
	var count := get_target_sub_stat_count()
	if count <= 0:
		return

	var main_type := get_main_stat_type()
	var primary_pool: Array[String] = []
	for st in SUB_STAT_TYPES:
		if st != main_type:
			primary_pool.append(st)
	primary_pool.shuffle()

	var current_pool: Array[String] = primary_pool.duplicate()
	var r_mult := get_sub_stat_rarity_multiplier() * bonus_mult

	for i in range(count):
		if current_pool.is_empty():
			# 當不重複屬性項目不夠時（例如彩虹裝需 5 項），重新補充屬性池允許重複
			current_pool = SUB_STAT_TYPES.duplicate()
			current_pool.shuffle()

		var st_type: String = current_pool.pop_back()
		var val := _roll_single_sub_stat_value(st_type, stage_tier, r_mult)
		sub_stats.append({
			"type": st_type,
			"value": val
		})

func _roll_single_sub_stat_value(st_type: String, stage_tier: int, r_mult: float) -> float:
	var tier_lvl := maxi(1, stage_tier)
	match st_type:
		"atk":
			return float(maxi(1, int(round((2.0 + tier_lvl * 1.6 + randf_range(0.0, 2.0)) * r_mult))))
		"def":
			return float(maxi(1, int(round((1.0 + tier_lvl * 0.9 + randf_range(0.0, 1.5)) * r_mult))))
		"hp":
			return float(maxi(5, int(round((12.0 + tier_lvl * 10.0 + randf_range(0.0, 8.0)) * r_mult))))
		"crit_rate":
			# 依品階決定暴擊率範圍：綠(1.5%~2.5%)、藍(2.5%~4.0%)、紫(4.0%~5.5%)、橘(5.5%~7.5%)、彩虹(7.5%~10.0%)
			var r_idx := maxi(0, rarity - 2)
			var min_cr := 0.015 + r_idx * 0.014
			var max_cr := 0.025 + r_idx * 0.018
			return snappedf(randf_range(min_cr, max_cr), 0.005)
		"crit_dmg":
			# 依品階決定暴擊傷害範圍：綠(8%~14%)、藍(14%~22%)、紫(22%~32%)、橘(32%~45%)、彩虹(45%~60%)
			var r_idx := maxi(0, rarity - 2)
			var min_cd := 0.08 + r_idx * 0.08
			var max_cd := 0.14 + r_idx * 0.11
			return snappedf(randf_range(min_cd, max_cd), 0.01)
	return 1.0

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
		Rarity.RAINBOW: return Color(1.0, 0.45, 0.78) # 彩虹代表色
		_: return Color(0.88, 0.88, 0.90)

func get_power_score() -> int:
	return (
		get_atk() * 10
		+ get_def() * 12
		+ get_hp() * 2
		+ int(round(get_crit_rate() * 100.0)) * 18
		+ int(round(get_crit_dmg() * 100.0)) * 6
	)

func _format_stat_line(st_type: String, val: float) -> String:
	match st_type:
		"atk":
			return "⚔️ 攻擊力：+%d" % int(round(val))
		"def":
			return "🛡️ 防禦力：+%d" % int(round(val))
		"hp":
			return "❤️ 生命值：+%d" % int(round(val))
		"crit_rate":
			return "💥 暴擊率：+%.1f%%" % (val * 100.0)
		"crit_dmg":
			return "🔥 暴擊傷害：+%d%%" % int(round(val * 100.0))
	return ""

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

func get_detailed_tooltip() -> String:
	var lines: Array[String] = []
	lines.append("【%s】%s +%d" % [get_rarity_name(), item_name, level])
	lines.append("部位：%s  |  戰力：%d" % [get_slot_name(), get_power_score()])
	lines.append("────────────────")
	lines.append("◆ 主屬性（隨等級成長）")
	match slot:
		SlotType.WEAPON:
			lines.append("  ⚔️ 攻擊力：+%d" % get_main_atk())
		SlotType.ARMOR:
			lines.append("  ❤️ 生命值：+%d" % get_main_hp())
		SlotType.SHIELD:
			lines.append("  🛡️ 防禦力：+%d" % get_main_def())

	lines.append("────────────────")
	lines.append("◇ 副屬性 (%d 項)（固定數值）" % sub_stats.size())
	if sub_stats.is_empty():
		lines.append("  （無副屬性）")
	else:
		for entry in sub_stats:
			var st_type: String = entry.get("type", "")
			var val: float = float(entry.get("value", 0.0))
			lines.append("  " + _format_stat_line(st_type, val))
	return "\n".join(lines)

func to_dict() -> Dictionary:
	return {
		"id": id,
		"item_name": item_name,
		"slot": slot,
		"level": level,
		"rarity": rarity,
		"base_atk": base_atk,
		"base_hp": base_hp,
		"base_def": base_def,
		"sub_stats": sub_stats.duplicate(true)
	}

static func from_dict(d: Dictionary) -> EquipmentData:
	var item := EquipmentData.new()
	item.id = d.get("id", "")
	item.item_name = d.get("item_name", "未命名裝備")
	item.slot = int(d.get("slot", SlotType.WEAPON)) as SlotType
	item.level = int(d.get("level", 1))
	item.rarity = int(d.get("rarity", Rarity.WHITE))
	item.base_atk = int(d.get("base_atk", 0))
	item.base_hp = int(d.get("base_hp", 0))
	item.base_def = int(d.get("base_def", 0))

	if d.has("sub_stats") and typeof(d["sub_stats"]) == TYPE_ARRAY:
		item.sub_stats.clear()
		for entry in d["sub_stats"]:
			if typeof(entry) == TYPE_DICTIONARY:
				item.sub_stats.append({
					"type": String(entry.get("type", "atk")),
					"value": float(entry.get("value", 0.0))
				})
	else:
		# 向下相容舊存檔：若舊裝備沒有 sub_stats 欄位，依品階自動補齊對應數量的副屬性
		if item.rarity > Rarity.WHITE:
			var est_tier := maxi(1, int(max(item.base_atk / 4.0, max(item.base_hp / 25.0, item.base_def / 2.0))))
			item.roll_sub_stats(est_tier, 1.0)
	return item
