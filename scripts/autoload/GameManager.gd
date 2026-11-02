extends Node

signal stats_changed
signal gold_changed(new_gold: int)
signal exp_changed(current_exp: int, max_exp: int, level: int)
signal equipment_changed
signal skills_changed
signal stage_changed(stage: int, wave: int)
signal combat_log_added(text: String)

const SAVE_PATH := "user://idle_rpg_save.json"

# 玩家基礎數值與無盡討伐進度
var level: int = 1
var current_exp: int = 0
var gold: int = 50
var skill_points: int = 0
var kill_count: int = 0 # 累計擊殺怪物數量（越殺越強）
var next_is_elite: bool = false # 下一隻是否已被觸發為菁英怪
var elite_spawn_chance: float = 0.20 # 擊殺一般怪後觸發下一隻為菁英怪的機率 (20%)
var elite_stat_multiplier: float = 1.5 # 菁英怪強度為上一隻怪物的 N 倍 (1.5 倍)

# 🎰 FEVER / BOSS RUSH 模式設定
signal boss_rush_started(duration: float)
signal boss_rush_ended
var is_boss_rush: bool = false
var boss_rush_timer: float = 0.0
var boss_rush_duration: float = 15.0 # FEVER 持續時間 (秒)
var boss_rush_trigger_chance: float = 0.35 # 擊敗菁英怪時觸發 BOSS RUSH 的機率 (35%)
var boss_rush_kill_count: int = 0 # 該次 BOSS RUSH 期間擊殺的菁英怪數量

# 基礎屬性
var base_max_hp: int = 120
var base_atk: int = 14
var base_def: int = 3
var base_aspd: float = 1.0 # 每秒攻擊次數
var base_crit_rate: float = 0.05 # 初始暴擊率 5%
var base_crit_dmg: float = 1.5 # 初始暴擊倍率 1.5倍 (未觸發為 1.0倍)
var base_combo_rate: float = 0.05 # 初始連擊率 5%
var base_direct_dmg: int = 0 # 初始直接傷害 0 (無視減免)
var base_dodge_rate: float = 0.0 # 初始迴避率 0%

# 裝備系統：目前穿戴的 3 個部位 (武器、裝甲、盾牌) 與背包清單
var equipped: Dictionary = {
	EquipmentData.SlotType.WEAPON: null,
	EquipmentData.SlotType.ARMOR: null,
	EquipmentData.SlotType.SHIELD: null,
}
var inventory: Array[EquipmentData] = []

# 技能系統
var skills: Array[SkillData] = []

func _ready() -> void:
	_setup_fonts()
	_init_default_skills()
	_init_starter_equipment()
	load_game()

const _FONT_TC := preload("res://assets/fonts/NotoSansTC-Bold.otf")
const _FONT_EMOJI := preload("res://assets/fonts/NotoEmoji.ttf")

func _setup_fonts() -> void:
	var tc_font := _FONT_TC as FontFile
	var emoji_font := _FONT_EMOJI as FontFile
	if tc_font != null and emoji_font != null:
		tc_font.fallbacks = [emoji_font]
		if ThemeDB.get_default_theme() != null:
			ThemeDB.get_default_theme().default_font = tc_font

