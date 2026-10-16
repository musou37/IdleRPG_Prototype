extends Control

@onready var arena: Node2D = $BattleViewport/BattleArena
@onready var stage_label: Label = $BattleViewport/StageBanner/StageLabel
@onready var hero_hp_bar: ProgressBar = $BattleViewport/HeroHUD/HPBar
@onready var hero_atk_bar: ProgressBar = $BattleViewport/HeroHUD/AtkBar
@onready var enemy_name_label: Label = $BattleViewport/EnemyHUD/NameLabel
@onready var enemy_hp_bar: ProgressBar = $BattleViewport/EnemyHUD/HPBar
@onready var enemy_atk_bar: ProgressBar = $BattleViewport/EnemyHUD/AtkBar

@onready var stats_label: Label = $BottomPanel/VBox/HeroStatsPanel/Margin/VBox/StatsLabel
@onready var exp_bar: ProgressBar = $BottomPanel/VBox/HeroStatsPanel/Margin/VBox/ExpBar
@onready var equip_list_vbox: VBoxContainer = $BottomPanel/VBox/MainTabs/裝備與背包/Scroll/VBox/EquippedBox
@onready var inv_list_vbox: VBoxContainer = $BottomPanel/VBox/MainTabs/裝備與背包/Scroll/VBox/InventoryBox
@onready var forge_btn: Button = $BottomPanel/VBox/MainTabs/裝備與背包/Scroll/VBox/HeaderRow/ForgeBtn
@onready var skill_list_vbox: VBoxContainer = $BottomPanel/VBox/MainTabs/技能學習/Scroll/SkillBox
@onready var log_panel: PanelContainer = $BottomPanel/VBox/LogPanel
@onready var log_label: RichTextLabel = $BottomPanel/VBox/LogPanel/Margin/LogRichText

# 戰鬥即時狀態
var hero_hp: int = 120
var hero_atk_timer: float = 0.0

var enemy_name: String = "史萊姆"
var enemy_max_hp: int = 45
var enemy_hp: int = 45
var enemy_atk: int = 6
var enemy_aspd: float = 0.65
var enemy_atk_timer: float = 0.0

# 技能圖示追蹤 (用於即時更新冷卻遮罩)
var battle_skill_icons: Array[IconSlot] = []
var tab_skill_icons: Array[IconSlot] = []
var battle_skill_bar: HBoxContainer = null
var debug_mode_btn: Button = null

func _ready() -> void:
	_setup_battle_skill_bar()
	_setup_debug_mode_ui()

	GameManager.stats_changed.connect(_on_stats_changed)
	GameManager.gold_changed.connect(func(_g): _refresh_all_ui())
	GameManager.exp_changed.connect(func(_e, _m, _l): _refresh_all_ui())
	GameManager.equipment_changed.connect(_refresh_equipment_ui)
	GameManager.skills_changed.connect(_refresh_skills_ui)
	GameManager.combat_log_added.connect(_append_log)

	forge_btn.visible = false
	$BottomPanel/VBox/MainTabs.set_tab_title(0, "裝備與素材")

	hero_hp = GameManager.get_total_max_hp()
	_spawn_enemy()
	_refresh_all_ui()
	_append_log("⚔️ 歡迎來到 Idle RPG 雛型！擊殺怪物可獲得各部位專屬強化素材。")

func _setup_battle_skill_bar() -> void:
	battle_skill_bar = HBoxContainer.new()
	battle_skill_bar.position = Vector2(20, 14)
	battle_skill_bar.add_theme_constant_override("separation", 8)
	$BattleViewport.add_child(battle_skill_bar)
	battle_skill_icons.clear()
	for i in range(GameManager.skills.size()):
		var icon := IconSlot.new(Vector2(46, 46))
		icon.setup_skill(GameManager.skills[i])
		icon.tooltip_text = GameManager.skills[i].skill_name
		battle_skill_bar.add_child(icon)
		battle_skill_icons.append(icon)

