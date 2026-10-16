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

# 裝備系統：固定穿戴初始 3 個部位，透過專屬素材提升等級
var equipped: Dictionary = {
	EquipmentData.SlotType.WEAPON: null,
	EquipmentData.SlotType.ARMOR: null,
	EquipmentData.SlotType.ACCESSORY: null,
}

# 各部位獨立對應的強化素材數量
var materials: Dictionary = {
	EquipmentData.SlotType.WEAPON: 3,    # 鋒利鐵礦 (武器專用)
	EquipmentData.SlotType.ARMOR: 3,     # 堅韌甲片 (防具專用)
	EquipmentData.SlotType.ACCESSORY: 3, # 星輝魔晶 (飾品專用)
}

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
	starter_sword.base_atk = 8
	equipped[EquipmentData.SlotType.WEAPON] = starter_sword

	var starter_armor := EquipmentData.new()
	starter_armor.id = "starter_armor"
	starter_armor.item_name = "旅行皮甲"
	starter_armor.slot = EquipmentData.SlotType.ARMOR
	starter_armor.level = 1
	starter_armor.base_def = 3
	starter_armor.base_hp = 40
	equipped[EquipmentData.SlotType.ARMOR] = starter_armor

	var starter_ring := EquipmentData.new()
	starter_ring.id = "starter_ring"
	starter_ring.item_name = "初心銅戒"
	starter_ring.slot = EquipmentData.SlotType.ACCESSORY
	starter_ring.level = 1
	starter_ring.base_atk = 3
	starter_ring.base_hp = 20
	starter_ring.base_aspd = 0.08
	equipped[EquipmentData.SlotType.ACCESSORY] = starter_ring

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
	for item: EquipmentData in equipped.values():
		if item != null:
			total += item.get_aspd()
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

# 素材系統操作
func get_material_count(slot: EquipmentData.SlotType) -> int:
	return int(materials.get(slot, 0))

func get_material_name(slot: EquipmentData.SlotType) -> String:
	match slot:
		EquipmentData.SlotType.WEAPON: return "鋒利鐵礦"
		EquipmentData.SlotType.ARMOR: return "堅韌甲片"
		EquipmentData.SlotType.ACCESSORY: return "星輝魔晶"
	return "未知素材"

func add_material(slot: EquipmentData.SlotType, amount: int) -> void:
	materials[slot] = get_material_count(slot) + amount
	equipment_changed.emit()

# 擊殺怪物時掉落裝備對應素材
func roll_monster_material_drop(is_boss: bool, stage_tier: int) -> Dictionary:
	# 一般怪 65% 機率掉落 1 種素材；Boss 100% 掉落大量素材
	var drop_chance := 1.0 if is_boss else 0.65
	if randf() > drop_chance:
		return {}

	var slots := [
		EquipmentData.SlotType.WEAPON,
		EquipmentData.SlotType.ARMOR,
		EquipmentData.SlotType.ACCESSORY
	]
	var chosen_slot: EquipmentData.SlotType = slots[randi() % slots.size()]
	var base_amt := 1 + int(stage_tier / 3)
	var amount := base_amt * (3 if is_boss else 1)

	add_material(chosen_slot, amount)
	var mat_name := get_material_name(chosen_slot)
	combat_log_added.emit("💎 獲得強化素材【%s】x%d！" % [mat_name, amount])
	return {
		"slot": chosen_slot,
		"amount": amount,
		"name": mat_name
	}

# 裝備操作：消耗對應素材強化裝備等級
func upgrade_equipped(slot: EquipmentData.SlotType) -> bool:
	var item: EquipmentData = equipped.get(slot)
	if item == null:
		return false
	var cost := item.get_upgrade_material_cost()
	var owned := get_material_count(slot)
	if owned < cost:
		return false
	materials[slot] = owned - cost
	var old_tier := item.get_tier()
	item.level += 1
	var new_tier := item.get_tier()
	if new_tier > old_tier:
		combat_log_added.emit("🌟 裝備進階！強化至【%s +%d】！" % [item.get_display_name(), item.level])
	else:
		combat_log_added.emit("🔨 消耗 %d 個%s，強化【%s】至 +%d！" % [cost, item.get_material_name(), item.get_display_name(), item.level])
	equipment_changed.emit()
	stats_changed.emit()
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