func _init_default_skills() -> void:
	skills.clear()

	# 1. 🔥 狂暴系 (BERSERK)
	var s1 := SkillData.new()
	s1.id = "reckless"
	s1.skill_name = "魯莽 (主動)"
	s1.category = SkillData.Category.BERSERK
	s1.skill_type = SkillData.SkillType.ACTIVE_DAMAGE
	s1.required_level = 1
	s1.level = 1
	s1.cooldown = 4.5
	s1.base_value = 1.50 # 150%
	s1.max_value = 2.50 # 250%
	s1.growth_per_level = 0.25 # 每級上下限各 +25%
	s1.base_cost = 1
	skills.append(s1)

	var s2 := SkillData.new()
	s2.id = "lethal"
	s2.skill_name = "致命 (被動)"
	s2.category = SkillData.Category.BERSERK
	s2.skill_type = SkillData.SkillType.PASSIVE_CRIT
	s2.required_level = 4
	s2.level = 0
	s2.base_value = 0.05 # 初始 +5% 暴擊傷害
	s2.growth_per_level = 0.05 # 每級 +5% 暴擊傷害
	s2.base_cost = 1
	skills.append(s2)

	# 2. 🛡️ 鐵衛系 (IRON_GUARD)
	var s3 := SkillData.new()
	s3.id = "first_aid"
	s3.skill_name = "急救 (主動)"
	s3.category = SkillData.Category.IRON_GUARD
	s3.skill_type = SkillData.SkillType.ACTIVE_HEAL
	s3.required_level = 2
	s3.level = 0
	s3.cooldown = 5.0 # 每 5 秒
	s3.base_value = 0.01 # 回復 1% 生命
	s3.growth_per_level = 0.005 # 每級 +0.5%
	s3.base_cost = 1
	skills.append(s3)

	var s4 := SkillData.new()
	s4.id = "block"
	s4.skill_name = "格檔 (被動)"
	s4.category = SkillData.Category.IRON_GUARD
	s4.skill_type = SkillData.SkillType.PASSIVE_BLOCK
	s4.required_level = 5
	s4.level = 0
	s4.base_value = 0.20 # 20% 機率減免 30% 傷害
	s4.growth_per_level = 0.01 # 每級 +1% 機率
	s4.base_cost = 1
	skills.append(s4)

	# 3. ⚡ 戰術系 (TACTICS)
	var s5 := SkillData.new()
	s5.id = "sword_mastery"
	s5.skill_name = "劍術專精 (被動)"
	s5.category = SkillData.Category.TACTICS
	s5.skill_type = SkillData.SkillType.PASSIVE_ATK
	s5.required_level = 3
	s5.level = 0
	s5.base_value = 0.15
	s5.growth_per_level = 0.10
	s5.base_cost = 1
	skills.append(s5)

	var s6 := SkillData.new()
	s6.id = "wind_blessing"
	s6.skill_name = "疾風祝福 (被動)"
	s6.category = SkillData.Category.TACTICS
	s6.skill_type = SkillData.SkillType.PASSIVE_ASPD
	s6.required_level = 6
	s6.level = 0
	s6.base_value = 0.12
	s6.growth_per_level = 0.08
	s6.base_cost = 1
	skills.append(s6)

func _init_starter_equipment() -> void:
	var starter_sword := EquipmentData.new()
	starter_sword.id = "starter_sword"
	starter_sword.item_name = "新手鐵劍"
	starter_sword.slot = EquipmentData.SlotType.WEAPON
	starter_sword.level = 1
	starter_sword.rarity = 1
	starter_sword.base_atk = 6
	equipped[EquipmentData.SlotType.WEAPON] = starter_sword

	var starter_armor := EquipmentData.new()
	starter_armor.id = "starter_armor"
	starter_armor.item_name = "旅行皮甲"
	starter_armor.slot = EquipmentData.SlotType.ARMOR
	starter_armor.level = 1
	starter_armor.rarity = 1
	starter_armor.base_hp = 40
	equipped[EquipmentData.SlotType.ARMOR] = starter_armor

	var starter_shield := EquipmentData.new()
	starter_shield.id = "starter_shield"
	starter_shield.item_name = "新手木盾"
	starter_shield.slot = EquipmentData.SlotType.SHIELD
	starter_shield.level = 1
	starter_shield.rarity = 1
	starter_shield.base_def = 2
	equipped[EquipmentData.SlotType.SHIELD] = starter_shield

# 計算玩家總屬性
func get_total_max_hp() -> int:
	var total := base_max_hp + (level - 1) * 28
	for item: EquipmentData in equipped.values():
		if item != null:
			total += item.get_hp()
	return total

func get_total_atk() -> int:
	var total := base_atk + (level - 1) * 4
	for item: EquipmentData in equipped.values():
		if item != null:
			total += item.get_atk()
	var mult := 1.0
	for s in skills:
		if s.is_learned() and s.skill_type == SkillData.SkillType.PASSIVE_ATK:
			mult += s.get_effect_value()
	return int(round(total * mult))