func _setup_debug_mode_ui() -> void:
	# 預設隱藏文字紀錄面板
	log_panel.visible = false

	# 在戰鬥畫面右上角建立「除錯模式」切換按鈕
	debug_mode_btn = Button.new()
	debug_mode_btn.text = "🛠️ 除錯模式: 關"
	debug_mode_btn.position = Vector2(565, 14)
	debug_mode_btn.custom_minimum_size = Vector2(135, 36)
	debug_mode_btn.add_theme_font_size_override("font_size", 13)
	debug_mode_btn.pressed.connect(func():
		log_panel.visible = not log_panel.visible
		debug_mode_btn.text = "🛠️ 除錯模式: 開" if log_panel.visible else "🛠️ 除錯模式: 關"
		if log_panel.visible:
			debug_mode_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		else:
			debug_mode_btn.remove_theme_color_override("font_color")
	)
	$BattleViewport.add_child(debug_mode_btn)

	# 將 LogPanel 內部升級為包含快捷除錯按鈕 + 戰鬥文字紀錄
	var margin: MarginContainer = $BottomPanel/VBox/LogPanel/Margin
	margin.remove_child(log_label)

	var debug_vbox := VBoxContainer.new()
	debug_vbox.add_theme_constant_override("separation", 6)
	margin.add_child(debug_vbox)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 6)
	debug_vbox.add_child(toolbar)

	var title_lbl := Label.new()
	title_lbl.text = "🐞 除錯紀錄與測試工具"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	toolbar.add_child(title_lbl)

	var btn_mat := Button.new()
	btn_mat.text = "+15 全素材"
	btn_mat.add_theme_font_size_override("font_size", 12)
	btn_mat.pressed.connect(func():
		for slot_key in [EquipmentData.SlotType.WEAPON, EquipmentData.SlotType.ARMOR, EquipmentData.SlotType.ACCESSORY]:
			GameManager.add_material(slot_key, 15)
		_append_log("🛠️ [除錯] 獲得三部位強化素材各 +15")
	)
	toolbar.add_child(btn_mat)

	var btn_gold := Button.new()
	btn_gold.text = "+500 金幣"
	btn_gold.add_theme_font_size_override("font_size", 12)
	btn_gold.pressed.connect(func():
		GameManager.add_gold(500)
		_append_log("🛠️ [除錯] 獲得 500 金幣")
	)
	toolbar.add_child(btn_gold)

	var btn_lvl := Button.new()
	btn_lvl.text = "+1 等級"
	btn_lvl.add_theme_font_size_override("font_size", 12)
	btn_lvl.pressed.connect(func():
		GameManager.add_exp(GameManager.get_max_exp())
		hero_hp = GameManager.get_total_max_hp()
		_refresh_all_ui()
	)
	toolbar.add_child(btn_lvl)

	var btn_stage := Button.new()
	btn_stage.text = "跳下一關"
	btn_stage.add_theme_font_size_override("font_size", 12)
	btn_stage.pressed.connect(func():
		GameManager.stage += 1
		GameManager.wave = 1
		_spawn_enemy()
		_refresh_all_ui()
		_append_log("🛠️ [除錯] 跳轉至第 %d 關" % GameManager.stage)
	)
	toolbar.add_child(btn_stage)

	var btn_clear := Button.new()
	btn_clear.text = "清空紀錄"
	btn_clear.add_theme_font_size_override("font_size", 12)
	btn_clear.pressed.connect(func(): log_label.clear())
	toolbar.add_child(btn_clear)

	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	debug_vbox.add_child(log_label)

func _process(delta: float) -> void:
	_process_combat(delta)
	_process_active_skills(delta)

func _process_combat(delta: float) -> void:
	# 勇者普攻讀條
	var h_aspd := GameManager.get_total_aspd()
	hero_atk_timer += delta * h_aspd
	hero_atk_bar.value = clampf(hero_atk_timer * 100.0, 0.0, 100.0)
	if hero_atk_timer >= 1.0:
		hero_atk_timer -= 1.0
		_perform_hero_attack(1.0, false)

	# 怪物普攻讀條
	enemy_atk_timer += delta * enemy_aspd
	enemy_atk_bar.value = clampf(enemy_atk_timer * 100.0, 0.0, 100.0)
	if enemy_atk_timer >= 1.0:
		enemy_atk_timer -= 1.0
		_perform_enemy_attack()

func _process_active_skills(delta: float) -> void:
	for i in range(GameManager.skills.size()):
		var s: SkillData = GameManager.skills[i]
		if s.is_learned() and s.is_active_skill():
			s.current_cd -= delta
			if s.current_cd <= 0.0:
				s.current_cd = s.cooldown
				_cast_active_skill(s)
		if i < battle_skill_icons.size() and is_instance_valid(battle_skill_icons[i]):
			battle_skill_icons[i].update_cooldown(s)
		if i < tab_skill_icons.size() and is_instance_valid(tab_skill_icons[i]):
			tab_skill_icons[i].update_cooldown(s)

