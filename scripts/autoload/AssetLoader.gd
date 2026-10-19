class_name AssetLoader
extends RefCounted

# 全局開關：是否啟用外部美術素材 (若設為 false 或找不到對應 PNG 檔，將自動退回原本的幾何繪圖備案！)
static var use_custom_assets: bool = true

# 快取已載入的 Texture2D，避免每幀重複讀檔
static var _tex_cache: Dictionary = {}

# 標準美術素材路徑常數表 (未來使用「方式 A」替換素材時，只需將同名 PNG 覆蓋放入對應資料夾即可自動生效！)
const PATH_CUTIN_HERO := "res://assets/cutin/hero_cutin.png"
const PATH_BG_NORMAL := "res://assets/backgrounds/bg_normal.png"
const PATH_BG_BOSS_RUSH := "res://assets/backgrounds/bg_boss_rush.png"

const PATH_SPRITE_HERO := "res://assets/sprites/hero.png"
const PATH_SPRITE_HERO_ATTACK := "res://assets/sprites/hero_attack.png"
const PATH_SPRITE_MONSTER_NORMAL := "res://assets/sprites/monster_normal.png"
const PATH_SPRITE_MONSTER_NORMAL_ATTACK := "res://assets/sprites/monster_normal_attack.png"
const PATH_SPRITE_MONSTER_BOSS := "res://assets/sprites/monster_boss.png"
const PATH_SPRITE_MONSTER_BOSS_ATTACK := "res://assets/sprites/monster_boss_attack.png"

const PATH_CHEST_ORNATE := "res://assets/sprites/chest_ornate.png"
const PATH_CHEST_LUXURY := "res://assets/sprites/chest_luxury.png"
const PATH_CHEST_ULTIMATE := "res://assets/sprites/chest_ultimate.png"
const PATH_CHEST_ORNATE_CLOSED := "res://assets/sprites/chest_ornate_closed.png"
const PATH_CHEST_LUXURY_CLOSED := "res://assets/sprites/chest_luxury_closed.png"
const PATH_CHEST_ULTIMATE_CLOSED := "res://assets/sprites/chest_ultimate_closed.png"

const PATH_ICON_WEAPON := "res://assets/icons/equip_weapon.png"
const PATH_ICON_ARMOR := "res://assets/icons/equip_armor.png"
const PATH_ICON_SHIELD := "res://assets/icons/equip_shield.png"

const PATH_SKILL_RECKLESS := "res://assets/icons/skill_reckless.png"
const PATH_SKILL_LETHAL := "res://assets/icons/skill_lethal.png"
const PATH_SKILL_FIRST_AID := "res://assets/icons/skill_first_aid.png"
const PATH_SKILL_BLOCK := "res://assets/icons/skill_block.png"
const PATH_SKILL_SWORD_MASTERY := "res://assets/icons/skill_sword_mastery.png"
const PATH_SKILL_WIND_BLESSING := "res://assets/icons/skill_wind_blessing.png"

## 清除快取（當熱重載或替換圖片時可呼叫）
static func clear_cache() -> void:
	_tex_cache.clear()

## 載入外部或專案內的 PNG 貼圖（無須開啟 Godot 編輯器重新 Import，直接丟進資料夾即可讀取！）
static func get_texture(res_path: String) -> Texture2D:
	if not use_custom_assets:
		return null

	if _tex_cache.has(res_path):
		return _tex_cache[res_path]

	var abs_path := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img != null and not img.is_empty():
			var tex := ImageTexture.create_from_image(img)
			_tex_cache[res_path] = tex
			return tex

	if ResourceLoader.exists(res_path):
		var res := ResourceLoader.load(res_path)
		if res is Texture2D:
			_tex_cache[res_path] = res
			return res

	_tex_cache[res_path] = null
	return null

## 取得勇者貼圖（支援待機與攻擊動作切換）
static func get_hero_texture(is_attacking: bool = false) -> Texture2D:
	if not use_custom_assets:
		return null
	if is_attacking:
		var atk_tex := get_texture(PATH_SPRITE_HERO_ATTACK)
		if atk_tex != null:
			return atk_tex
	return get_texture(PATH_SPRITE_HERO)

