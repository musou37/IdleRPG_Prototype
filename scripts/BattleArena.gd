extends Node2D

# 角色與怪物的視覺舞台繪製節點
var hero_pos := Vector2(185, 215)
var enemy_pos := Vector2(535, 215)
var hero_offset := Vector2.ZERO
var enemy_offset := Vector2.ZERO
var hero_flash: float = 0.0
var enemy_flash: float = 0.0
var enemy_color := Color(0.35, 0.85, 0.45)
var enemy_is_boss := false
var slash_alpha: float = 0.0
var slash_pos := Vector2.ZERO

func _process(delta: float) -> void:
	var need_redraw := false
	if hero_flash > 0.0:
		hero_flash = maxf(0.0, hero_flash - delta * 4.0)
		need_redraw = true
	if enemy_flash > 0.0:
		enemy_flash = maxf(0.0, enemy_flash - delta * 4.0)
		need_redraw = true
	if slash_alpha > 0.0:
		slash_alpha = maxf(0.0, slash_alpha - delta * 3.5)
		need_redraw = true
	if hero_offset != Vector2.ZERO or enemy_offset != Vector2.ZERO:
		need_redraw = true
	if need_redraw:
		queue_redraw()

func trigger_hero_attack() -> void:
	var tw := create_tween()
	tw.tween_property(self, "hero_offset", Vector2(45, -8), 0.08).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "hero_offset", Vector2.ZERO, 0.14).set_trans(Tween.TRANS_QUAD)

func trigger_enemy_attack() -> void:
	var tw := create_tween()
	tw.tween_property(self, "enemy_offset", Vector2(-45, -6), 0.08).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "enemy_offset", Vector2.ZERO, 0.14).set_trans(Tween.TRANS_QUAD)

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
	# 背景天空與草地舞台
	draw_rect(Rect2(0, 0, 720, 310), Color(0.11, 0.14, 0.22))
	draw_rect(Rect2(0, 235, 720, 75), Color(0.16, 0.26, 0.18))
	draw_line(Vector2(0, 235), Vector2(720, 235), Color(0.28, 0.45, 0.30), 3.0)

	# 繪製勇者 (2D 像素/幾何小人：披風、身體、頭盔、武器與盾牌)
	var hp_center := hero_pos + hero_offset
	var h_col := Color(0.25, 0.65, 1.0).lerp(Color.WHITE, hero_flash)
	# 陰影
	draw_circle(Vector2(hp_center.x, 240), 26, Color(0, 0, 0, 0.35))
	# 披風
	draw_rect(Rect2(hp_center.x - 28, hp_center.y - 38, 22, 52), Color(0.8, 0.2, 0.25))
	# 身體鎧甲
	draw_rect(Rect2(hp_center.x - 18, hp_center.y - 42, 36, 56), h_col)
	# 頭部與騎士頭盔
	draw_circle(hp_center + Vector2(0, -60), 20, Color(0.95, 0.82, 0.68).lerp(Color.WHITE, hero_flash))
	draw_rect(Rect2(hp_center.x - 22, hp_center.y - 82, 44, 16), Color(0.75, 0.8, 0.88))
	# 長劍
	draw_line(hp_center + Vector2(20, -15), hp_center + Vector2(62, -55), Color(0.9, 0.95, 1.0), 6.0)
	draw_line(hp_center + Vector2(14, -22), hp_center + Vector2(28, -8), Color(0.95, 0.75, 0.2), 5.0)

	# 繪製怪物 (依一般怪或 Boss 改變體型與外觀)
	var ep_center := enemy_pos + enemy_offset
	var scale_mult := 1.35 if enemy_is_boss else 1.0
	var e_col := enemy_color.lerp(Color.WHITE, enemy_flash)
	# 陰影
	draw_circle(Vector2(ep_center.x, 240), 28 * scale_mult, Color(0, 0, 0, 0.35))
	# 怪物身體
	var body_size := Vector2(56, 56) * scale_mult
	draw_rect(Rect2(ep_center - Vector2(body_size.x * 0.5, body_size.y - 14), body_size), e_col)
	# 怪物角 (Boss 有雙大角)
	if enemy_is_boss:
		draw_line(ep_center + Vector2(-24, -55), ep_center + Vector2(-42, -88), Color(0.95, 0.8, 0.2), 6.0)
		draw_line(ep_center + Vector2(24, -55), ep_center + Vector2(42, -88), Color(0.95, 0.8, 0.2), 6.0)
	# 怪物眼睛
	draw_circle(ep_center + Vector2(-12 * scale_mult, -22 * scale_mult), 6 * scale_mult, Color(1.0, 0.2, 0.2))
	draw_circle(ep_center + Vector2(8 * scale_mult, -22 * scale_mult), 6 * scale_mult, Color(1.0, 0.2, 0.2))

	# 主動技能斬擊特效
	if slash_alpha > 0.0:
		var s_col := Color(1.0, 0.55, 0.15, slash_alpha)
		draw_line(slash_pos + Vector2(-55, -65), slash_pos + Vector2(55, 35), s_col, 8.0)
		draw_line(slash_pos + Vector2(55, -65), slash_pos + Vector2(-55, 35), s_col, 8.0)
