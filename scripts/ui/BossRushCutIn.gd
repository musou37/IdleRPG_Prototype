class_name BossRushCutIn
extends Control

signal cut_in_finished

var portrait_slide: float = 0.0 # 0.0 (左側畫面外) -> 1.0 (切入就位)
var text_slide: float = 0.0     # 0.0 (右側畫面外) -> 1.0 (文字切入就位)
var banner_alpha: float = 0.0   # 整體暗轉與背景橫幅透明度
var flash_alpha: float = 0.0    # 必殺技發動與文字撞擊閃光
var anim_time: float = 0.0
var is_playing: bool = false
var _tween: Tween = null

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

func play_cut_in() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()

	is_playing = true
	visible = true
	anim_time = 0.0
	portrait_slide = 0.0
	text_slide = 0.0
	banner_alpha = 1.0
	flash_alpha = 1.0

	# 暫停遊戲（格鬥遊戲超必殺技「暗轉時間凍結」演出），切入期間固定 1.0 倍真實時間流速
	Engine.time_scale = 1.0
	get_tree().paused = true

	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	# 階段 1：左方巨型大頭像高速切入 (0.0s -> 0.22s)
	_tween.tween_property(self, "portrait_slide", 1.0, 0.22).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	# 階段 2：頭像切入就位後，右方「BOSS RUSH!!!」文字猛烈撞入 (約 0.22s -> 0.44s)
	_tween.tween_callback(func():
		flash_alpha = 0.85 # 文字撞擊瞬間二次閃光
	)
	_tween.tween_property(self, "text_slide", 1.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 階段 3：雙重定格展示超必殺魄力 (停留 0.90s)
	_tween.tween_interval(0.90)

	# 階段 4：左右雙向高速滑出退場，解除暫停並進入 2x BOSS RUSH (0.26s)
	_tween.tween_property(self, "portrait_slide", 0.0, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.parallel().tween_property(self, "text_slide", 0.0, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.parallel().tween_property(self, "banner_alpha", 0.0, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	_tween.tween_callback(_finish_cut_in)
	queue_redraw()

func force_stop() -> void:
	if not is_playing:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_finish_cut_in()

func _finish_cut_in() -> void:
	is_playing = false
	visible = false
	portrait_slide = 0.0
	text_slide = 0.0
	banner_alpha = 0.0
	flash_alpha = 0.0
	get_tree().paused = false
	if GameManager.is_boss_rush:
		Engine.time_scale = 2.0
	cut_in_finished.emit()

func _process(delta: float) -> void:
	if not is_playing:
		return
	anim_time += delta
	if flash_alpha > 0.0:
		flash_alpha = maxf(0.0, flash_alpha - delta * 3.8)
	queue_redraw()

func _draw() -> void:
	if not is_playing:
		return

	var a := clampf(banner_alpha, 0.0, 1.0)

	# 1. 全畫面超必殺暗轉背景 (壓暗整個 720x960 遊戲畫面，凸顯中央 Cut-In)
	draw_rect(Rect2(0, 0, 720, 960), Color(0.02, 0.01, 0.06, 0.74 * a))

	# 2. 橫跨全螢幕中央的斜切超必殺橫幅帶 (y = 230 ~ 570，直接跨在戰鬥區與下方介面正中央)
	var band_top_left := 265.0
	var band_top_right := 215.0
	var band_bot_right := 545.0
	var band_bot_left := 595.0

	var band_poly := PackedVector2Array([
		Vector2(0, band_top_left),
		Vector2(720, band_top_right),
		Vector2(720, band_bot_right),
		Vector2(0, band_bot_left)
	])
	var pulse := (sin(anim_time * 14.0) + 1.0) * 0.5
	var band_col := Color(0.26, 0.04, 0.14, 0.96 * a).lerp(Color(0.45, 0.08, 0.20, 0.96 * a), pulse)
	draw_colored_polygon(band_poly, band_col)

	# 橫幅內部高速斜向速度線 (Speed Lines)
	for i in range(18):
		var t_ratio := float(i) / 18.0
		var ly_left := lerpf(band_top_left + 12.0, band_bot_left - 12.0, t_ratio)
		var slope := (band_top_right - band_top_left) / 720.0
		var lx := fmod(i * 83.0 + anim_time * 1350.0, 900.0) - 180.0
		var llen := 140.0 + (i % 4) * 75.0
		var ly1 := ly_left + lx * slope
		var ly2 := ly_left + (lx + llen) * slope
		var lcol := Color(1.0, 0.88, 0.35, (0.22 + (i % 3) * 0.12) * a) if (i % 2 == 0) else Color(0.55, 0.85, 1.0, 0.25 * a)
		draw_line(Vector2(lx, ly1), Vector2(lx + llen, ly2), lcol, 2.5 + (i % 3))

	# 橫幅上下粗黑框與發光黃金邊條
	draw_line(Vector2(0, band_top_left), Vector2(720, band_top_right), Color(0.05, 0.02, 0.05, a), 12.0)
	draw_line(Vector2(0, band_top_left), Vector2(720, band_top_right), Color(1.0, 0.85, 0.25, a), 5.0)
	draw_line(Vector2(0, band_bot_left), Vector2(720, band_bot_right), Color(0.05, 0.02, 0.05, a), 12.0)
	draw_line(Vector2(0, band_bot_left), Vector2(720, band_bot_right), Color(1.0, 0.85, 0.25, a), 5.0)

	# 3. 左方巨型勇者側面特寫大頭像 (Portrait Cut-In)
	if portrait_slide > 0.001:
		_draw_left_hero_portrait(a)

	# 4. 右方「BOSS RUSH!!!」魄力文字切入 (Text Cut-In)
	if text_slide > 0.001:
		_draw_right_boss_rush_text(a)

	# 5. 全畫面必殺閃白光效
	if flash_alpha > 0.0:
		draw_rect(Rect2(0, 0, 720, 960), Color(1.0, 0.97, 0.88, flash_alpha * 0.65))


func _draw_left_hero_portrait(master_alpha: float) -> void:
	var p_alpha := clampf(portrait_slide, 0.0, 1.0) * master_alpha
	var x_off := (1.0 - portrait_slide) * -480.0
	# 將大頭像配置在畫面中央偏左 (y 基準在 225，讓頭像直接突破橫幅上下邊界，展現出框魄力！)
	var base := Vector2(x_off - 10.0, 225.0)

	# 優先使用正式美術立繪 (assets/cutin/hero_cutin.png)，若無則自動退回下方原生幾何繪圖備案
	var cutin_tex := AssetLoader.get_texture(AssetLoader.PATH_CUTIN_HERO)
	if cutin_tex != null:
		var dest_rect := Rect2(base + Vector2(0, -40), Vector2(430, 430))
		# 繪製後方黃金鬥氣殘影位移與立繪本體
		draw_texture_rect(cutin_tex, Rect2(dest_rect.position + Vector2(8, 4), dest_rect.size), false, Color(1.0, 0.82, 0.15, 0.55 * p_alpha))
		draw_texture_rect(cutin_tex, dest_rect, false, Color(1.0, 1.0, 1.0, p_alpha))
		return

	# [備案 Fallback] 原生程式幾何繪圖：
	# (a) 後方高領黑紫披風與巨型黃金鎖鏈
	var cape_poly := PackedVector2Array([
		base + Vector2(0, 130),
		base + Vector2(225, 165),
		base + Vector2(265, 360),
		base + Vector2(0, 370)
	])
	draw_colored_polygon(cape_poly, Color(0.10, 0.04, 0.16, 0.96 * p_alpha))

	var chain_col := Color(0.95, 0.74, 0.16, 0.95 * p_alpha)
	var chain_dark := Color(0.42, 0.25, 0.04, 0.98 * p_alpha)
	draw_arc(base + Vector2(62, 190), 44.0, 0.0, TAU, 24, chain_dark, 19.0)
	draw_arc(base + Vector2(62, 190), 44.0, 0.0, TAU, 24, chain_col, 12.0)
	draw_arc(base + Vector2(88, 265), 46.0, 0.0, TAU, 24, chain_dark, 19.0)
	draw_arc(base + Vector2(88, 265), 46.0, 0.0, TAU, 24, chain_col, 12.0)
	draw_arc(base + Vector2(48, 325), 42.0, 0.0, TAU, 24, chain_dark, 19.0)
	draw_arc(base + Vector2(48, 325), 42.0, 0.0, TAU, 24, chain_col, 12.0)

	# (b) 巨型臉部側面輪廓 (銳利鼻樑、咬牙嘴型、剛毅下顎)
	var skin_base := Color(0.93, 0.73, 0.55, 0.96 * p_alpha)
	var skin_light := Color(0.99, 0.89, 0.75, 0.98 * p_alpha)
	var ink_col := Color(0.06, 0.03, 0.05, 0.98 * p_alpha)

	var face_poly := PackedVector2Array([
		base + Vector2(130, 32),   # 後腦上方
		base + Vector2(375, 38),   # 額頭前緣
		base + Vector2(382, 98),   # 眉骨突出
		base + Vector2(364, 122),  # 眼窩凹陷
		base + Vector2(422, 182),  # 巨型高挺鼻尖
		base + Vector2(382, 200),  # 鼻下人中
		base + Vector2(394, 216),  # 上唇突出
		base + Vector2(376, 232),  # 咬牙嘴角
		base + Vector2(390, 248),  # 下唇
		base + Vector2(380, 290),  # 剛毅下巴尖
		base + Vector2(265, 322),  # 下顎線轉折
		base + Vector2(215, 365),  # 頸部後方
		base + Vector2(105, 365)
	])
	draw_colored_polygon(face_poly, skin_base)

	# 鼻樑與臉頰高光色塊
	var highlight_poly := PackedVector2Array([
		base + Vector2(364, 122),
		base + Vector2(422, 182),
		base + Vector2(382, 200),
		base + Vector2(342, 186),
		base + Vector2(332, 145)
	])
	draw_colored_polygon(highlight_poly, skin_light)

	# (c) 壓低帽簷下的上半臉濃黑陰影色塊 (JOJO 承太郎式半臉黑影)
	var upper_shadow_poly := PackedVector2Array([
		base + Vector2(140, 48),
		base + Vector2(382, 88),
		base + Vector2(364, 122),
		base + Vector2(392, 152),
		base + Vector2(315, 198),
		base + Vector2(238, 265),
		base + Vector2(140, 265)
	])
	draw_colored_polygon(upper_shadow_poly, ink_col)

	# 臉頰斜向漫畫排線 (Hatching Lines)
	for h_i in range(9):
		var hy := 168.0 + h_i * 13.0
		var hx := 318.0 - h_i * 7.5
		draw_line(base + Vector2(hx, hy), base + Vector2(hx + 38.0, hy - 15.0), ink_col, 3.2)

	# (d) 陰影中爆亮的銳利眼神與金色光軌殘影
	var eye_white := PackedVector2Array([
		base + Vector2(292, 130),
		base + Vector2(344, 124),
		base + Vector2(334, 144),
		base + Vector2(282, 142)
	])
	draw_colored_polygon(eye_white, Color(0.95, 0.99, 1.0, p_alpha))
	draw_circle(base + Vector2(322, 134), 6.5, Color(1.0, 0.85, 0.15, p_alpha))
	draw_circle(base + Vector2(322, 134), 3.0, Color(1.0, 1.0, 1.0, p_alpha))
	# 眼神向後拉出的超必殺光束殘影
	var eye_glow := (sin(anim_time * 22.0) + 1.0) * 0.5
	draw_line(base + Vector2(322, 134), base + Vector2(170, 110), Color(0.4, 0.9, 1.0, (0.75 + 0.25 * eye_glow) * p_alpha), 5.0)
	draw_line(base + Vector2(322, 134), base + Vector2(215, 148), Color(1.0, 0.88, 0.25, 0.85 * p_alpha), 3.5)

	# (e) 咬緊牙關的冷酷嘴部細節
	var mouth_poly := PackedVector2Array([
		base + Vector2(386, 220),
		base + Vector2(342, 214),
		base + Vector2(336, 232),
		base + Vector2(382, 238)
	])
	draw_colored_polygon(mouth_poly, ink_col)
	draw_line(base + Vector2(346, 224), base + Vector2(380, 228), Color(0.96, 0.96, 0.99, 0.92 * p_alpha), 5.0)

	# (f) 側面輪廓超粗漫畫黑線與黃金鬥氣描邊
	var profile_pts := PackedVector2Array([
		base + Vector2(375, 38),
		base + Vector2(382, 98),
		base + Vector2(364, 122),
		base + Vector2(422, 182),
		base + Vector2(382, 200),
		base + Vector2(394, 216),
		base + Vector2(376, 232),
		base + Vector2(390, 248),
		base + Vector2(380, 290),
		base + Vector2(265, 322)
	])
	for i in range(profile_pts.size() - 1):
		draw_line(profile_pts[i] + Vector2(4, 0), profile_pts[i + 1] + Vector2(4, 0), Color(1.0, 0.86, 0.22, 0.90 * p_alpha), 6.5)
		draw_line(profile_pts[i], profile_pts[i + 1], ink_col, 6.5)

	# (g) 前方高聳立領大衣 (遮住下巴底部，製造深沉立體感)
	var collar_poly := PackedVector2Array([
		base + Vector2(145, 255),
		base + Vector2(348, 272),
		base + Vector2(330, 368),
		base + Vector2(115, 368)
	])
	draw_colored_polygon(collar_poly, Color(0.11, 0.13, 0.24, 0.98 * p_alpha))
	draw_line(base + Vector2(145, 255), base + Vector2(348, 272), Color(0.95, 0.78, 0.20, 0.96 * p_alpha), 5.0)
	draw_line(base + Vector2(145, 255), base + Vector2(348, 272), ink_col, 2.5)

	# (h) 頂部與後方壓低帽簷戰盔 + 黑紫尖刺髮束
	var hat_dark := Color(0.10, 0.11, 0.22, 0.99 * p_alpha)
	var hat_mid := Color(0.22, 0.26, 0.48, 0.98 * p_alpha)
	var hat_poly := PackedVector2Array([
		base + Vector2(0, 62),
		base + Vector2(78, 12),
		base + Vector2(145, -18),
		base + Vector2(395, -18),
		base + Vector2(488, 138),  # 超長壓低帽簷尖端
		base + Vector2(468, 156),  # 帽簷下緣
		base + Vector2(275, 86),
		base + Vector2(95, 148),
		base + Vector2(0, 125)
	])
	draw_colored_polygon(hat_poly, hat_dark)

	var visor_poly := PackedVector2Array([
		base + Vector2(245, 32),
		base + Vector2(395, -12),
		base + Vector2(488, 138),
		base + Vector2(468, 156),
		base + Vector2(285, 76)
	])
	draw_colored_polygon(visor_poly, hat_mid)
	draw_line(base + Vector2(245, 32), base + Vector2(488, 138), Color(0.48, 0.45, 1.0, 0.96 * p_alpha), 5.0)
	draw_line(base + Vector2(225, 58), base + Vector2(468, 156), ink_col, 6.5)

	# 帽冠上的黃金紋章飾牌
	var badge_poly := PackedVector2Array([
		base + Vector2(318, -14),
		base + Vector2(382, -14),
		base + Vector2(368, 46),
		base + Vector2(304, 38)
	])
	draw_colored_polygon(badge_poly, Color(0.98, 0.80, 0.18, 0.98 * p_alpha))
	for i in range(badge_poly.size()):
		draw_line(badge_poly[i], badge_poly[(i + 1) % badge_poly.size()], ink_col, 4.0)


func _draw_right_boss_rush_text(master_alpha: float) -> void:
	var t_alpha := clampf(text_slide, 0.0, 1.0) * master_alpha
	# 從右側 +500px 猛烈撞入至右側定位 0
	var x_off := (1.0 - text_slide) * 500.0
	var base := Vector2(x_off, 0.0)
	var font := ThemeDB.fallback_font
	if font == null:
		return

	# 1. 文字背後的斜切黑金衝擊底板 (讓「BOSS RUSH!!!」在任何背景上都極度搶眼)
	var plate_outer := PackedVector2Array([
		base + Vector2(355, 295),
		base + Vector2(720, 265),
		base + Vector2(720, 515),
		base + Vector2(315, 535)
	])
	draw_colored_polygon(plate_outer, Color(0.04, 0.02, 0.06, 0.92 * t_alpha))
	draw_line(plate_outer[0], plate_outer[1], Color(1.0, 0.85, 0.2, t_alpha), 5.0)
	draw_line(plate_outer[3], plate_outer[2], Color(1.0, 0.35, 0.15, t_alpha), 5.0)
	draw_line(plate_outer[0], plate_outer[3], Color(1.0, 0.85, 0.2, t_alpha), 6.0)

	# 內部閃電斜切裝飾色塊
	var slash_accent := PackedVector2Array([
		base + Vector2(375, 310),
		base + Vector2(710, 282),
		base + Vector2(695, 345),
		base + Vector2(360, 365)
	])
	draw_colored_polygon(slash_accent, Color(0.85, 0.12, 0.22, 0.65 * t_alpha))

	# 2. 繪製超巨型「BOSS」與「RUSH!!!」雙層爆裂字體
	var pos_boss := base + Vector2(395, 392)
	var pos_rush := base + Vector2(355, 476)

	# 立體深紅黑陰影位移
	draw_string(font, pos_boss + Vector2(6, 6), "BOSS", HORIZONTAL_ALIGNMENT_LEFT, -1, 68, Color(0.45, 0.05, 0.1, t_alpha))
	draw_string_outline(font, pos_boss, "BOSS", HORIZONTAL_ALIGNMENT_LEFT, -1, 68, 14, Color(0.04, 0.02, 0.05, t_alpha))
	draw_string(font, pos_boss, "BOSS", HORIZONTAL_ALIGNMENT_LEFT, -1, 68, Color(1.0, 0.94, 0.35, t_alpha))

	draw_string(font, pos_rush + Vector2(7, 7), "RUSH!!!", HORIZONTAL_ALIGNMENT_LEFT, -1, 76, Color(0.55, 0.05, 0.08, t_alpha))
	draw_string_outline(font, pos_rush, "RUSH!!!", HORIZONTAL_ALIGNMENT_LEFT, -1, 76, 16, Color(0.04, 0.02, 0.05, t_alpha))
	var rush_col := Color(1.0, 0.55, 0.12, t_alpha).lerp(Color(1.0, 0.92, 0.3, t_alpha), (sin(anim_time * 20.0) + 1.0) * 0.5)
	draw_string(font, pos_rush, "RUSH!!!", HORIZONTAL_ALIGNMENT_LEFT, -1, 76, rush_col)

	# 3. 底部副標「⚡ FEVER TIME - 2X SPEED ⚡」
	var pos_sub := base + Vector2(372, 514)
	draw_string_outline(font, pos_sub, "⚡ FEVER TIME • 2X SPEED ⚡", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 6, Color(0.0, 0.0, 0.0, t_alpha))
	draw_string(font, pos_sub, "⚡ FEVER TIME • 2X SPEED ⚡", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.45, 0.95, 1.0, t_alpha))
