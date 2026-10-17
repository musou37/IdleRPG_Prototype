extends SceneTree

const ARTIFACT_DIR := "C:/Users/Lin/.gemini/antigravity/brain/7b18309c-e9da-4455-bcca-ec22ae207d19/"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/cutin"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/backgrounds"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/sprites"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/icons"))

	# 1. 處理戰鬥背景 (裁切為 720x310 寬銀幕比例)
	_process_background(ARTIFACT_DIR + "bg_normal_1792250520533.jpg", "res://assets/backgrounds/bg_normal.png")
	_process_background(ARTIFACT_DIR + "bg_boss_rush_1792250540498.jpg", "res://assets/backgrounds/bg_boss_rush.png")

	# 2. 處理去背立繪、角色與怪物小人、裝備 ICON
	_process_cutout_sprite(ARTIFACT_DIR + "hero_cutin_raw_1792250525758.jpg", "res://assets/cutin/hero_cutin.png", 440, 440)
	_process_cutout_sprite(ARTIFACT_DIR + "hero_raw_png_1792250520681.jpg", "res://assets/sprites/hero.png", 256, 256)
	_process_cutout_sprite(ARTIFACT_DIR + "monster_normal_raw_png_1792250539911.jpg", "res://assets/sprites/monster_normal.png", 256, 256)
	_process_cutout_sprite(ARTIFACT_DIR + "monster_boss_raw_png_1792250555956.jpg", "res://assets/sprites/monster_boss.png", 280, 280)

	_process_cutout_sprite(ARTIFACT_DIR + "equip_weapon_raw_1792250517934.jpg", "res://assets/icons/equip_weapon.png", 128, 128)
	_process_cutout_sprite(ARTIFACT_DIR + "equip_armor_raw_1792250535704.jpg", "res://assets/icons/equip_armor.png", 128, 128)
	_process_cutout_sprite(ARTIFACT_DIR + "equip_shield_raw_1792250552287.jpg", "res://assets/icons/equip_shield.png", 128, 128)

	_process_cutout_sprite(ARTIFACT_DIR + "chest_ornate_raw_1792251868062.jpg", "res://assets/sprites/chest_ornate.png", 260, 260)
	_process_cutout_sprite(ARTIFACT_DIR + "chest_luxury_raw_1792251883274.jpg", "res://assets/sprites/chest_luxury.png", 260, 260)
	_process_cutout_sprite(ARTIFACT_DIR + "chest_ultimate_raw_1792251902403.jpg", "res://assets/sprites/chest_ultimate.png", 280, 280)

	_process_cutout_sprite(ARTIFACT_DIR + "chest_ornate_closed_raw_1792252474108.jpg", "res://assets/sprites/chest_ornate_closed.png", 260, 260)
	_generate_closed_chest_variants("res://assets/sprites/chest_ornate_closed.png")

	print("[AssetProcessor] 所有美術素材去背與轉檔完成！")
	quit(0)

func _generate_closed_chest_variants(base_closed_res: String) -> void:
	var base_img := Image.load_from_file(ProjectSettings.globalize_path(base_closed_res))
	if base_img == null or base_img.is_empty():
		return
	var w := base_img.get_width()
	var h := base_img.get_height()

	# 1. 奢華寶箱關閉狀態 (紫紅寶石與暗金配色)
	var lux_img := base_img.duplicate() as Image
	# 2. 究極寶箱關閉狀態 (天界聖白金與幻彩菱鏡配色)
	var ult_img := base_img.duplicate() as Image
	ult_img.resize(280, 280, Image.INTERPOLATE_LANCZOS)

	for y in range(h):
		for x in range(w):
			var c := lux_img.get_pixel(x, y)
			if c.a <= 0.01:
				continue
			# 若為藍色系木板/寶石區域 (Hue 約在 0.50 ~ 0.72)，轉換為奢華紫紅色系 (Hue 0.86 ~ 0.96)
			if c.h >= 0.48 and c.h <= 0.74 and c.s > 0.20:
				var new_h := fmod(0.85 + (c.h - 0.50) * 0.45, 1.0)
				lux_img.set_pixel(x, y, Color.from_hsv(new_h, minf(1.0, c.s * 1.1), c.v, c.a))

	var uw := ult_img.get_width()
	var uh := ult_img.get_height()
	for y in range(uh):
		for x in range(uw):
			var c := ult_img.get_pixel(x, y)
			if c.a <= 0.01:
				continue
			if c.h >= 0.48 and c.h <= 0.74 and c.s > 0.20:
				# 轉換為天界聖白與淡彩稜鏡光澤
				var rainbow_h := fmod(float(x + y) / float(uw + uh) * 1.8, 1.0)
				var new_v := clampf(c.v * 1.55 + 0.18, 0.0, 1.0)
				var new_s := clampf(c.s * 0.38, 0.12, 0.45)
				ult_img.set_pixel(x, y, Color.from_hsv(rainbow_h, new_s, new_v, c.a))

	lux_img.save_png(ProjectSettings.globalize_path("res://assets/sprites/chest_luxury_closed.png"))
	ult_img.save_png(ProjectSettings.globalize_path("res://assets/sprites/chest_ultimate_closed.png"))
	print("[Sprite] 已產生奢華與究極關閉寶箱貼圖！")

