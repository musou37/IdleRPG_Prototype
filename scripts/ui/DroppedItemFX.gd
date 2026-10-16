class_name DroppedItemFX
extends Control

var item: EquipmentData
var glow_color: Color = Color.WHITE
var aura_pulse: float = 0.0
var icon_slot: IconSlot

func _init(p_item: EquipmentData) -> void:
	item = p_item
	glow_color = item.get_rarity_color()
	custom_minimum_size = Vector2(56, 56)
	size = Vector2(56, 56)
	pivot_offset = Vector2(28, 28)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	icon_slot = IconSlot.new(Vector2(56, 56))
	icon_slot.setup_equipment(item, item.slot)
	icon_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_slot)

func _process(delta: float) -> void:
	aura_pulse += delta * 5.0
	queue_redraw()

func _draw() -> void:
	var r := item.rarity
	var pulse := (sin(aura_pulse) + 1.0) * 0.5 # 0.0 ~ 1.0
	var center := size * 0.5
	
	# 根據品階強度決定光芒大小與層數
	var base_radius := 30.0 + r * 5.0 + pulse * (4.0 + r * 2.5)
	
	# 外層光暈
	var outer_alpha := clampf(0.12 + r * 0.06 + pulse * 0.08, 0.1, 0.7)
	draw_circle(center, base_radius * 1.3, Color(glow_color.r, glow_color.g, glow_color.b, outer_alpha * 0.45))
	
	# 中層聚光
	var mid_alpha := clampf(0.20 + r * 0.08, 0.15, 0.8)
	draw_circle(center, base_radius, Color(glow_color.r, glow_color.g, glow_color.b, mid_alpha))
	
	# 高階裝備 (紫、橘、彩虹) 額外繪製放射光芒星芒
	if r >= 4:
		var rays := 4 if r == 4 else (6 if r == 5 else 8)
		var ray_len := base_radius * (1.3 + (r - 4) * 0.35 + pulse * 0.3)
		var ray_color := Color.WHITE.lerp(glow_color, 0.35)
		ray_color.a = clampf(0.4 + r * 0.1 + pulse * 0.2, 0.3, 0.95)
		var rot_offset := aura_pulse * (0.8 if r < 6 else 1.5)
		for i in range(rays):
			var ang := (TAU / float(rays)) * i + rot_offset
			var dir := Vector2(cos(ang), sin(ang))
			draw_line(center, center + dir * ray_len, ray_color, 2.5 + (r - 4) * 1.0)
			
	# 彩虹神話額外繪製旋轉閃爍彩虹環
	if r >= 6:
		var rainbow_col := Color.from_hsv(fmod(aura_pulse * 0.3, 1.0), 0.75, 1.0, 0.85)
		draw_arc(center, base_radius * 1.15, 0, TAU, 32, rainbow_col, 3.5)
