class_name IconSlot
extends Control

enum Kind {
	EMPTY_WEAPON,
	EMPTY_ARMOR,
	EMPTY_ACCESSORY,
	WEAPON,
	ARMOR,
	ACCESSORY,
	MAT_WEAPON,
	MAT_ARMOR,
	MAT_ACCESSORY,
	SKILL_SLASH,
	SKILL_HEAL,
	SKILL_ATK,
	SKILL_ASPD
}

var icon_kind: Kind = Kind.WEAPON
var border_color: Color = Color(0.45, 0.48, 0.55)
var accent_color: Color = Color(0.85, 0.85, 0.85)
var badge_text: String = ""
var is_locked: bool = false
var cooldown_ratio: float = 0.0 # 0.0 ~ 1.0
var cooldown_sec: float = 0.0

func _init(slot_size: Vector2 = Vector2(56, 56)) -> void:
	custom_minimum_size = slot_size
	mouse_filter = Control.MOUSE_FILTER_PASS

func setup_equipment(item: EquipmentData, empty_slot: EquipmentData.SlotType = EquipmentData.SlotType.WEAPON) -> void:
	cooldown_ratio = 0.0
	cooldown_sec = 0.0
	if item == null:
		is_locked = true
		border_color = Color(0.32, 0.35, 0.42)
		accent_color = Color(0.35, 0.38, 0.45)
		badge_text = ""
		match empty_slot:
			EquipmentData.SlotType.WEAPON:
				icon_kind = Kind.EMPTY_WEAPON
			EquipmentData.SlotType.ARMOR:
				icon_kind = Kind.EMPTY_ARMOR
			EquipmentData.SlotType.ACCESSORY:
				icon_kind = Kind.EMPTY_ACCESSORY
	else:
		is_locked = false
		border_color = item.get_rarity_color()
		accent_color = item.get_rarity_color()
		badge_text = "Lv.%d" % item.level
		match item.slot:
			EquipmentData.SlotType.WEAPON:
				icon_kind = Kind.WEAPON
			EquipmentData.SlotType.ARMOR:
				icon_kind = Kind.ARMOR
			EquipmentData.SlotType.ACCESSORY:
				icon_kind = Kind.ACCESSORY
	queue_redraw()

func setup_material(slot: EquipmentData.SlotType, count: int) -> void:
	cooldown_ratio = 0.0
	cooldown_sec = 0.0
	is_locked = (count <= 0)
	badge_text = "x%d" % count
	match slot:
		EquipmentData.SlotType.WEAPON:
			icon_kind = Kind.MAT_WEAPON
			accent_color = Color(1.0, 0.52, 0.25) # 赤紅鐵礦
		EquipmentData.SlotType.ARMOR:
			icon_kind = Kind.MAT_ARMOR
			accent_color = Color(0.35, 0.78, 0.95) # 蒼藍甲片
		EquipmentData.SlotType.ACCESSORY:
			icon_kind = Kind.MAT_ACCESSORY
			accent_color = Color(0.85, 0.48, 1.0) # 紫耀魔晶
	border_color = accent_color if not is_locked else Color(0.35, 0.38, 0.42)
	queue_redraw()

func setup_skill(skill: SkillData) -> void:
	is_locked = not skill.is_learned()
	badge_text = ("Lv.%d" % skill.level) if skill.is_learned() else "未學"
	match skill.skill_type:
		SkillData.SkillType.ACTIVE_DAMAGE:
			icon_kind = Kind.SKILL_SLASH
			accent_color = Color(1.0, 0.48, 0.2)
		SkillData.SkillType.ACTIVE_HEAL:
			icon_kind = Kind.SKILL_HEAL
			accent_color = Color(0.35, 0.95, 0.5)
		SkillData.SkillType.PASSIVE_ATK:
			icon_kind = Kind.SKILL_ATK
			accent_color = Color(1.0, 0.8, 0.25)
		SkillData.SkillType.PASSIVE_ASPD:
			icon_kind = Kind.SKILL_ASPD
			accent_color = Color(0.35, 0.85, 1.0)
	border_color = accent_color if not is_locked else Color(0.35, 0.38, 0.42)
	update_cooldown(skill)
	queue_redraw()

func update_cooldown(skill: SkillData) -> void:
	if skill != null and skill.is_learned() and skill.is_active_skill() and skill.cooldown > 0.0:
		cooldown_sec = maxf(0.0, skill.current_cd)
		cooldown_ratio = clampf(cooldown_sec / skill.cooldown, 0.0, 1.0)
	else:
		cooldown_sec = 0.0
		cooldown_ratio = 0.0
	queue_redraw()