func get_total_def() -> int:
	var total := base_def + (level - 1) * 1
	for item: EquipmentData in equipped.values():
		if item != null:
			total += item.get_def()
	return total

func get_total_aspd() -> float:
	var total := base_aspd
	var mult := 1.0
	for s in skills:
		if s.is_learned() and s.skill_type == SkillData.SkillType.PASSIVE_ASPD:
			mult += s.get_effect_value()
	return snappedf(total * mult, 0.01)

func get_total_crit_rate() -> float:
	var total := base_crit_rate
	for item: EquipmentData in equipped.values():
		if item != null:
			total += item.get_crit_rate()
	return clampf(total, 0.0, 1.0)

func get_total_crit_dmg() -> float:
	var total := base_crit_dmg
	for item: EquipmentData in equipped.values():
		if item != null:
			total += item.get_crit_dmg()
	for s in skills:
		if s.is_learned() and s.skill_type == SkillData.SkillType.PASSIVE_CRIT:
			total += s.get_effect_value()
	return snappedf(total, 0.01)

func get_total_combo_rate() -> float:
	var total := base_combo_rate
	for item: EquipmentData in equipped.values():
		if item != null:
			total += item.get_combo_rate()
	return clampf(total, 0.0, 1.0)

func get_total_direct_dmg() -> int:
	var total := base_direct_dmg
	for item: EquipmentData in equipped.values():
		if item != null:
			total += item.get_direct_dmg()
	return maxi(0, total)

func get_total_dodge_rate() -> float:
	var total := base_dodge_rate
	for item: EquipmentData in equipped.values():
		if item != null:
			total += item.get_dodge_rate()
	return clampf(total, 0.0, 0.95)

func get_block_chance() -> float:
	var total := 0.0
	for s in skills:
		if s.is_learned() and s.skill_type == SkillData.SkillType.PASSIVE_BLOCK:
			total += s.get_effect_value()
	return clampf(total, 0.0, 0.90)

func get_block_reduction() -> float:
	return 0.30

func get_max_exp() -> int:
	return int(30 * pow(1.35, level - 1))

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

func add_exp(amount: int) -> void:
	current_exp += amount
	var gained_levels := 0
	while current_exp >= get_max_exp():
		current_exp -= get_max_exp()
		level += 1
		skill_points += 1
		gained_levels += 1
	exp_changed.emit(current_exp, get_max_exp(), level)
	if gained_levels > 0:
		combat_log_added.emit("🎉 勇者升到了 Lv.%d！獲得 %d 點技能點（目前共 %d 點）！" % [level, gained_levels, skill_points])
		skills_changed.emit()
		stats_changed.emit()

# 裝備操作：強化已穿戴裝備
func upgrade_equipped(slot: EquipmentData.SlotType) -> bool:
	var item: EquipmentData = equipped.get(slot)
	if item == null:
		return false
	var cost := item.get_upgrade_cost()
	if not spend_gold(cost):
		return false
	item.level += 1
	combat_log_added.emit("🔨 強化【%s】至 +%d！" % [item.item_name, item.level])
	equipment_changed.emit()
	stats_changed.emit()
	return true

# 裝備操作：穿戴背包中的裝備
func equip_from_inventory(index: int) -> void:
	if index < 0 or index >= inventory.size():
		return
	var new_item: EquipmentData = inventory[index]
	inventory.remove_at(index)
	var old_item: EquipmentData = equipped.get(new_item.slot)
	if old_item != null:
		inventory.append(old_item)
	equipped[new_item.slot] = new_item
	combat_log_added.emit("🛡️ 穿上了【%s】！" % new_item.item_name)
	equipment_changed.emit()
	stats_changed.emit()

# 賣出背包裝備換取金幣
func sell_inventory_item(index: int) -> void:
	if index < 0 or index >= inventory.size():
		return
	var item: EquipmentData = inventory[index]
	var sell_price := int(10 * item.rarity * item.level)
	inventory.remove_at(index)
	add_gold(sell_price)
	combat_log_added.emit("💰 出售【%s】獲得 %d 金幣" % [item.item_name, sell_price])
	equipment_changed.emit()

