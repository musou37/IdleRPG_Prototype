class_name RushChestCutIn
extends Control

signal chest_sequence_finished

var is_playing: bool = false
var anim_time: float = 0.0
var banner_alpha: float = 0.0
var flash_alpha: float = 0.0
var chest_scale_vec: Vector2 = Vector2.ZERO
var chest_shake: float = 0.0
var seam_glow: float = 0.0         # 0.0 -> 1.0 開箱前寶箱縫隙與鎖頭凝聚外洩的強光
var open_burst_progress: float = 0.0 # 0.0 -> 1.0 開箱瞬間的沖天光柱與震波擴散進度
var is_opened: bool = false

var chest_tier: int = 1 # 1: 華麗寶箱, 2: 奢華寶箱, 3: 究極寶箱
var chest_name: String = "華麗寶箱"
var rush_kills: int = 0
var reward_items: Array[EquipmentData] = []
var _tween: Tween = null

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

func play_chest_cut_in(reward_data: Dictionary) -> void:
	if not reward_data.get("has_chest", false):
		return

	if _tween != null and _tween.is_valid():
		_tween.kill()

	# 清理可能殘留的舊掉落物節點
	for child in get_children():
		child.queue_free()

	chest_tier = reward_data.get("chest_tier", 1)
	chest_name = reward_data.get("chest_name", "華麗寶箱")
	rush_kills = reward_data.get("kills", 3)
	reward_items.clear()
	var raw_items: Array = reward_data.get("items", [])
	for it in raw_items:
		if it is EquipmentData:
			reward_items.append(it)

	is_playing = true
	is_opened = false
	visible = true
	anim_time = 0.0
	banner_alpha = 0.0
	flash_alpha = 0.65
	chest_scale_vec = Vector2(0.2, 0.2)
	chest_shake = 0.0
	seam_glow = 0.0
	open_burst_progress = 0.0

	# ⏸️ 寶箱演出期間暫停背後戰鬥與時間流速
	Engine.time_scale = 1.0
	get_tree().paused = true

	var center_pos := Vector2(360.0, 420.0)

	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	# 階段 1：最上層中央 Cut-In 橫幅展開 + 「緊閉上鎖的寶箱」重重砸落登場 (0.0s -> 0.34s)
	_tween.tween_property(self, "banner_alpha", 1.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "chest_scale_vec", Vector2(1.18, 0.86), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "chest_scale_vec", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	# 階段 2：緊閉寶箱劇烈震動蓄力 + 縫隙與鎖扣迸發刺眼光芒 (0.55s)
	_tween.tween_property(self, "chest_shake", 18.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.parallel().tween_property(self, "seam_glow", 1.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# 階段 3：開箱前極限下壓蓄力 (Squash 0.14s) -> 轟然掀蓋爆開 (Stretch + Lid Pop + 沖天光柱 + 拋物線噴裝！)
	_tween.tween_property(self, "chest_scale_vec", Vector2(1.34, 0.66), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_callback(func():
		is_opened = true
		chest_shake = 0.0
		seam_glow = 0.0
		flash_alpha = 1.0
		# 瞬間縱向彈起掀開寶箱蓋！
		chest_scale_vec = Vector2(0.76, 1.38)
		_spawn_chest_loot_fountain(center_pos + Vector2(0, -15))
	)
	_tween.tween_property(self, "chest_scale_vec", Vector2(1.08, 1.08), 0.32).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "open_burst_progress", 1.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 階段 4：停留展示開啟的寶箱與滿地閃耀神裝飛入背包 (約 1.65s 後退場並恢復戰鬥)
	_tween.tween_interval(1.55)
	_tween.tween_property(self, "banner_alpha", 0.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.parallel().tween_property(self, "chest_scale_vec", Vector2.ZERO, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_finish_chest_cut_in)
	queue_redraw()


func _finish_chest_cut_in() -> void:
	is_playing = false
	visible = false
	is_opened = false
	banner_alpha = 0.0
	flash_alpha = 0.0
	get_tree().paused = false
	if GameManager.is_boss_rush:
		Engine.time_scale = 2.0
	else:
		Engine.time_scale = 1.0
	chest_sequence_finished.emit()


func _spawn_chest_loot_fountain(origin_pos: Vector2) -> void:
	var count := reward_items.size()
	if count == 0:
		return

	for i in range(count):
		var item: EquipmentData = reward_items[i]
		var fx := DroppedItemFX.new(item)
		fx.process_mode = Node.PROCESS_MODE_ALWAYS
		fx.position = origin_pos - Vector2(28, 28)
		fx.scale = Vector2(0.35, 0.35)
		fx.modulate.a = 0.0
		add_child(fx)

		# 依道具數量扇形均勻展開落點 (在畫面正中央橫幅帶 x: 95 ~ 625 之間呈扇形噴發)
		var spread_ratio := 0.5 if count == 1 else float(i) / float(count - 1)
		var base_land_x := lerpf(115.0, 605.0, spread_ratio)
		var land_x := clampf(base_land_x + randf_range(-18.0, 18.0) - 28.0, 65.0, 615.0)
		var ground_y := 515.0 + randf_range(-14.0, 16.0)
		var apex_y := origin_pos.y - randf_range(125.0, 175.0)
		var delay := i * 0.06 # 連續噴發節奏感

		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		if delay > 0.0:
			tw.tween_interval(delay)

		# 1. 從打開的寶箱內部向上拋物線噴出並彈跳落地
		tw.tween_property(fx, "modulate:a", 1.0, 0.10)
		tw.parallel().tween_property(fx, "scale", Vector2(1.24, 1.24), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(fx, "position:x", land_x, 0.46).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(fx, "position:y", apex_y, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.chain().tween_property(fx, "position:y", ground_y, 0.26).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(fx, "scale", Vector2(1.05, 1.05), 0.24)

		# 2. 觸地瞬間彈出裝備品階與名稱浮動文字
		tw.chain().tween_callback(func():
			_spawn_cut_in_floating_label(Vector2(land_x - 30.0, ground_y - 26.0), "[%s] %s" % [item.get_rarity_name(), item.item_name], item.get_rarity_color())
		)

		# 3. 在畫面上閃耀停留供玩家欣賞，接著飛入下方背包區
		tw.chain().tween_interval(0.75)
		var bag_target := Vector2(360.0 - 28.0, 680.0)
		tw.chain().tween_property(fx, "position", bag_target, 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(fx, "scale", Vector2(0.35, 0.35), 0.36)
		tw.parallel().tween_property(fx, "modulate:a", 0.0, 0.36)

		# 4. 實際寫入背包並通知 UI 更新
		tw.chain().tween_callback(func():
			GameManager.inventory.append(item)
			GameManager.equipment_changed.emit()
			fx.queue_free()
		)


func _spawn_cut_in_floating_label(pos: Vector2, text: String, col: Color) -> void:
	var lbl := Label.new()
	lbl.process_mode = Node.PROCESS_MODE_ALWAYS
	lbl.text = text
	lbl.position = pos
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 5)
	add_child(lbl)

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", pos.y - 36.0, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.85).set_delay(0.25)
	tw.chain().tween_callback(lbl.queue_free)


func _process(delta: float) -> void:
	if not is_playing:
		return
	anim_time += delta
	if flash_alpha > 0.0:
		flash_alpha = maxf(0.0, flash_alpha - delta * 3.2)
	queue_redraw()


func _draw() -> void:
	if not is_playing:
		return

	var a := clampf(banner_alpha, 0.0, 1.0)
	var center := Vector2(360.0, 420.0)

	# 1. 全螢幕半透明暗轉背景 (暫停戰鬥並凸顯正中央的寶箱開箱演出)
	draw_rect(Rect2(0, 0, 720, 960), Color(0.02, 0.02, 0.06, 0.76 * a))

	# 2. 依寶箱階級決定主題配色 (1: 華麗藍金, 2: 奢華紫紅金, 3: 究極幻彩聖金)
	var theme_bg := Color(0.08, 0.16, 0.36, 0.96 * a)
	var theme_border := Color(0.35, 0.78, 1.0, a)
	var ray_col := Color(1.0, 0.86, 0.30, 0.28 * a)
	if chest_tier == 2:
		theme_bg = Color(0.28, 0.06, 0.22, 0.96 * a)
		theme_border = Color(1.0, 0.65, 0.18, a)
		ray_col = Color(1.0, 0.55, 0.15, 0.34 * a)
	elif chest_tier >= 3:
		var hue := fmod(anim_time * 0.45, 1.0)
		theme_bg = Color(0.22, 0.08, 0.32, 0.96 * a)
		theme_border = Color.from_hsv(hue, 0.75, 1.0, a)
		ray_col = Color.from_hsv(fmod(hue + 0.15, 1.0), 0.65, 1.0, 0.38 * a)

	# 3. 位於畫面正中央的 Cut-In 橫幅舞台 (y = 210 ~ 605)
	var band_rect := Rect2(0, 210, 720, 395)
	draw_rect(band_rect, theme_bg)
	draw_line(Vector2(0, 210), Vector2(720, 210), Color(0.04, 0.02, 0.06, a), 10.0)
	draw_line(Vector2(0, 210), Vector2(720, 210), theme_border, 4.5)
	draw_line(Vector2(0, 605), Vector2(720, 605), Color(0.04, 0.02, 0.06, a), 10.0)
	draw_line(Vector2(0, 605), Vector2(720, 605), theme_border, 4.5)

	# 4. 寶箱背後的旋轉聖光放射條 (開箱後轉速加快、光芒放大)
	var ray_count := 12 if chest_tier < 3 else 16
	var rot_speed := 1.6 if is_opened else 0.7
	for i in range(ray_count):
		var ang := (TAU / float(ray_count)) * i + anim_time * rot_speed
		var half_w := 0.10 if is_opened else 0.07
		var r_len := 255.0 if is_opened else 190.0
		var p1 := center + Vector2(cos(ang - half_w), sin(ang - half_w)) * r_len
		var p2 := center + Vector2(cos(ang + half_w), sin(ang + half_w)) * r_len
		draw_colored_polygon(PackedVector2Array([center, p1, p2]), ray_col)

	# 5. 開箱瞬間的沖天光柱與震波環 (在寶箱掀蓋瞬間爆發)
	if is_opened and open_burst_progress < 1.0:
		var burst_alpha := (1.0 - open_burst_progress) * a
		var pillar_w := lerpf(160.0, 45.0, open_burst_progress)
		var pillar_col := Color(1.0, 0.95, 0.55, 0.75 * burst_alpha)
		draw_rect(Rect2(center.x - pillar_w * 0.5, 210.0, pillar_w, 220.0), pillar_col, true)
		# 擴散震波光環
		var ring_radius := lerpf(40.0, 240.0, open_burst_progress)
		draw_arc(center, ring_radius, 0.0, TAU, 40, Color(1.0, 0.92, 0.4, 0.85 * burst_alpha), 8.0 * (1.0 - open_burst_progress) + 2.0)

	# 6. 繪製正中央巨型寶箱 (開箱前顯示「緊閉上鎖寶箱 + 縫隙蓄力強光」，開箱瞬間切換「掀蓋爆光寶箱」！)
	if chest_scale_vec.length() > 0.02:
		var shake_offset := Vector2(sin(anim_time * 65.0) * chest_shake, cos(anim_time * 52.0) * chest_shake * 0.45)
		var chest_center := center + shake_offset
		var c_tex := AssetLoader.get_chest_texture(chest_tier, is_opened)
		if c_tex != null:
			var base_sz := Vector2(235.0 * chest_scale_vec.x, 235.0 * chest_scale_vec.y)
			var c_rect := Rect2(chest_center - base_sz * 0.5, base_sz)
			if is_opened:
				draw_circle(chest_center, 118.0 * chest_scale_vec.x, Color(1.0, 0.92, 0.45, 0.38 * a))
			var mod_col := Color(1.0 + seam_glow * 0.65, 1.0 + seam_glow * 0.55, 1.0 + seam_glow * 0.35, a)
			draw_texture_rect(c_tex, c_rect, false, mod_col)

			# 若尚未開啟但正在蓄力 (seam_glow > 0)，在寶箱縫隙與鎖扣處繪製迸發的十字裂縫金光！
			if not is_opened and seam_glow > 0.02:
				var lock_pos := chest_center + Vector2(0, 12)
				var g_len := 45.0 + seam_glow * 95.0
				var g_col := Color(1.0, 0.95, 0.45, seam_glow * a)
				draw_line(lock_pos - Vector2(g_len, 0), lock_pos + Vector2(g_len, 0), g_col, 4.0 + seam_glow * 5.0)
				draw_line(lock_pos - Vector2(0, g_len * 0.6), lock_pos + Vector2(0, g_len * 0.6), g_col, 3.0 + seam_glow * 4.0)
				draw_circle(lock_pos, 10.0 + seam_glow * 18.0, Color(1.0, 1.0, 0.85, seam_glow * 0.9 * a))
		else:
			_draw_procedural_chest(chest_center, chest_scale_vec, a)

	# 7. 繪製頂部與底部 Cut-In 炫耀標題文字
	var font := ThemeDB.fallback_font
	if font != null:
		var top_str := "⚡ BOSS RUSH %d KILL 達成獎勵 ⚡" % rush_kills
		draw_string_outline(font, Vector2(0, 255), top_str, HORIZONTAL_ALIGNMENT_CENTER, 720, 22, 7, Color(0, 0, 0, a))
		draw_string(font, Vector2(0, 255), top_str, HORIZONTAL_ALIGNMENT_CENTER, 720, 22, Color(1.0, 0.92, 0.4, a))

		var title_str := ""
		if not is_opened:
			title_str = "🔒 獲得【%s】！正在解鎖開啟..." % chest_name
		else:
			title_str = "🎁 【%s】開啟！(噴發 %d 件神裝)" % [chest_name, reward_items.size()]
		var title_col := Color(0.45, 0.92, 1.0, a) if chest_tier == 1 else (Color(1.0, 0.72, 0.22, a) if chest_tier == 2 else Color.from_hsv(fmod(anim_time * 0.8, 1.0), 0.55, 1.0, a))
		draw_string_outline(font, Vector2(0, 298), title_str, HORIZONTAL_ALIGNMENT_CENTER, 720, 32, 10, Color(0, 0, 0, a))
		draw_string(font, Vector2(0, 298), title_str, HORIZONTAL_ALIGNMENT_CENTER, 720, 32, title_col)

	# 8. 開箱瞬間閃白特效
	if flash_alpha > 0.0:
		draw_rect(Rect2(0, 0, 720, 960), Color(1.0, 0.98, 0.88, flash_alpha * 0.68))


func _draw_procedural_chest(c_pos: Vector2, sc_vec: Vector2, alpha: float) -> void:
	# [備案 Fallback] 原生程式幾何寶箱繪製（包含箱蓋掀開動畫）
	var w := 145.0 * sc_vec.x
	var h := 70.0 * sc_vec.y
	var lid_h := 42.0 * sc_vec.y
	var body_col := Color(0.18, 0.42, 0.85, alpha) if chest_tier == 1 else (Color(0.62, 0.14, 0.45, alpha) if chest_tier == 2 else Color(0.95, 0.92, 1.0, alpha))
	var gold_col := Color(1.0, 0.82, 0.22, alpha)
	var dark_col := Color(0.08, 0.05, 0.10, alpha)

	# 下半部箱身
	var base_rect := Rect2(c_pos.x - w * 0.5, c_pos.y - h * 0.2, w, h)
	if is_opened:
		# 箱內黃金寶藏光芒
		draw_circle(Vector2(c_pos.x, base_rect.position.y), 52.0 * sc_vec.x, Color(1.0, 0.95, 0.35, 0.9 * alpha))
	draw_rect(base_rect, body_col, true)
	draw_rect(base_rect, gold_col, false, 5.0)
	draw_rect(base_rect.grow(2.0), dark_col, false, 2.5)

	# 上半部箱蓋 (開啟時向上掀起位移)
	var lid_offset_y := -34.0 * sc_vec.y if is_opened else 0.0
	var lid_rect := Rect2(c_pos.x - w * 0.52, base_rect.position.y - lid_h + lid_offset_y, w * 1.04, lid_h)
	draw_rect(lid_rect, body_col.lightened(0.12), true)
	draw_rect(lid_rect, gold_col, false, 5.0)
	draw_rect(lid_rect.grow(2.0), dark_col, false, 2.5)

	# 中央鎖頭
	if not is_opened:
		draw_rect(Rect2(c_pos.x - 14 * sc_vec.x, base_rect.position.y - 12 * sc_vec.y, 28 * sc_vec.x, 28 * sc_vec.y), gold_col, true)