func _process_background(src_abs: String, dst_res: String) -> void:
	var img := Image.load_from_file(src_abs)
	if img == null or img.is_empty():
		push_error("無法載入背景: " + src_abs)
		return
	var w := img.get_width()
	var h := img.get_height()
	# 目標比例 720:310 (約 2.322)
	var target_h := int(float(w) * 310.0 / 720.0)
	if target_h < h:
		# 取偏下方區域 (保留平坦地面與中景天空)
		var crop_y := int((h - target_h) * 0.65)
		img = img.get_region(Rect2i(0, crop_y, w, target_h))
	img.resize(720, 310, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path(dst_res))
	print("[BG] 已儲存: ", dst_res)

func _is_bg_white(c: Color) -> bool:
	var lum := (c.r + c.g + c.b) / 3.0
	var max_c := maxf(c.r, maxf(c.g, c.b))
	var min_c := minf(c.r, minf(c.g, c.b))
	var diff := max_c - min_c
	return lum > 0.87 and diff < 0.14

func _process_cutout_sprite(src_abs: String, dst_res: String, out_w: int, out_h: int) -> void:
	var img := Image.load_from_file(src_abs)
	if img == null or img.is_empty():
		push_error("無法載入素材: " + src_abs)
		return

	# 先縮放到 512x512 加速 BFS Flood-Fill 去背運算
	img.resize(512, 512, Image.INTERPOLATE_LANCZOS)
	img.convert(Image.FORMAT_RGBA8)

	var w := img.get_width()
	var h := img.get_height()
	var visited := PackedByteArray()
	visited.resize(w * h)
	visited.fill(0)

	var queue: Array[Vector2i] = []
	for x in range(w):
		queue.append(Vector2i(x, 0))
		queue.append(Vector2i(x, h - 1))
	for y in range(h):
		queue.append(Vector2i(0, y))
		queue.append(Vector2i(w - 1, y))

	# 針對角色與怪物全身圖，將翅膀/披風/手臂縫隙內的封閉純白背景孔洞也加入種子 (避開臉部眼白、牙齒與寶箱內部強光)
	if not dst_res.contains("hero_cutin") and not dst_res.contains("chest_"):
		for y in range(h):
			for x in range(w):
				# 避開角色上半部臉孔眼白區域 (x: 20%~45%, y: 20%~40%)
				if dst_res.contains("hero.png") and x > int(w * 0.18) and x < int(w * 0.45) and y > int(h * 0.22) and y < int(h * 0.38):
					continue
				var c := img.get_pixel(x, y)
				if c.r > 0.96 and c.g > 0.96 and c.b > 0.96:
					queue.append(Vector2i(x, y))

	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		if p.x < 0 or p.x >= w or p.y < 0 or p.y >= h:
			continue
		var idx := p.y * w + p.x
		if visited[idx] == 1:
			continue
		visited[idx] = 1

		var col := img.get_pixel(p.x, p.y)
		if _is_bg_white(col):
			img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
			queue.append(Vector2i(p.x + 1, p.y))
			queue.append(Vector2i(p.x - 1, p.y))
			queue.append(Vector2i(p.x, p.y + 1))
			queue.append(Vector2i(p.x, p.y - 1))

	# 邊緣柔化去白邊 (對緊鄰透明像素的淺灰白邊進行 Alpha 衰減與顏色修正)
	var min_x := w
	var min_y := h
	var max_x := 0
	var max_y := 0

	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				var has_trans_neighbor := (
					img.get_pixel(x + 1, y).a == 0.0 or
					img.get_pixel(x - 1, y).a == 0.0 or
					img.get_pixel(x, y + 1).a == 0.0 or
					img.get_pixel(x, y - 1).a == 0.0
				)
				if has_trans_neighbor:
					var lum := (c.r + c.g + c.b) / 3.0
					if lum > 0.72:
						c.a = clampf((0.92 - lum) / 0.20, 0.0, 0.75)
						c.r *= 0.65
						c.g *= 0.65
						c.b *= 0.65
						img.set_pixel(x, y, c)
				if c.a > 0.05:
					min_x = mini(min_x, x)
					min_y = mini(min_y, y)
					max_x = maxi(max_x, x)
					max_y = maxi(max_y, y)

	# 自動裁切透明邊界並置中塞入正方畫布
	if max_x > min_x and max_y > min_y:
		var pad := 8
		min_x = maxi(0, min_x - pad)
		min_y = maxi(0, min_y - pad)
		max_x = mini(w - 1, max_x + pad)
		max_y = mini(h - 1, max_y + pad)
		var bw := max_x - min_x + 1
		var bh := max_y - min_y + 1
		var cropped := img.get_region(Rect2i(min_x, min_y, bw, bh))

		var side := maxi(bw, bh)
		var square := Image.create(side, side, false, Image.FORMAT_RGBA8)
		square.fill(Color(0, 0, 0, 0))
		var ox := int((side - bw) * 0.5)
		var oy := int((side - bh) * 0.5)
		square.blit_rect(cropped, Rect2i(0, 0, bw, bh), Vector2i(ox, oy))
		square.resize(out_w, out_h, Image.INTERPOLATE_LANCZOS)
		square.save_png(ProjectSettings.globalize_path(dst_res))
	else:
		img.resize(out_w, out_h, Image.INTERPOLATE_LANCZOS)
		img.save_png(ProjectSettings.globalize_path(dst_res))

	print("[Sprite] 已去背並儲存: ", dst_res)