# 判斷裝備是否比目前身上同部位的裝備更強 / 更弱
func is_stronger_than_equipped(item: EquipmentData) -> bool:
	if item == null:
		return false
	var cur: EquipmentData = equipped.get(item.slot)
	if cur == null:
		return true
	return item.get_power_score() > cur.get_power_score()

func is_weaker_than_equipped(item: EquipmentData) -> bool:
	if item == null:
		return false
	var cur: EquipmentData = equipped.get(item.slot)
	if cur == null:
		return false
	return item.get_power_score() < cur.get_power_score()

func has_stronger_in_inventory() -> bool:
	for item in inventory:
		if is_stronger_than_equipped(item):
			return true
	return false

func get_weaker_inventory_count() -> int:
	var cnt := 0
	for item in inventory:
		if is_weaker_than_equipped(item):
			cnt += 1
	return cnt

# 一鍵穿上倉庫中各部位最強的裝備
func auto_equip_best() -> int:
	var swapped_count := 0
	for slot_key in [EquipmentData.SlotType.WEAPON, EquipmentData.SlotType.ARMOR, EquipmentData.SlotType.SHIELD]:
		var cur: EquipmentData = equipped.get(slot_key)
		var best_score := cur.get_power_score() if cur != null else -1
		var best_idx := -1
		for i in range(inventory.size()):
			var cand: EquipmentData = inventory[i]
			if cand.slot == slot_key and cand.get_power_score() > best_score:
				best_score = cand.get_power_score()
				best_idx = i
		if best_idx != -1:
			var new_item: EquipmentData = inventory[best_idx]
			inventory.remove_at(best_idx)
			if cur != null:
				inventory.append(cur)
			equipped[slot_key] = new_item
			swapped_count += 1
			combat_log_added.emit("⚡ 自動換上最強%s【%s +%d】！" % [new_item.get_slot_name(), new_item.item_name, new_item.level])
	if swapped_count > 0:
		equipment_changed.emit()
		stats_changed.emit()
	return swapped_count

# 一鍵售出倉庫中所有比身上弱的裝備
func auto_sell_weaker() -> Dictionary:
	var sold_count := 0
	var total_gold := 0
	for i in range(inventory.size() - 1, -1, -1):
		var inv_item: EquipmentData = inventory[i]
		if is_weaker_than_equipped(inv_item):
			var sell_price := int(10 * inv_item.rarity * inv_item.level)
			total_gold += sell_price
			sold_count += 1
			inventory.remove_at(i)
	if sold_count > 0:
		add_gold(total_gold)
		combat_log_added.emit("💰 自動售出 %d 件較弱裝備，共獲得 %d 金幣！" % [sold_count, total_gold])
		equipment_changed.emit()
	return {"count": sold_count, "gold": total_gold}

