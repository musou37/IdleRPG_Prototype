class_name IconSlot
extends Control

enum Kind {
	EMPTY_WEAPON,
	EMPTY_ARMOR,
	EMPTY_SHIELD,
	WEAPON,
	ARMOR,
	SHIELD,
	SKILL_SLASH,
	SKILL_HEAL,
	SKILL_ATK,
	SKILL_ASPD,
	SKILL_CRIT,
	SKILL_DEF_HP
}

signal left_clicked
signal right_clicked

var icon_kind: Kind = Kind.WEAPON
var border_color: Color = Color(0.45, 0.48, 0.55)
var accent_color: Color = Color(0.85, 0.85, 0.85)
var badge_text: String = ""
var compare_tag: String = "" # 左上角強弱提示 ("▲" 較強 / "▼" 較弱)
var compare_color: Color = Color(0.3, 1.0, 0.5)
var is_locked: bool = false
var is_rainbow_border: bool = false
var rainbow_hue: float = 0.0
var cooldown_ratio: float = 0.0 # 0.0 ~ 1.0
var cooldown_sec: float = 0.0

func _init(slot_size: Vector2 = Vector2(56, 56)) -> void:
	custom_minimum_size = slot_size
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			left_clicked.emit()
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			right_clicked.emit()
			accept_event()

func _process(delta: float) -> void:
	if is_rainbow_border:
		rainbow_hue = fmod(rainbow_hue + delta * 0.45, 1.0)
		accent_color = Color.from_hsv(rainbow_hue, 0.72, 1.0)
		queue_redraw()

func setup_equipment(item: EquipmentData, empty_slot: EquipmentData.SlotType = EquipmentData.SlotType.WEAPON, is_inventory_item: bool = false) -> void:
	cooldown_ratio = 0.0
	cooldown_sec = 0.0
	compare_tag = ""
	if item == null:
		is_locked = true
		is_rainbow_border = false
		border_color = Color(0.32, 0.35, 0.42)
		accent_color = Color(0.35, 0.38, 0.45)
		badge_text = ""
		match empty_slot:
			EquipmentData.SlotType.WEAPON:
				icon_kind = Kind.EMPTY_WEAPON
				tooltip_text = "武器槽（尚未穿戴）"
			EquipmentData.SlotType.ARMOR:
				icon_kind = Kind.EMPTY_ARMOR
				tooltip_text = "裝甲槽（尚未穿戴）"
			EquipmentData.SlotType.SHIELD:
				icon_kind = Kind.EMPTY_SHIELD
				tooltip_text = "盾牌槽（尚未穿戴）"
	else:
		is_locked = false
		is_rainbow_border = item.is_rainbow()
		border_color = item.get_rarity_color()
		accent_color = item.get_rarity_color()
		badge_text = "+%d" % item.level
		var tip := item.get_detailed_tooltip()
		if is_inventory_item:
			var is_stronger := GameManager.is_stronger_than_equipped(item)
			var is_weaker := GameManager.is_weaker_than_equipped(item)
			if is_stronger:
				compare_tag = "▲"
				compare_color = Color(0.3, 1.0, 0.5)
				tip += "\n────────────────\n🔼 比目前穿戴的裝備更強！"
			elif is_weaker:
				compare_tag = "▼"
				compare_color = Color(1.0, 0.45, 0.45)
				tip += "\n────────────────\n🔽 比目前穿戴的裝備較弱"
			else:
				tip += "\n────────────────\n🟰 與目前穿戴戰力持平"
			var sell_price := int(10 * item.rarity * item.level)
			tip += "\n🖱️ [左鍵點擊] 穿戴裝備\n🖱️ [右鍵點擊] 出售 (+%d 金幣)" % sell_price
		else:
			var cost := item.get_upgrade_cost()
			tip += "\n────────────────\n🔨 強化費用：%d 金幣" % cost
		tooltip_text = tip
		match item.slot:
			EquipmentData.SlotType.WEAPON:
				icon_kind = Kind.WEAPON
			EquipmentData.SlotType.ARMOR:
				icon_kind = Kind.ARMOR
			EquipmentData.SlotType.SHIELD:
				icon_kind = Kind.SHIELD
	queue_redraw()