## 依怪物名稱、是否為菁英/BOSS 與是否正在攻擊，自動挑選對應的怪物貼圖
static func get_monster_texture(enemy_name: String, is_boss: bool, is_attacking: bool = false) -> Texture2D:
	if not use_custom_assets:
		return null

	# 1. 優先檢查是否有該怪物專屬命名的貼圖
	var specific_base := ""
	if enemy_name.contains("史萊姆"):
		specific_base = "res://assets/sprites/monster_slime"
	elif enemy_name.contains("哥布林"):
		specific_base = "res://assets/sprites/monster_goblin"
	elif enemy_name.contains("骷髏"):
		specific_base = "res://assets/sprites/monster_skeleton"
	elif enemy_name.contains("半獸人"):
		specific_base = "res://assets/sprites/monster_orc"
	elif enemy_name.contains("巨龍") or enemy_name.contains("魔龍"):
		specific_base = "res://assets/sprites/monster_dragon"
	elif enemy_name.contains("魔王"):
		specific_base = "res://assets/sprites/monster_demon"

	if specific_base != "":
		if is_attacking:
			var spec_atk_tex := get_texture(specific_base + "_attack.png")
			if spec_atk_tex != null:
				return spec_atk_tex
		var spec_tex := get_texture(specific_base + ".png")
		if spec_tex != null:
			return spec_tex

	# 2. 退回通用「菁英/BOSS 怪物圖」或「一般怪物圖」（含攻擊動作切換）
	if is_boss:
		if is_attacking:
			var boss_atk_tex := get_texture(PATH_SPRITE_MONSTER_BOSS_ATTACK)
			if boss_atk_tex != null:
				return boss_atk_tex
		var boss_tex := get_texture(PATH_SPRITE_MONSTER_BOSS)
		if boss_tex != null:
			return boss_tex

	if is_attacking:
		var norm_atk_tex := get_texture(PATH_SPRITE_MONSTER_NORMAL_ATTACK)
		if norm_atk_tex != null:
			return norm_atk_tex
	return get_texture(PATH_SPRITE_MONSTER_NORMAL)

## 依裝備部位取得對應 ICON 貼圖
static func get_equip_icon_texture(slot_type: int) -> Texture2D:
	match slot_type:
		0: # WEAPON
			return get_texture(PATH_ICON_WEAPON)
		1: # ARMOR
			return get_texture(PATH_ICON_ARMOR)
		2: # SHIELD
			return get_texture(PATH_ICON_SHIELD)
	return null

## 依技能 ID 取得對應 ICON 貼圖
static func get_skill_icon_texture(skill_id: String) -> Texture2D:
	match skill_id:
		"reckless":
			return get_texture(PATH_SKILL_RECKLESS)
		"lethal":
			return get_texture(PATH_SKILL_LETHAL)
		"first_aid":
			return get_texture(PATH_SKILL_FIRST_AID)
		"block":
			return get_texture(PATH_SKILL_BLOCK)
		"sword_mastery":
			return get_texture(PATH_SKILL_SWORD_MASTERY)
		"wind_blessing":
			return get_texture(PATH_SKILL_WIND_BLESSING)
	return null

## 依 RUSH 寶箱階級 (1: 華麗, 2: 奢華, 3: 究極) 與開關狀態取得對應寶箱貼圖
static func get_chest_texture(chest_tier: int, is_open: bool = true) -> Texture2D:
	if not is_open:
		var closed_tex: Texture2D = null
		match chest_tier:
			1:
				closed_tex = get_texture(PATH_CHEST_ORNATE_CLOSED)
			2:
				closed_tex = get_texture(PATH_CHEST_LUXURY_CLOSED)
			3:
				closed_tex = get_texture(PATH_CHEST_ULTIMATE_CLOSED)
		if closed_tex != null:
			return closed_tex

	match chest_tier:
		1:
			return get_texture(PATH_CHEST_ORNATE)
		2:
			return get_texture(PATH_CHEST_LUXURY)
		3:
			return get_texture(PATH_CHEST_ULTIMATE)
	return null