# 隨機生成一件裝備（source_type: "normal" 一般怪低品質, "elite" 菁英怪高品質, "forge" 鐵匠鍛造）
func generate_random_equipment(stage_tier: int, source_type: String = "forge") -> EquipmentData:
	var item := EquipmentData.new()
	var slot_roll := randi() % 3
	var rarity_roll := randf()

	match source_type:
		"normal":
			# 一般怪物：低品階（80% 白裝、18% 綠裝、2% 藍裝）
			if rarity_roll < 0.02:
				item.rarity = EquipmentData.Rarity.BLUE
			elif rarity_roll < 0.20:
				item.rarity = EquipmentData.Rarity.GREEN
			else:
				item.rarity = EquipmentData.Rarity.WHITE
		"elite":
			# 菁英怪物：必為高品階（40% 藍裝、35% 紫裝、18% 橘裝、7% 彩虹框神話裝）
			if rarity_roll < 0.07:
				item.rarity = EquipmentData.Rarity.RAINBOW
			elif rarity_roll < 0.25:
				item.rarity = EquipmentData.Rarity.ORANGE
			elif rarity_roll < 0.60:
				item.rarity = EquipmentData.Rarity.PURPLE
			else:
				item.rarity = EquipmentData.Rarity.BLUE
		"chest_ornate":
			# 華麗寶箱 (3~5殺)：保底藍~紫，高機率橘裝與神話裝 (12% 彩虹、33% 橘、40% 紫、15% 藍)
			if rarity_roll < 0.12:
				item.rarity = EquipmentData.Rarity.RAINBOW
			elif rarity_roll < 0.45:
				item.rarity = EquipmentData.Rarity.ORANGE
			elif rarity_roll < 0.85:
				item.rarity = EquipmentData.Rarity.PURPLE
			else:
				item.rarity = EquipmentData.Rarity.BLUE
		"chest_luxury":
			# 奢華寶箱 (6~9殺)：保底紫裝，極高機率橘裝與神話裝 (28% 彩虹、47% 橘、25% 紫)
			if rarity_roll < 0.28:
				item.rarity = EquipmentData.Rarity.RAINBOW
			elif rarity_roll < 0.75:
				item.rarity = EquipmentData.Rarity.ORANGE
			else:
				item.rarity = EquipmentData.Rarity.PURPLE
		"chest_ultimate":
			# 究極寶箱 (10殺以上)：全數為傳奇橘裝與天界彩虹神話裝！(55% 彩虹、45% 橘)
			if rarity_roll < 0.55:
				item.rarity = EquipmentData.Rarity.RAINBOW
			else:
				item.rarity = EquipmentData.Rarity.ORANGE
		_:
			# 鐵匠鍛造：全品階皆可鍛造（40% 白、30% 綠、16% 藍、9% 紫、4% 橘、1% 彩虹框）
			if rarity_roll < 0.01:
				item.rarity = EquipmentData.Rarity.RAINBOW
			elif rarity_roll < 0.05:
				item.rarity = EquipmentData.Rarity.ORANGE
			elif rarity_roll < 0.14:
				item.rarity = EquipmentData.Rarity.PURPLE
			elif rarity_roll < 0.30:
				item.rarity = EquipmentData.Rarity.BLUE
			elif rarity_roll < 0.60:
				item.rarity = EquipmentData.Rarity.GREEN
			else:
				item.rarity = EquipmentData.Rarity.WHITE

	var prefix_map := {
		EquipmentData.Rarity.WHITE: "粗鐵",
		EquipmentData.Rarity.GREEN: "精鋼",
		EquipmentData.Rarity.BLUE: "秘銀",
		EquipmentData.Rarity.PURPLE: "暗金",
		EquipmentData.Rarity.ORANGE: "龍血",
		EquipmentData.Rarity.RAINBOW: "天界幻彩"
	}
	var prefix: String = prefix_map.get(item.rarity, "粗鐵")

	# 菁英怪與 RUSH 寶箱掉落的裝備皆享有額外基礎屬性加成
	var stat_mult := 1.0
	match source_type:
		"normal":
			stat_mult = 0.80
		"elite", "chest_ornate":
			stat_mult = 1.25
		"chest_luxury":
			stat_mult = 1.38
		"chest_ultimate":
			stat_mult = 1.50

	match slot_roll:
		0:
			# 武器(劍) - 主要提供攻擊力
			item.slot = EquipmentData.SlotType.WEAPON
			var names := ["短劍", "長劍", "巨劍", "魔劍"]
			item.item_name = "%s%s" % [prefix, names[randi() % names.size()]]
			item.base_atk = maxi(1, int(round((6 + stage_tier * 4 + randi_range(0, 3)) * stat_mult)))
		1:
			# 裝甲 - 主要提供血量
			item.slot = EquipmentData.SlotType.ARMOR
			var names := ["皮甲", "胸甲", "重鎧", "戰甲"]
			item.item_name = "%s%s" % [prefix, names[randi() % names.size()]]
			item.base_hp = maxi(5, int(round((35 + stage_tier * 25 + randi_range(0, 15)) * stat_mult)))
		2:
			# 盾牌 - 主要提供防禦力
			item.slot = EquipmentData.SlotType.SHIELD
			var names := ["圓盾", "方盾", "塔盾", "聖盾"]
			item.item_name = "%s%s" % [prefix, names[randi() % names.size()]]
			item.base_def = maxi(1, int(round((3 + stage_tier * 2 + randi_range(0, 2)) * stat_mult)))

	# 依品階決定副屬性項目數量（白0、綠1、藍2、紫3、橘4、彩虹5）與數值（不隨裝備強化等級成長）
	item.roll_sub_stats(stage_tier, stat_mult)

	item.level = 1
	return item