func setup_skill(skill: SkillData) -> void:
	is_locked = not skill.is_learned()
	is_rainbow_border = false
	if skill.is_learned():
		badge_text = "Lv.%d" % skill.level
	elif GameManager.level < skill.required_level:
		badge_text = "需Lv%d" % skill.required_level
	else:
		badge_text = "可學"

	match skill.skill_type:
		SkillData.SkillType.ACTIVE_DAMAGE:
			icon_kind = Kind.SKILL_SLASH
			accent_color = Color(1.0, 0.42, 0.25)
		SkillData.SkillType.ACTIVE_HEAL:
			icon_kind = Kind.SKILL_HEAL
			accent_color = Color(0.35, 0.95, 0.5)
		SkillData.SkillType.PASSIVE_ATK:
			icon_kind = Kind.SKILL_ATK
			accent_color = Color(1.0, 0.78, 0.25)
		SkillData.SkillType.PASSIVE_ASPD:
			icon_kind = Kind.SKILL_ASPD
			accent_color = Color(0.35, 0.85, 1.0)
		SkillData.SkillType.PASSIVE_CRIT:
			icon_kind = Kind.SKILL_CRIT
			accent_color = Color(1.0, 0.32, 0.55)
		SkillData.SkillType.PASSIVE_BLOCK:
			icon_kind = Kind.SKILL_DEF_HP
			accent_color = Color(0.4, 0.88, 0.65)
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

func _draw_rainbow_border(r_box: Rect2, width: float) -> void:
	var p0 := r_box.position
	var p1 := Vector2(r_box.end.x, r_box.position.y)
	var p2 := r_box.end
	var p3 := Vector2(r_box.position.x, r_box.end.y)
	var corners := [p0, p1, p2, p3]
	var segs_per_side := 5
	for side in range(4):
		var a: Vector2 = corners[side]
		var b: Vector2 = corners[(side + 1) % 4]
		for k in range(segs_per_side):
			var t0 := float(k) / float(segs_per_side)
			var t1 := float(k + 1) / float(segs_per_side)
			var hue := fmod(rainbow_hue + (float(side) + t0) * 0.25, 1.0)
			var seg_col := Color.from_hsv(hue, 0.85, 1.0)
			draw_line(a.lerp(b, t0), a.lerp(b, t1), seg_col, width)

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

	if is_rainbow_border:
		_draw_rainbow_border(rect.grow(-1.0), 3.0)
	else:
		draw_rect(rect.grow(-1.0), border_color, false, 2.5)

	# 2. 繪製圖示：優先使用正式美術 ICON (assets/icons/*.png)，若無則自動退回下方原生幾何圖示備案
	var custom_tex: Texture2D = null
	match icon_kind:
		Kind.EMPTY_WEAPON, Kind.WEAPON:
			custom_tex = AssetLoader.get_equip_icon_texture(0)
		Kind.EMPTY_ARMOR, Kind.ARMOR:
			custom_tex = AssetLoader.get_equip_icon_texture(1)
		Kind.EMPTY_SHIELD, Kind.SHIELD:
			custom_tex = AssetLoader.get_equip_icon_texture(2)
		Kind.SKILL_SLASH:
			custom_tex = AssetLoader.get_skill_icon_texture("reckless")
		Kind.SKILL_HEAL:
			custom_tex = AssetLoader.get_skill_icon_texture("first_aid")
		Kind.SKILL_ATK:
			custom_tex = AssetLoader.get_skill_icon_texture("sword_mastery")
		Kind.SKILL_ASPD:
			custom_tex = AssetLoader.get_skill_icon_texture("wind_blessing")
		Kind.SKILL_CRIT:
			custom_tex = AssetLoader.get_skill_icon_texture("lethal")
		Kind.SKILL_DEF_HP:
			custom_tex = AssetLoader.get_skill_icon_texture("block")

	var col := Color(0.42, 0.45, 0.52, 0.55) if is_locked else accent_color
	var light_col := col.lerp(Color.WHITE, 0.45)

	if custom_tex != null:
		var icon_mod := Color(0.45, 0.48, 0.55, 0.40) if is_locked else Color.WHITE
		draw_texture_rect(custom_tex, rect.grow(-4.0), false, icon_mod)
	else:
		_draw_procedural_icon(center, r, col, light_col)

	# 3. 技能冷卻遮罩
	if cooldown_ratio > 0.01:
		var cd_h := s.y * cooldown_ratio
		draw_rect(Rect2(0, s.y - cd_h, s.x, cd_h), Color(0.0, 0.0, 0.0, 0.68), true)
		var font := ThemeDB.fallback_font
		if font != null and cooldown_sec > 0.0:
			var cd_str := "%.1fs" % cooldown_sec
			draw_string(font, Vector2(6, center.y + 5), cd_str, HORIZONTAL_ALIGNMENT_CENTER, s.x - 12, 13, Color(1.0, 0.95, 0.4))

	# 4. 右下角等級 / 狀態小標籤
	if badge_text != "":
		var font := ThemeDB.fallback_font
		if font != null:
			var b_col := Color(0.65, 0.65, 0.65) if is_locked else Color(1.0, 0.95, 0.75)
			draw_rect(Rect2(2, s.y - 16, s.x - 4, 14), Color(0.05, 0.06, 0.09, 0.78), true)
			draw_string(font, Vector2(4, s.y - 5), badge_text, HORIZONTAL_ALIGNMENT_RIGHT, s.x - 8, 11, b_col)

	# 5. 左上角強弱提示小箭頭 (▲較強 / ▼較弱)
	if compare_tag != "":
		var font := ThemeDB.fallback_font
		if font != null:
			draw_rect(Rect2(3, 3, 14, 14), Color(0.05, 0.06, 0.09, 0.78), true)
			draw_string(font, Vector2(4, 14), compare_tag, HORIZONTAL_ALIGNMENT_CENTER, 12, 11, compare_color)

