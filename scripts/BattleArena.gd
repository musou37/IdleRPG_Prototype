extends Node2D

const ATTACK_POSE_DURATION := 0.24

# 角色與怪物的視覺舞台繪製節點
var hero_pos := Vector2(185, 215)
var enemy_pos := Vector2(535, 215)
var hero_offset := Vector2.ZERO
var enemy_offset := Vector2.ZERO
var hero_flash: float = 0.0
var enemy_flash: float = 0.0
var hero_attack_timer: float = 0.0
var enemy_attack_timer: float = 0.0
var enemy_color := Color(0.35, 0.85, 0.45)
var enemy_is_boss := false
var enemy_title: String = ""
var slash_alpha: float = 0.0
var slash_pos := Vector2.ZERO
var is_reviving: bool = false
var revive_ratio: float = 0.0
var is_boss_rush: bool = false
var fever_anim_timer: float = 0.0

func _process(delta: float) -> void:
	var need_redraw := false
	if is_boss_rush:
		fever_anim_timer += delta
		need_redraw = true
	if hero_attack_timer > 0.0:
		hero_attack_timer = maxf(0.0, hero_attack_timer - delta)
		need_redraw = true
	if enemy_attack_timer > 0.0:
		enemy_attack_timer = maxf(0.0, enemy_attack_timer - delta)
		need_redraw = true
	if hero_flash > 0.0:
		hero_flash = maxf(0.0, hero_flash - delta * 4.0)
		need_redraw = true
	if enemy_flash > 0.0:
		enemy_flash = maxf(0.0, enemy_flash - delta * 4.0)
		need_redraw = true
	if slash_alpha > 0.0:
		slash_alpha = maxf(0.0, slash_alpha - delta * 3.5)
		need_redraw = true
	if hero_offset != Vector2.ZERO or enemy_offset != Vector2.ZERO or is_reviving:
		need_redraw = true
	if need_redraw:
		queue_redraw()

func trigger_hero_attack() -> void:
	hero_attack_timer = ATTACK_POSE_DURATION
	queue_redraw()
	var tw := create_tween()
	tw.tween_property(self, "hero_offset", Vector2(45, -8), 0.08).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "hero_offset", Vector2.ZERO, 0.16).set_trans(Tween.TRANS_QUAD)

func trigger_enemy_attack() -> void:
	enemy_attack_timer = ATTACK_POSE_DURATION
	queue_redraw()
	var tw := create_tween()
	tw.tween_property(self, "enemy_offset", Vector2(-45, -6), 0.08).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "enemy_offset", Vector2.ZERO, 0.16).set_trans(Tween.TRANS_QUAD)

func trigger_enemy_hit(is_skill: bool = false) -> void:
	enemy_flash = 1.0
	if is_skill:
		slash_alpha = 1.0
		slash_pos = enemy_pos
	queue_redraw()

func trigger_hero_hit() -> void:
	hero_flash = 1.0
	queue_redraw()

