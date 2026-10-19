extends SceneTree

const BRAIN_DIR := "C:/Users/mmusou37/.gemini/antigravity/brain/64fe54ff-16c8-4719-83b2-7415bb1ee675/"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/sprites"))

	_process_attack_sprite(
		BRAIN_DIR + "hero_attack_dynamic_1792403134253.jpg",
		"res://assets/sprites/hero_attack.png",
		280, 280,
		Rect2(0.47, 0.37, 0.14, 0.07) # 保護勇者頭盔護目鏡內的發光白眼
	)
	_process_attack_sprite(
		BRAIN_DIR + "monster_normal_attack_swing_1792403321091.jpg",
		"res://assets/sprites/monster_normal_attack.png",
		280, 280,
		Rect2(0.43, 0.42, 0.14, 0.12) # 保護哥布林臉部眼睛與牙齒
	)
	_process_attack_sprite(
		BRAIN_DIR + "monster_boss_attack_raw_png_1792402993397.jpg",
		"res://assets/sprites/monster_boss_attack.png",
		300, 300,
		Rect2(0.20, 0.34, 0.20, 0.18) # 保護魔龍臉部與牙齒
	)

	print("[AttackSpriteProcessor] 所有攻擊動作與刀光素材去背完成！")
	quit(0)

func _is_bg_candidate(c: Color) -> bool:
	var max_c := maxf(c.r, maxf(c.g, c.b))
	var min_c := minf(c.r, minf(c.g, c.b))
	var diff := max_c - min_c
	var lum := (c.r + c.g + c.b) / 3.0
	if lum > 0.86 and diff < 0.16:
		return true
	if min_c > 0.82 and lum > 0.89:
		return true
	return false

func _has_nearby_dark_outline(img: Image, x: int, y: int, w: int, h: int) -> bool:
	for dy in range(-3, 4):
		var ny := y + dy
		if ny < 0 or ny >= h:
			continue
		for dx in range(-3, 4):
			var nx := x + dx
			if nx < 0 or nx >= w:
				continue
			var nc := img.get_pixel(nx, ny)
			if nc.r < 0.22 and nc.g < 0.22 and nc.b < 0.22:
				return true
	return false

func _process_attack_sprite(src_abs: String, dst_res: String, out_w: int, out_h: int, protect_uv: Rect2) -> void:
	if not FileAccess.file_exists(src_abs):
		return
	var img := Image.load_from_file(src_abs)
	if img == null or img.is_empty():
		push_error("無法載入攻擊素材: " + src_abs)
		return

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

	var px_rect := Rect2(protect_uv.position.x * w, protect_uv.position.y * h, protect_uv.size.x * w, protect_uv.size.y * h)
	for y in range(4, h - 4, 2):
		for x in range(4, w - 4, 2):
			if px_rect.has_point(Vector2(x, y)):
				continue
			var c := img.get_pixel(x, y)
			if c.r > 0.95 and c.g > 0.95 and c.b > 0.95:
				if _has_nearby_dark_outline(img, x, y, w, h):
					queue.append(Vector2i(x, y))

	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		if p.x < 0 or p.x >= w or p.y < 0 or p.y >= h:
			continue
		if px_rect.has_point(Vector2(p.x, p.y)):
			continue
		var idx := p.y * w + p.x
		if visited[idx] == 1:
			continue
		visited[idx] = 1

		var col := img.get_pixel(p.x, p.y)
		if _is_bg_candidate(col):
			img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
			queue.append(Vector2i(p.x + 1, p.y))
			queue.append(Vector2i(p.x - 1, p.y))
			queue.append(Vector2i(p.x, p.y + 1))
			queue.append(Vector2i(p.x, p.y - 1))

	for pass_idx in range(3):
		for y in range(1, h - 1):
			for x in range(1, w - 1):
				var c := img.get_pixel(x, y)
				if c.a <= 0.01:
					continue
				var has_trans_neighbor := (
					img.get_pixel(x + 1, y).a < 0.25 or
					img.get_pixel(x - 1, y).a < 0.25 or
					img.get_pixel(x, y + 1).a < 0.25 or
					img.get_pixel(x, y - 1).a < 0.25
				)
				if has_trans_neighbor:
					var min_c := minf(c.r, minf(c.g, c.b))
					var max_c := maxf(c.r, maxf(c.g, c.b))
					var sat := (max_c - min_c) / maxf(0.001, max_c)
					if min_c > 0.60:
						if sat > 0.18:
							var alpha := clampf(1.0 - min_c * 0.85, 0.15, 0.92)
							var nr := clampf((c.r - min_c * 0.75) / alpha, 0.0, 1.0)
							var ng := clampf((c.g - min_c * 0.75) / alpha, 0.0, 1.0)
							var nb := clampf((c.b - min_c * 0.75) / alpha, 0.0, 1.0)
							img.set_pixel(x, y, Color(nr, ng, nb, alpha))
						else:
							var alpha := clampf((0.86 - min_c) / 0.26, 0.0, 0.70)
							img.set_pixel(x, y, Color(c.r * 0.6, c.g * 0.6, c.b * 0.6, alpha))

	var min_x := w
	var min_y := h
	var max_x := 0
	var max_y := 0
	for y in range(h):
		for x in range(w):
			if img.get_pixel(x, y).a > 0.08:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)

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

	print("[AttackSprite] 已儲存: ", dst_res)