func _cast_active_skill(skill: SkillData) -> void:
	match skill.skill_type:
		SkillData.SkillType.ACTIVE_DAMAGE:
			_append_log("🔥 施放技能【%s】！" % skill.skill_name)
			_perform_hero_attack(skill.get_effect_value(), true)
		SkillData.SkillType.ACTIVE_HEAL:
			var heal_amount := int(round(GameManager.get_total_max_hp() * skill.get_effect_value()))
			hero_hp = mini(GameManager.get_total_max_hp(), hero_hp + heal_amount)
			_update_combat_bars()
			_spawn_floating_text(arena.hero_pos + Vector2(0, -85), "+%d HP" % heal_amount, Color(0.3, 1.0, 0.45))
			_append_log("💚 施放【%s】回復了 %d 點生命！" % [skill.skill_name, heal_amount])

func _perform_hero_attack(dmg_multiplier: float, is_skill: bool) -> void:
	arena.trigger_hero_attack()
	arena.trigger_enemy_hit(is_skill)

	var is_crit := randf() < 0.15
	var raw_dmg := int(round(GameManager.get_total_atk() * dmg_multiplier * (1.6 if is_crit else 1.0)))
	raw_dmg = maxi(1, raw_dmg)
	enemy_hp = maxi(0, enemy_hp - raw_dmg)
	_update_combat_bars()

	var color := Color(1.0, 0.55, 0.15) if is_skill else (Color(1.0, 0.9, 0.2) if is_crit else Color.WHITE)
	var prefix := "技能! " if is_skill else ("暴擊! " if is_crit else "")
	_spawn_floating_text(arena.enemy_pos + Vector2(randf_range(-20, 20), -85), "%s-%d" % [prefix, raw_dmg], color)

	if enemy_hp <= 0:
		_on_enemy_defeated()

func _perform_enemy_attack() -> void:
	arena.trigger_enemy_attack()
	arena.trigger_hero_hit()

	var dmg := maxi(1, enemy_atk - GameManager.get_total_def())
	hero_hp = maxi(0, hero_hp - dmg)
	_update_combat_bars()
	_spawn_floating_text(arena.hero_pos + Vector2(randf_range(-15, 15), -85), "-%d" % dmg, Color(1.0, 0.35, 0.35))

	if hero_hp <= 0:
		_on_hero_defeated()

func _on_enemy_defeated() -> void:
	var is_boss := (GameManager.wave == GameManager.max_waves_per_stage)
	var gold_reward := (8 + GameManager.stage * 6) * (3 if is_boss else 1)
	var exp_reward := (12 + GameManager.stage * 8) * (3 if is_boss else 1)

	GameManager.add_gold(gold_reward)
	GameManager.add_exp(exp_reward)

	# 掉寶判定：擊殺怪物掉落裝備專屬強化素材
	var drop_info := GameManager.roll_monster_material_drop(is_boss, GameManager.stage)
	if not drop_info.is_empty():
		var mat_name: String = drop_info["name"]
		var mat_amt: int = drop_info["amount"]
		_spawn_floating_text(
			arena.enemy_pos + Vector2(-35, -115),
			"💎 +%d %s" % [mat_amt, mat_name],
			Color(0.4, 0.95, 1.0)
		)

	# 推進波數與關卡
	GameManager.wave += 1
	if GameManager.wave > GameManager.max_waves_per_stage:
		GameManager.wave = 1
		if GameManager.auto_advance_stage:
			GameManager.stage += 1
			_append_log("🚩 突破成功！進入第 %d 關！" % GameManager.stage)

	_spawn_enemy()
	_refresh_all_ui()

func _on_hero_defeated() -> void:
	_append_log("💀 勇者力竭倒下！退回第 1 波並恢復全部生命。")
	GameManager.wave = 1
	if GameManager.stage > 1:
		GameManager.stage -= 1
	hero_hp = GameManager.get_total_max_hp()
	_spawn_enemy()
	_refresh_all_ui()

func _spawn_enemy() -> void:
	var s := GameManager.stage
	var is_boss := (GameManager.wave == GameManager.max_waves_per_stage)
	var monster_names := ["翠綠史萊姆", "狂暴哥布林", "暗影骷髏兵", "雙頭魔狼", "深淵石像鬼"]
	var base_name: String = monster_names[(s - 1) % monster_names.size()]

	enemy_is_boss_setup(is_boss, s)
	enemy_name = ("【首領】" + base_name + "王") if is_boss else base_name
	enemy_max_hp = int((38 + pow(s, 1.45) * 28) * (2.6 if is_boss else 1.0))
	enemy_hp = enemy_max_hp
	enemy_atk = int((5 + pow(s, 1.3) * 4) * (1.5 if is_boss else 1.0))
	enemy_aspd = 0.65 + minf(0.5, s * 0.03)
	enemy_atk_timer = 0.0
	_update_combat_bars()