# 依 BOSS RUSH 擊殺數結算對應品階的 RUSH 寶箱與掉落裝備清單
# 規則：
# - 3~5 殺：華麗寶箱 (最低 2 件)
# - 6~9 殺：奢華寶箱 (3 件，更高品質)
# - 10 殺以上：究極寶箱 (10~19殺 4 件，之後每滿 10 殺再多 1 件，極高品質)
func generate_rush_chest_reward(kills: int) -> Dictionary:
	if kills < 3:
		return {"has_chest": false, "chest_tier": 0, "chest_name": "", "items": []}

	var chest_tier := 1
	var chest_name := "華麗寶箱"
	var item_count := 2
	var source_type := "chest_ornate"

	if kills >= 10:
		chest_tier = 3
		chest_name = "究極寶箱"
		# 10~19殺為 4 件，20~29殺為 5 件，30~39殺為 6 件... 每 10 殺多 1 件
		item_count = 3 + int(kills / 10)
		source_type = "chest_ultimate"
	elif kills >= 6:
		chest_tier = 2
		chest_name = "奢華寶箱"
		item_count = 3
		source_type = "chest_luxury"
	else:
		chest_tier = 1
		chest_name = "華麗寶箱"
		item_count = 2
		source_type = "chest_ornate"

	var tier := get_current_tier()
	var drops: Array[EquipmentData] = []
	for i in range(item_count):
		drops.append(generate_random_equipment(tier, source_type))

	return {
		"has_chest": true,
		"chest_tier": chest_tier,
		"chest_name": chest_name,
		"kills": kills,
		"items": drops
	}

func get_current_tier() -> int:
	return 1 + int(kill_count / 5)

func forge_cost() -> int:
	return 25 + (get_current_tier() - 1) * 20

func forge_random_equipment() -> bool:
	var cost := forge_cost()
	if not spend_gold(cost):
		return false
	var new_item := generate_random_equipment(get_current_tier(), "forge")
	inventory.append(new_item)
	combat_log_added.emit("⚒️ 鍛造出【%s】(%s)！已放入背包" % [new_item.item_name, new_item.get_slot_name()])
	equipment_changed.emit()
	return true

# 技能升級（消耗技能點，並檢查勇者等級限制）
func upgrade_skill(index: int) -> bool:
	if index < 0 or index >= skills.size():
		return false
	var s := skills[index]
	if level < s.required_level:
		return false
	var cost := s.get_upgrade_cost()
	if skill_points < cost:
		return false
	skill_points -= cost
	s.points_spent += cost
	s.level += 1
	combat_log_added.emit("✨ 消耗 %d 點技能點，【%s】升至 Lv.%d！（剩餘技能點: %d）" % [cost, s.skill_name, s.level, skill_points])
	skills_changed.emit()
	stats_changed.emit()
	return true

func get_spent_skill_points() -> int:
	var total := 0
	for s in skills:
		total += s.points_spent
	return total

# 重置所有已消耗的技能點
func reset_skills() -> int:
	var refunded := get_spent_skill_points()
	if refunded <= 0:
		return 0
	for s in skills:
		s.level -= s.points_spent
		s.points_spent = 0
		if s.level <= 0:
			s.level = 0
			s.current_cd = 0.0
	skill_points += refunded
	combat_log_added.emit("🔄 已重置所有技能！退還了 %d 點技能點（目前可用: %d 點）" % [refunded, skill_points])
	skills_changed.emit()
	stats_changed.emit()
	return refunded

# 🎰 FEVER / BOSS RUSH 啟動與結束控制
func start_boss_rush(duration: float = -1.0) -> void:
	is_boss_rush = true
	boss_rush_timer = boss_rush_duration if duration <= 0.0 else duration
	boss_rush_kill_count = 0
	next_is_elite = true
	boss_rush_started.emit(boss_rush_timer)
	combat_log_added.emit("🎰🔥【FEVER！BOSS RUSH 狂熱模式爆發！】🔥🎰")
	combat_log_added.emit("⚡ 接下來 %.0f 秒內將源源不絕湧現【菁英怪】，高階神裝大爆發！" % boss_rush_timer)