func _draw() -> void:
	var s := size
	if s.x <= 4 or s.y <= 4:
		s = custom_minimum_size
	var rect := Rect2(Vector2.ZERO, s)
	var center := s * 0.5
	var r := minf(s.x, s.y) * 0.5

	# 1. 底框背景與外框
	var bg_col := Color(0.11, 0.13, 0.18) if is_locked else Color(0.14, 0.17, 0.24).lerp(accent_color, 0.14)
	draw_rect(rect, bg_col, true)
	draw_rect(rect.grow(-3.0), Color(0.08, 0.09, 0.13, 0.65), true)
	draw_rect(rect.grow(-1.0), border_color, false, 2.5)

	# 2. 繪製簡易幾何圖示 (Icon)
	var col := Color(0.42, 0.45, 0.52, 0.55) if is_locked else accent_color
	var light_col := col.lerp(Color.WHITE, 0.45)

	match icon_kind:
		Kind.EMPTY_WEAPON, Kind.WEAPON:
			# 寶劍圖示：斜向劍刃、護手、劍柄
			var p_tip := center + Vector2(r * 0.52, -r * 0.52)
			var p_hilt := center + Vector2(-r * 0.22, r * 0.22)
			var p_pommel := center + Vector2(-r * 0.52, r * 0.52)
			draw_line(p_hilt, p_tip, light_col, 5.5)
			draw_line(p_hilt, p_tip, col, 2.5)
			var guard_a := p_hilt + Vector2(-r * 0.26, -r * 0.26)
			var guard_b := p_hilt + Vector2(r * 0.26, r * 0.26)
			draw_line(guard_a, guard_b, Color(0.95, 0.78, 0.25) if not is_locked else col, 4.5)
			draw_line(p_pommel, p_hilt, Color(0.65, 0.42, 0.22) if not is_locked else col, 3.5)
			draw_circle(p_pommel, 3.5, Color(0.95, 0.78, 0.25) if not is_locked else col)

		Kind.EMPTY_ARMOR, Kind.ARMOR:
			# 盾甲圖示：五邊形盾牌與胸甲核心
			var pts := PackedVector2Array([
				center + Vector2(-r * 0.48, -r * 0.45),
				center + Vector2(r * 0.48, -r * 0.45),
				center + Vector2(r * 0.48, r * 0.08),
				center + Vector2(0.0, r * 0.58),
				center + Vector2(-r * 0.48, r * 0.08)
			])
			draw_colored_polygon(pts, col.darkened(0.25))
			for i in range(pts.size()):
				draw_line(pts[i], pts[(i + 1) % pts.size()], light_col, 2.5)
			draw_line(center + Vector2(0, -r * 0.28), center + Vector2(0, r * 0.32), light_col, 2.5)
			draw_line(center + Vector2(-r * 0.26, -r * 0.04), center + Vector2(r * 0.26, -r * 0.04), light_col, 2.5)

		Kind.EMPTY_ACCESSORY, Kind.ACCESSORY:
			# 寶石戒/護符圖示：指環 + 上方菱形寶石
			var ring_c := center + Vector2(0, r * 0.14)
			draw_arc(ring_c, r * 0.34, 0.0, TAU, 24, Color(0.95, 0.8, 0.3) if not is_locked else col, 3.5)
			var gem_c := center + Vector2(0, -r * 0.26)
			var gem_pts := PackedVector2Array([
				gem_c + Vector2(0, -r * 0.28),
				gem_c + Vector2(r * 0.26, 0),
				gem_c + Vector2(0, r * 0.28),
				gem_c + Vector2(-r * 0.26, 0)
			])
			draw_colored_polygon(gem_pts, light_col)
			for i in range(gem_pts.size()):
				draw_line(gem_pts[i], gem_pts[(i + 1) % gem_pts.size()], col, 2.0)

		Kind.MAT_WEAPON:
			# 鋒利鐵礦：多角形礦石結晶與鍛造火星
			var ore_pts := PackedVector2Array([
				center + Vector2(-r * 0.15, -r * 0.52),
				center + Vector2(r * 0.42, -r * 0.25),
				center + Vector2(r * 0.48, r * 0.32),
				center + Vector2(-r * 0.12, r * 0.48),
				center + Vector2(-r * 0.48, r * 0.18),
				center + Vector2(-r * 0.42, -r * 0.32)
			])
			draw_colored_polygon(ore_pts, col.darkened(0.2))
			for i in range(ore_pts.size()):
				draw_line(ore_pts[i], ore_pts[(i + 1) % ore_pts.size()], light_col, 2.2)
			draw_line(center + Vector2(-r * 0.15, -r * 0.52), center + Vector2(r * 0.08, r * 0.12), light_col, 2.0)
			draw_line(center + Vector2(r * 0.08, r * 0.12), center + Vector2(r * 0.48, r * 0.32), light_col, 2.0)

		Kind.MAT_ARMOR:
			# 堅韌甲片：雙層交疊金屬護甲鱗片
			for layer in range(2):
				var y_off := (layer - 0.5) * r * 0.32
				var plate := PackedVector2Array([
					center + Vector2(-r * 0.46, y_off - r * 0.22),
					center + Vector2(r * 0.46, y_off - r * 0.22),
					center + Vector2(r * 0.36, y_off + r * 0.26),
					center + Vector2(0, y_off + r * 0.36),
					center + Vector2(-r * 0.36, y_off + r * 0.26)
				])
				draw_colored_polygon(plate, col.darkened(0.15 if layer == 1 else 0.35))
				for i in range(plate.size()):
					draw_line(plate[i], plate[(i + 1) % plate.size()], light_col, 2.0)

		Kind.MAT_ACCESSORY:
			# 星輝魔晶：中央主六角魔晶柱 + 兩側小晶簇
			var main_gem := PackedVector2Array([
				center + Vector2(0, -r * 0.58),
				center + Vector2(r * 0.26, -r * 0.22),
				center + Vector2(r * 0.22, r * 0.42),
				center + Vector2(0, r * 0.55),
				center + Vector2(-r * 0.22, r * 0.42),
				center + Vector2(-r * 0.26, -r * 0.22)
			])
			draw_colored_polygon(main_gem, col)
			for i in range(main_gem.size()):
				draw_line(main_gem[i], main_gem[(i + 1) % main_gem.size()], light_col, 2.2)
			draw_line(center + Vector2(-r * 0.48, -r * 0.08), center + Vector2(-r * 0.2, r * 0.38), light_col, 3.5)
			draw_line(center + Vector2(r * 0.48, -r * 0.08), center + Vector2(r * 0.2, r * 0.38), light_col, 3.5)

		Kind.SKILL_SLASH:
			# 烈焰重斬：雙重交叉烈焰斬擊弧線
			draw_line(center + Vector2(-r * 0.52, -r * 0.48), center + Vector2(r * 0.52, r * 0.48), col, 6.0)
			draw_line(center + Vector2(-r * 0.52, -r * 0.48), center + Vector2(r * 0.52, r * 0.48), light_col, 2.5)
			draw_line(center + Vector2(r * 0.52, -r * 0.48), center + Vector2(-r * 0.52, r * 0.48), col, 6.0)
			draw_line(center + Vector2(r * 0.52, -r * 0.48), center + Vector2(-r * 0.52, r * 0.48), light_col, 2.5)
			draw_circle(center, r * 0.18, light_col)

		Kind.SKILL_HEAL:
			# 聖光治癒：發光十字與外環光暈
			draw_arc(center, r * 0.52, 0.0, TAU, 24, col, 2.0)
			draw_rect(Rect2(center.x - r * 0.15, center.y - r * 0.42, r * 0.30, r * 0.84), light_col, true)
			draw_rect(Rect2(center.x - r * 0.42, center.y - r * 0.15, r * 0.84, r * 0.30), light_col, true)

		Kind.SKILL_ATK:
			# 劍術專精：直立戰劍 + 雙向上強化箭頭
			draw_line(center + Vector2(0, r * 0.48), center + Vector2(0, -r * 0.52), light_col, 4.5)
			draw_line(center + Vector2(-r * 0.25, r * 0.2), center + Vector2(r * 0.25, r * 0.2), col, 3.5)
			draw_line(center + Vector2(-r * 0.45, r * 0.05), center + Vector2(-r * 0.28, -r * 0.22), col, 2.5)
			draw_line(center + Vector2(r * 0.45, r * 0.05), center + Vector2(r * 0.28, -r * 0.22), col, 2.5)

		Kind.SKILL_ASPD:
			# 疾風祝福：三道流線疾風與閃電紋
			for idx in range(-1, 2):
				var y_off := idx * r * 0.32
				draw_line(center + Vector2(-r * 0.48, y_off + 3), center + Vector2(r * 0.35, y_off - 4), light_col, 3.0)
				draw_circle(center + Vector2(r * 0.38, y_off - 4), 2.5, col)

	# 3. 技能冷卻遮罩
	if cooldown_ratio > 0.01:
		var cd_h := s.y * cooldown_ratio
		draw_rect(Rect2(0, s.y - cd_h, s.x, cd_h), Color(0.0, 0.0, 0.0, 0.68), true)
		var font := ThemeDB.fallback_font
		if font != null and cooldown_sec > 0.0:
			var cd_str := "%.1fs" % cooldown_sec
			draw_string(font, Vector2(6, center.y + 5), cd_str, HORIZONTAL_ALIGNMENT_CENTER, s.x - 12, 13, Color(1.0, 0.95, 0.4))

	# 4. 右下角等級 / 數量小標籤
	if badge_text != "":
		var font := ThemeDB.fallback_font
		if font != null:
			var b_col := Color(0.65, 0.65, 0.65) if is_locked else Color(1.0, 0.95, 0.75)
			draw_rect(Rect2(2, s.y - 16, s.x - 4, 14), Color(0.05, 0.06, 0.09, 0.78), true)
			draw_string(font, Vector2(4, s.y - 5), badge_text, HORIZONTAL_ALIGNMENT_RIGHT, s.x - 8, 11, b_col)