func _draw() -> void:
	# 1. 戰鬥舞台背景：優先載入正式美術圖 (assets/backgrounds/bg_normal.png 或 bg_boss_rush.png)，無則退回幾何背景
	var bg_path := AssetLoader.PATH_BG_BOSS_RUSH if is_boss_rush else AssetLoader.PATH_BG_NORMAL
	var bg_tex := AssetLoader.get_texture(bg_path)
	if bg_tex != null:
		var bg_mod := Color.WHITE
		if is_boss_rush:
			var pulse := (sin(fever_anim_timer * 5.0) + 1.0) * 0.5
			bg_mod = Color(1.0, 0.88, 0.88).lerp(Color(1.15, 0.98, 0.92), pulse)
		draw_texture_rect(bg_tex, Rect2(0, 0, 720, 310), false, bg_mod)
	else:
		# [備案 Fallback] 原生程式幾何背景與草地舞台
		var sky_color := Color(0.11, 0.14, 0.22)
		if is_boss_rush:
			var pulse := (sin(fever_anim_timer * 5.0) + 1.0) * 0.5
			sky_color = Color(0.28, 0.06, 0.16).lerp(Color(0.42, 0.12, 0.22), pulse)
		draw_rect(Rect2(0, 0, 720, 310), sky_color)
		draw_rect(Rect2(0, 235, 720, 75), Color(0.16, 0.26, 0.18, 1.0))
		draw_line(Vector2(0, 235), Vector2(720, 235), Color(0.28, 0.45, 0.30), 3.0)

	# FEVER 邊框光暈與動態火焰粒子光線
	if is_boss_rush:
		var border_alpha := 0.35 + (sin(fever_anim_timer * 6.0) + 1.0) * 0.25
		var border_color := Color(1.0, 0.65, 0.15, border_alpha)
		# 頂部與四邊發光框
		draw_rect(Rect2(2, 2, 716, 306), border_color, false, 3.5)
		draw_rect(Rect2(6, 6, 708, 298), Color(1.0, 0.25, 0.1, border_alpha * 0.5), false, 2.0)
		# 漂浮的狂熱火星 (假粒子)
		for p_i in range(8):
			var px := fmod(100.0 * p_i + fever_anim_timer * 65.0, 700.0) + 10.0
			var py := 220.0 - fmod(fever_anim_timer * 40.0 + p_i * 28.0, 180.0)
			var spark_col := Color(1.0, 0.85, 0.2, 0.6 + sin(fever_anim_timer * 5.0 + p_i) * 0.3)
			draw_circle(Vector2(px, py), 2.5 + (p_i % 3), spark_col)

	# 2. 繪製勇者：攻擊時切換為攻擊動作圖片 (hero_attack.png)，平時為待機圖 (hero.png)
	var hp_center := hero_pos + hero_offset
	var hero_alpha := 0.45 if is_reviving else 1.0
	var is_hero_attacking := (hero_attack_timer > 0.0 and not is_reviving)
	# 陰影
	draw_circle(Vector2(hp_center.x, 244), 32, Color(0, 0, 0, 0.42))
	# 復活詠唱魔法陣與光柱特效
	if is_reviving:
		draw_arc(Vector2(hp_center.x, 244), 42.0, 0.0, TAU, 32, Color(0.3, 0.85, 1.0, 0.35), 2.5)
		draw_arc(Vector2(hp_center.x, 244), 42.0, -PI * 0.5, -PI * 0.5 + TAU * revive_ratio, 32, Color(0.4, 1.0, 0.65, 0.95), 4.5)
		draw_rect(Rect2(hp_center.x - 28, hp_center.y - 100, 56, 128), Color(0.35, 0.9, 1.0, 0.12 + 0.15 * revive_ratio))

	var hero_tex := AssetLoader.get_hero_texture(is_hero_attacking)
	if hero_tex != null:
		var h_size := Vector2(158, 158) if is_hero_attacking else Vector2(138, 138)
		var h_rect := Rect2(hp_center - Vector2(h_size.x * 0.46 if is_hero_attacking else h_size.x * 0.5, h_size.y - 32), h_size)
		var h_mod := Color(1.0 + hero_flash * 2.2, 1.0 + hero_flash * 2.2, 1.0 + hero_flash * 2.2, hero_alpha)
		draw_texture_rect(hero_tex, h_rect, false, h_mod)
	else:
		# [備案 Fallback] 原生程式幾何勇者小人（含攻擊揮砍與武器拖曳刀光）
		var h_col := Color(0.25, 0.65, 1.0, hero_alpha).lerp(Color.WHITE, hero_flash)
		draw_rect(Rect2(hp_center.x - 28, hp_center.y - 38, 22, 52), Color(0.8, 0.2, 0.25, hero_alpha))
		draw_rect(Rect2(hp_center.x - 18, hp_center.y - 42, 36, 56), h_col)
		draw_circle(hp_center + Vector2(0, -60), 20, Color(0.95, 0.82, 0.68, hero_alpha).lerp(Color.WHITE, hero_flash))
		draw_rect(Rect2(hp_center.x - 22, hp_center.y - 82, 44, 16), Color(0.75, 0.8, 0.88, hero_alpha))
		if is_hero_attacking:
			# 揮劍下斬姿勢 + 半月形拖曳刀光
			draw_line(hp_center + Vector2(18, -18), hp_center + Vector2(68, 10), Color(0.9, 0.95, 1.0, hero_alpha), 7.0)
			draw_arc(hp_center + Vector2(12, -28), 62.0, -PI * 0.42, PI * 0.22, 20, Color(0.3, 0.85, 1.0, 0.85), 14.0)
			draw_arc(hp_center + Vector2(12, -28), 65.0, -PI * 0.38, PI * 0.18, 20, Color(1.0, 1.0, 1.0, 0.95), 6.0)
		else:
			draw_line(hp_center + Vector2(20, -15), hp_center + Vector2(62, -55), Color(0.9, 0.95, 1.0, hero_alpha), 6.0)
			draw_line(hp_center + Vector2(14, -22), hp_center + Vector2(28, -8), Color(0.95, 0.75, 0.2, hero_alpha), 5.0)

	# 3. 繪製怪物：攻擊時切換為攻擊動作圖片 (monster_*_attack.png)，平時為待機圖
	var ep_center := enemy_pos + enemy_offset
	var scale_mult := 1.28 if enemy_is_boss else 1.0
	var is_enemy_attacking := (enemy_attack_timer > 0.0)
	# 陰影
	draw_circle(Vector2(ep_center.x, 244), 34 * scale_mult, Color(0, 0, 0, 0.42))

	var enemy_tex := AssetLoader.get_monster_texture(enemy_title, enemy_is_boss, is_enemy_attacking)
	if enemy_tex != null:
		var e_size := (Vector2(152, 152) if is_enemy_attacking else Vector2(132, 132)) * scale_mult
		var e_rect := Rect2(ep_center - Vector2(e_size.x * 0.54 if is_enemy_attacking else e_size.x * 0.5, e_size.y - 32), e_size)
		var e_mod := Color(1.0 + enemy_flash * 2.2, 1.0 + enemy_flash * 2.2, 1.0 + enemy_flash * 2.2, 1.0)
		draw_texture_rect(enemy_tex, e_rect, false, e_mod)
	else:
		# [備案 Fallback] 原生程式幾何怪物（含攻擊揮擊與武器拖曳刀光）
		var e_col := enemy_color.lerp(Color.WHITE, enemy_flash)
		var body_size := Vector2(56, 56) * scale_mult
		draw_rect(Rect2(ep_center - Vector2(body_size.x * 0.5, body_size.y - 14), body_size), e_col)
		if enemy_is_boss:
			draw_line(ep_center + Vector2(-24, -55), ep_center + Vector2(-42, -88), Color(0.95, 0.8, 0.2), 6.0)
			draw_line(ep_center + Vector2(24, -55), ep_center + Vector2(42, -88), Color(0.95, 0.8, 0.2), 6.0)
		draw_circle(ep_center + Vector2(-12 * scale_mult, -22 * scale_mult), 6 * scale_mult, Color(1.0, 0.2, 0.2))
		draw_circle(ep_center + Vector2(8 * scale_mult, -22 * scale_mult), 6 * scale_mult, Color(1.0, 0.2, 0.2))
		if is_enemy_attacking:
			var trail_col := Color(1.0, 0.32, 0.15, 0.88) if enemy_is_boss else Color(1.0, 0.65, 0.18, 0.85)
			draw_arc(ep_center + Vector2(-12 * scale_mult, -26 * scale_mult), 58.0 * scale_mult, PI * 0.78, PI * 1.42, 20, trail_col, 13.0 * scale_mult)
			draw_arc(ep_center + Vector2(-12 * scale_mult, -26 * scale_mult), 61.0 * scale_mult, PI * 0.82, PI * 1.38, 20, Color(1.0, 0.95, 0.65, 0.95), 5.5 * scale_mult)

	# 主動技能斬擊特效
	if slash_alpha > 0.0:
		var s_col := Color(1.0, 0.55, 0.15, slash_alpha)
		draw_line(slash_pos + Vector2(-55, -65), slash_pos + Vector2(55, 35), s_col, 8.0)
		draw_line(slash_pos + Vector2(55, -65), slash_pos + Vector2(-55, 35), s_col, 8.0)