func end_boss_rush() -> void:
	if not is_boss_rush:
		return
	is_boss_rush = false
	boss_rush_timer = 0.0
	boss_rush_ended.emit()
	combat_log_added.emit("🏁【BOSS RUSH FEVER 結束】本次狂熱共討伐了 %d 隻菁英怪！戰場回歸平靜。" % boss_rush_kill_count)

# 💾 進度存檔與讀檔系統 (Save & Load System)
func save_game() -> bool:
	var save_dict := {
		"version": 1,
		"level": level,
		"current_exp": current_exp,
		"gold": gold,
		"skill_points": skill_points,
		"kill_count": kill_count,
		"equipped": {},
		"inventory": [],
		"skills": []
	}

	# 1. 穿戴裝備
	for slot_key in equipped.keys():
		var item: EquipmentData = equipped[slot_key]
		if item != null:
			save_dict["equipped"][str(slot_key)] = item.to_dict()
		else:
			save_dict["equipped"][str(slot_key)] = null

	# 2. 背包裝備
	for item: EquipmentData in inventory:
		if item != null:
			save_dict["inventory"].append(item.to_dict())

	# 3. 技能進度
	for s: SkillData in skills:
		save_dict["skills"].append(s.to_dict())

	var json_str := JSON.stringify(save_dict, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		print("[Save] 無法寫入存檔檔案: ", SAVE_PATH)
		return false
	file.store_string(json_str)
	file.close()
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false

	var json_str := file.get_as_text()
	file.close()

	var parse_result = JSON.parse_string(json_str)
	if typeof(parse_result) != TYPE_DICTIONARY:
		return false

	var d: Dictionary = parse_result

	level = int(d.get("level", 1))
	current_exp = int(d.get("current_exp", 0))
	gold = int(d.get("gold", 50))
	skill_points = int(d.get("skill_points", 0))
	kill_count = int(d.get("kill_count", 0))

	# 讀取穿戴裝備
	if d.has("equipped") and typeof(d["equipped"]) == TYPE_DICTIONARY:
		var eq_dict: Dictionary = d["equipped"]
		for slot_key_str in eq_dict.keys():
			var slot_key := int(slot_key_str) as EquipmentData.SlotType
			var item_data = eq_dict[slot_key_str]
			if typeof(item_data) == TYPE_DICTIONARY:
				equipped[slot_key] = EquipmentData.from_dict(item_data)
			else:
				equipped[slot_key] = null

	# 讀取背包裝備
	if d.has("inventory") and typeof(d["inventory"]) == TYPE_ARRAY:
		inventory.clear()
		for item_dict in d["inventory"]:
			if typeof(item_dict) == TYPE_DICTIONARY:
				inventory.append(EquipmentData.from_dict(item_dict))

	# 讀取技能學習狀態
	if d.has("skills") and typeof(d["skills"]) == TYPE_ARRAY:
		var skill_map: Dictionary = {}
		for sk_data in d["skills"]:
			if typeof(sk_data) == TYPE_DICTIONARY and sk_data.has("id"):
				skill_map[sk_data["id"]] = sk_data
		for s in skills:
			if skill_map.has(s.id):
				s.apply_dict(skill_map[s.id])

	stats_changed.emit()
	gold_changed.emit(gold)
	exp_changed.emit(current_exp, get_max_exp(), level)
	equipment_changed.emit()
	skills_changed.emit()
	print("[Load] 成功讀取遊戲進度！Lv.", level, " 金幣: ", gold, " 累計擊殺: ", kill_count)
	return true

func reset_save_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	level = 1
	current_exp = 0
	gold = 50
	skill_points = 0
	kill_count = 0
	next_is_elite = false
	is_boss_rush = false
	boss_rush_timer = 0.0
	_init_default_skills()
	_init_starter_equipment()
	stats_changed.emit()
	gold_changed.emit(gold)
	exp_changed.emit(current_exp, get_max_exp(), level)
	equipment_changed.emit()
	skills_changed.emit()