func _draw_procedural_icon(center: Vector2, r: float, col: Color, light_col: Color) -> void:
	match icon_kind:
		Kind.EMPTY_WEAPON, Kind.WEAPON:
			# 武器(劍)圖示：斜向劍刃、護手、劍柄
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
			# 裝甲(胸甲)圖示：雙肩甲、領口、胸甲軀幹與腰甲
			var armor_pts := PackedVector2Array([
				center + Vector2(-r * 0.22, -r * 0.48),
				center + Vector2(-r * 0.54, -r * 0.36),
				center + Vector2(-r * 0.46, -r * 0.05),
				center + Vector2(-r * 0.32, -r * 0.08),
				center + Vector2(-r * 0.36, r * 0.48),
				center + Vector2(r * 0.36, r * 0.48),
				center + Vector2(r * 0.32, -r * 0.08),
				center + Vector2(r * 0.46, -r * 0.05),
				center + Vector2(r * 0.54, -r * 0.36),
				center + Vector2(r * 0.22, -r * 0.48),
				center + Vector2(0.0, -r * 0.32)
			])
			draw_colored_polygon(armor_pts, col.darkened(0.25))
			for i in range(armor_pts.size()):
				draw_line(armor_pts[i], armor_pts[(i + 1) % armor_pts.size()], light_col, 2.2)
			# 胸甲中線與護心紋
			draw_line(center + Vector2(0, -r * 0.30), center + Vector2(0, r * 0.46), light_col, 2.0)
			draw_line(center + Vector2(-r * 0.32, r * 0.16), center + Vector2(r * 0.32, r * 0.16), light_col, 2.0)

		Kind.EMPTY_SHIELD, Kind.SHIELD:
			# 盾牌圖示：五邊形騎士盾與中央十字紋章
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

		Kind.SKILL_CRIT:
			# 狂暴之血：四角星芒爆裂圖示
			draw_line(center + Vector2(0, -r * 0.58), center + Vector2(0, r * 0.58), light_col, 3.5)
			draw_line(center + Vector2(-r * 0.58, 0), center + Vector2(r * 0.58, 0), light_col, 3.5)
			draw_line(center + Vector2(-r * 0.38, -r * 0.38), center + Vector2(r * 0.38, r * 0.38), col, 2.5)
			draw_line(center + Vector2(r * 0.38, -r * 0.38), center + Vector2(-r * 0.38, r * 0.38), col, 2.5)
			draw_circle(center, r * 0.20, light_col)

		Kind.SKILL_DEF_HP:
			# 不屈壁壘：雙重加固盾徽
			draw_arc(center, r * 0.48, 0.0, TAU, 6, light_col, 3.0)
			draw_circle(center, r * 0.22, col)

