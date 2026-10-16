extends Node

signal stats_changed
signal gold_changed(new_gold: int)
signal exp_changed(current_exp: int, max_exp: int, level: int)
signal equipment_changed
signal skills_changed
signal stage_changed(stage: int, wave: int)
signal combat_log_added(text: String)

const SAVE_PATH := "user://idle_rpg_save.json"

# 玩家基礎數值與進度
var level: int = 1
var current_exp: int = 0
var gold: int = 50
var stage: int = 1
var wave: int = 1
var max_waves_per_stage: int = 5
var auto_advance_stage: bool = true

# 基礎屬性
var base_max_hp: int = 120
var base_atk: int = 14
var base_def: int = 3
var base_aspd: float = 1.0 # 每秒攻擊次數

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
	_init_default_skills()
	_init_starter_equipment()

func _init_default_skills() -> void:
	skills.clear()

	var s1 := SkillData.new()
	s1.id = "power_slash"
	s1.skill_name = "烈焰重斬 (主動)"
	s1.skill_type = SkillData.SkillType.ACTIVE_DAMAGE
	s1.level = 1
	s1.cooldown = 4.5
	s1.base_value = 2.2
	s1.growth_per_level = 0.45
	s1.base_cost = 25
	skills.append(s1)

	var s2 := SkillData.new()
	s2.id = "holy_light"
	s2.skill_name = "聖光治癒 (主動)"
	s2.skill_type = SkillData.SkillType.ACTIVE_HEAL
	s2.level = 0
	s2.cooldown = 8.0
	s2.base_value = 0.25
	s2.growth_per_level = 0.05
	s2.base_cost = 40
	skills.append(s2)

	var s3 := SkillData.new()
	s3.id = "sword_mastery"
	s3.skill_name = "劍術專精 (被動)"
	s3.skill_type = SkillData.SkillType.PASSIVE_ATK
	s3.level = 0
	s3.base_value = 0.15
	s3.growth_per_level = 0.10
	s3.base_cost = 35
	skills.append(s3)

	var s4 := SkillData.new()
	s4.id = "wind_blessing"
	s4.skill_name = "疾風祝福 (被動)"
	s4.skill_type = SkillData.SkillType.PASSIVE_ASPD
	s4.level = 0
	s4.base_value = 0.12
	s4.growth_per_level = 0.08
	s4.base_cost = 45
	skills.append(s4)

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
	var leveled_up := false
	while current_exp >= get_max_exp():
		current_exp -= get_max_exp()
		level += 1
		leveled_up = true
	exp_changed.emit(current_exp, get_max_exp(), level)
	if leveled_up:
		combat_log_added.emit("🎉 勇者升到了 Lv.%d！全屬性提升！" % level)
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

# 隨機生成一件裝備（打怪掉落或鐵匠鍛造）
func generate_random_equipment(stage_tier: int) -> EquipmentData:
	var item := EquipmentData.new()
	var slot_roll := randi() % 3
	var rarity_roll := randf()
	if rarity_roll < 0.12:
		item.rarity = 3
	elif rarity_roll < 0.40:
		item.rarity = 2
	else:
		item.rarity = 1

	var prefix_map := {1: "精鋼", 2: "秘銀", 3: "龍血"}
	var prefix: String = prefix_map[item.rarity]

	match slot_roll:
		0:
			# 武器(劍) - 主要提供攻擊力
			item.slot = EquipmentData.SlotType.WEAPON
			var names := ["短劍", "長劍", "巨劍", "魔劍"]
			item.item_name = "%s%s" % [prefix, names[randi() % names.size()]]
			item.base_atk = 6 + stage_tier * 4 + randi_range(0, 3)
		1:
			# 裝甲 - 主要提供血量
			item.slot = EquipmentData.SlotType.ARMOR
			var names := ["皮甲", "胸甲", "重鎧", "戰甲"]
			item.item_name = "%s%s" % [prefix, names[randi() % names.size()]]
			item.base_hp = 35 + stage_tier * 25 + randi_range(0, 15)
		2:
			# 盾牌 - 主要提供防禦力
			item.slot = EquipmentData.SlotType.SHIELD
			var names := ["圓盾", "方盾", "塔盾", "聖盾"]
			item.item_name = "%s%s" % [prefix, names[randi() % names.size()]]
			item.base_def = 3 + stage_tier * 2 + randi_range(0, 2)

	item.level = 1
	return item

func forge_cost() -> int:
	return 25 + (stage - 1) * 20

func forge_random_equipment() -> bool:
	var cost := forge_cost()
	if not spend_gold(cost):
		return false
	var new_item := generate_random_equipment(stage)
	inventory.append(new_item)
	combat_log_added.emit("⚒️ 鍛造出【%s】(%s)！已放入背包" % [new_item.item_name, new_item.get_slot_name()])
	equipment_changed.emit()
	return true

# 技能升級
func upgrade_skill(index: int) -> bool:
	if index < 0 or index >= skills.size():
		return false
	var s := skills[index]
	var cost := s.get_upgrade_cost()
	if not spend_gold(cost):
		return false
	s.level += 1
	combat_log_added.emit("✨ 技能【%s】升至 Lv.%d！" % [s.skill_name, s.level])
	skills_changed.emit()
	stats_changed.emit()
	return true