func enemy_is_boss_setup(is_boss: bool, stage_num: int) -> void:
	arena.enemy_is_boss = is_boss
	var palette := [
		Color(0.35, 0.85, 0.45),
		Color(0.85, 0.45, 0.25),
		Color(0.65, 0.45, 0.85),
		Color(0.25, 0.75, 0.85),
		Color(0.85, 0.25, 0.45)
	]
	arena.enemy_color = palette[(stage_num - 1) % palette.size()]
	arena.queue_redraw()

func _spawn_floating_text(pos: Vector2, text: String, col: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.add_theme_font_size_override("font_size", 20)
	$BattleViewport.add_child(lbl)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", pos.y - 48.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.65)
	tw.chain().tween_callback(lbl.queue_free)

func _on_stats_changed() -> void:
	hero_hp = mini(hero_hp, GameManager.get_total_max_hp())
	_refresh_all_ui()

func _update_combat_bars() -> void:
	var max_hp := GameManager.get_total_max_hp()
	hero_hp_bar.max_value = max_hp
	hero_hp_bar.value = hero_hp
	$BattleViewport/HeroHUD/HPLabel.text = "勇者 HP: %d / %d" % [hero_hp, max_hp]

	enemy_name_label.text = "%s (攻擊:%d)" % [enemy_name, enemy_atk]
	enemy_hp_bar.max_value = enemy_max_hp
	enemy_hp_bar.value = enemy_hp
	$BattleViewport/EnemyHUD/HPLabel.text = "HP: %d / %d" % [enemy_hp, enemy_max_hp]

func _refresh_all_ui() -> void:
	stage_label.text = "第 %d 關 - 波次 %d / %d" % [GameManager.stage, GameManager.wave, GameManager.max_waves_per_stage]
	stats_label.text = "Lv.%d 勇者   |   💰 金幣: %d\n❤️ 生命: %d   ⚔️ 攻擊: %d   🛡️ 防禦: %d   ⚡ 攻速: %.2f/秒" % [
		GameManager.level,
		GameManager.gold,
		GameManager.get_total_max_hp(),
		GameManager.get_total_atk(),
		GameManager.get_total_def(),
		GameManager.get_total_aspd()
	]
	exp_bar.max_value = GameManager.get_max_exp()
	exp_bar.value = GameManager.current_exp

	_update_combat_bars()
	_refresh_equipment_ui()
	_refresh_skills_ui()

func _refresh_equipment_ui() -> void:
	for c in equip_list_vbox.get_children():
		c.queue_free()

	# 1. 三格初始裝備養成槽 (橫向並排卡片)
	var slots_hbox := HBoxContainer.new()
	slots_hbox.add_theme_constant_override("separation", 10)
	equip_list_vbox.add_child(slots_hbox)

	for slot_key in [EquipmentData.SlotType.WEAPON, EquipmentData.SlotType.ARMOR, EquipmentData.SlotType.ACCESSORY]:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		card.add_child(margin)

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 5)
		margin.add_child(vbox)

		var item: EquipmentData = GameManager.equipped.get(slot_key)

		# 置中視覺圖示槽
		var icon_center := CenterContainer.new()
		var icon := IconSlot.new(Vector2(62, 62))
		icon.setup_equipment(item, slot_key)
		icon_center.add_child(icon)
		vbox.add_child(icon_center)

		var name_lbl := Label.new()
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 14)

		var stat_lbl := Label.new()
		stat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stat_lbl.add_theme_font_size_override("font_size", 12)
		stat_lbl.add_theme_color_override("font_color", Color(0.82, 0.86, 0.94))

		var req_lbl := Label.new()
		req_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		req_lbl.add_theme_font_size_override("font_size", 12)

		var upg_btn := Button.new()
		if item != null:
			name_lbl.text = "%s Lv.%d" % [item.get_display_name(), item.level]
			name_lbl.add_theme_color_override("font_color", item.get_rarity_color())
			stat_lbl.text = item.get_summary_text()

			var cost := item.get_upgrade_material_cost()
			var owned := GameManager.get_material_count(slot_key)
			var mat_name := item.get_material_name()
			req_lbl.text = "消耗 %s: %d / %d" % [mat_name, owned, cost]
			req_lbl.add_theme_color_override(
				"font_color",
				Color(0.45, 0.95, 0.55) if owned >= cost else Color(1.0, 0.5, 0.5)
			)

			upg_btn.text = "⬆️ 素材強化"
			upg_btn.disabled = owned < cost
			upg_btn.pressed.connect(func(): GameManager.upgrade_equipped(slot_key))

		vbox.add_child(name_lbl)
		vbox.add_child(stat_lbl)
		vbox.add_child(req_lbl)
		vbox.add_child(upg_btn)
		slots_hbox.add_child(card)

	# 2. 三種部位獨立對應素材倉庫 (橫向三格視覺卡片)
	for c in inv_list_vbox.get_children():
		c.queue_free()

	var mat_hbox := HBoxContainer.new()
	mat_hbox.add_theme_constant_override("separation", 10)
	inv_list_vbox.add_child(mat_hbox)

	var mat_descs := {
		EquipmentData.SlotType.WEAPON: "專用於強化【武器】等級",
		EquipmentData.SlotType.ARMOR: "專用於強化【防具】等級",
		EquipmentData.SlotType.ACCESSORY: "專用於強化【飾品】等級"
	}

	for slot_key in [EquipmentData.SlotType.WEAPON, EquipmentData.SlotType.ARMOR, EquipmentData.SlotType.ACCESSORY]:
		var mat_card := PanelContainer.new()
		mat_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		mat_card.add_child(margin)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		margin.add_child(row)

		var count := GameManager.get_material_count(slot_key)
		var mat_icon := IconSlot.new(Vector2(52, 52))
		mat_icon.setup_material(slot_key, count)
		row.add_child(mat_icon)

		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		info_vbox.add_theme_constant_override("separation", 2)

		var m_title := Label.new()
		m_title.text = "%s" % GameManager.get_material_name(slot_key)
		m_title.add_theme_font_size_override("font_size", 14)
		m_title.add_theme_color_override("font_color", mat_icon.accent_color)

		var m_count := Label.new()
		m_count.text = "持有數量: %d" % count
		m_count.add_theme_font_size_override("font_size", 13)
		m_count.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98))

		var m_desc := Label.new()
		m_desc.text = mat_descs[slot_key]
		m_desc.add_theme_font_size_override("font_size", 11)
		m_desc.add_theme_color_override("font_color", Color(0.68, 0.72, 0.78))

		info_vbox.add_child(m_title)
		info_vbox.add_child(m_count)
		info_vbox.add_child(m_desc)
		row.add_child(info_vbox)
		mat_hbox.add_child(mat_card)

func _refresh_skills_ui() -> void:
	# 同步更新戰鬥畫面左上角的技能圖示列
	for i in range(mini(battle_skill_icons.size(), GameManager.skills.size())):
		if is_instance_valid(battle_skill_icons[i]):
			battle_skill_icons[i].setup_skill(GameManager.skills[i])

	for c in skill_list_vbox.get_children():
		c.queue_free()
	tab_skill_icons.clear()

	for i in range(GameManager.skills.size()):
		var s: SkillData = GameManager.skills[i]
		var panel := PanelContainer.new()

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_bottom", 6)
		panel.add_child(margin)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		margin.add_child(hbox)

		# 技能視覺圖示槽 (含即時冷卻動畫)
		var icon := IconSlot.new(Vector2(56, 56))
		icon.setup_skill(s)
		hbox.add_child(icon)
		tab_skill_icons.append(icon)

		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		var title := Label.new()
		title.text = "%s  (Lv.%d)" % [s.skill_name, s.level]
		title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35) if s.is_learned() else Color(0.7, 0.7, 0.75))
		var desc := Label.new()
		desc.text = s.get_display_desc()
		desc.add_theme_font_size_override("font_size", 13)
		desc.add_theme_color_override("font_color", Color(0.82, 0.86, 0.92))
		vbox.add_child(title)
		vbox.add_child(desc)

		var btn := Button.new()
		var cost := s.get_upgrade_cost()
		btn.custom_minimum_size = Vector2(110, 42)
		btn.text = "%s (%dG)" % [("學習" if s.level == 0 else "升級"), cost]
		btn.disabled = GameManager.gold < cost
		var idx := i
		btn.pressed.connect(func(): GameManager.upgrade_skill(idx))

		hbox.add_child(vbox)
		hbox.add_child(btn)
		skill_list_vbox.add_child(panel)

func _append_log(msg: String) -> void:
	if log_label == null:
		return
	log_label.append_text(msg + "\n")

