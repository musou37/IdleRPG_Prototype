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
@onready var auto_equip_btn: Button = $BottomPanel/VBox/MainTabs/裝備與背包/Scroll/VBox/InvHeaderRow/AutoEquipBtn
@onready var auto_sell_btn: Button = $BottomPanel/VBox/MainTabs/裝備與背包/Scroll/VBox/InvHeaderRow/AutoSellBtn
@onready var skill_list_vbox: VBoxContainer = $BottomPanel/VBox/MainTabs/技能學習/Scroll/SkillBox
@onready var log_panel: PanelContainer = $BottomPanel/VBox/LogPanel
@onready var log_label: RichTextLabel = $BottomPanel/VBox/LogPanel/Margin/LogRichText

# 戰鬥即時狀態
var hero_hp: int = 120
var hero_atk_timer: float = 0.0
var is_reviving: bool = false
var revive_timer: float = 0.0
const REVIVE_DURATION: float = 5.0

var enemy_name: String = "史萊姆"
var enemy_max_hp: int = 45
var enemy_hp: int = 45
var enemy_atk: int = 6
var enemy_aspd: float = 1.0 # 怪物攻速固定為 1.0 次/秒，不再成長
var enemy_atk_timer: float = 0.0
var enemy_is_elite: bool = false
var prev_enemy_max_hp: int = 45
var prev_enemy_atk: int = 6

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

	forge_btn.visible = true
	forge_btn.pressed.connect(func():
		if not GameManager.forge_random_equipment():
			_spawn_floating_text(Vector2(360, 280), "金幣不足！", Color(1.0, 0.4, 0.4))
	)

	auto_equip_btn.pressed.connect(func():
		var count := GameManager.auto_equip_best()
		if count > 0:
			_spawn_floating_text(Vector2(280, 260), "⚡ 已自動換上 %d 件最強裝備！" % count, Color(0.4, 1.0, 0.55))
	)

	auto_sell_btn.pressed.connect(func():
		var res := GameManager.auto_sell_weaker()
		var cnt: int = res.get("count", 0)
		var g: int = res.get("gold", 0)
		if cnt > 0:
			_spawn_floating_text(Vector2(280, 260), "💰 售出 %d 件較弱裝備 (+%dG)" % [cnt, g], Color(1.0, 0.88, 0.3))
	)

	hero_hp = GameManager.get_total_max_hp()
	_spawn_enemy()
	_refresh_all_ui()
	_append_log("⚔️ 歡迎來到 Idle RPG 雛型！勇者已開始自動戰鬥。")

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
	toolbar.add_theme_constant_override("separation", 8)
	debug_vbox.add_child(toolbar)

	var title_lbl := Label.new()
	title_lbl.text = "🐞 除錯紀錄與測試工具"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	toolbar.add_child(title_lbl)

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
		_refresh_all_ui()
	)
	toolbar.add_child(btn_lvl)

	var btn_kills := Button.new()
	btn_kills.text = "+10 擊殺"
	btn_kills.add_theme_font_size_override("font_size", 12)
	btn_kills.pressed.connect(func():
		GameManager.kill_count += 10
		_spawn_enemy()
		_refresh_all_ui()
		_append_log("🛠️ [除錯] 累計擊殺 +10（目前 %d 隻）" % GameManager.kill_count)
	)
	toolbar.add_child(btn_kills)

	var btn_elite := Button.new()
	btn_elite.text = "必出菁英"
	btn_elite.add_theme_font_size_override("font_size", 12)
	btn_elite.pressed.connect(func():
		GameManager.next_is_elite = true
		_refresh_all_ui()
		_append_log("🛠️ [除錯] 已預約下一隻怪物為【菁英怪】！")
	)
	toolbar.add_child(btn_elite)

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
	# 若勇者正在復活詠唱中：暫停雙方普攻，敵人停止攻擊並維持原血量
	if is_reviving:
		revive_timer += delta
		var progress_ratio := clampf(revive_timer / REVIVE_DURATION, 0.0, 1.0)
		arena.is_reviving = true
		arena.revive_ratio = progress_ratio
		hero_atk_bar.value = progress_ratio * 100.0
		_update_combat_bars()

		if revive_timer >= REVIVE_DURATION:
			is_reviving = false
			revive_timer = 0.0
			arena.is_reviving = false
			arena.revive_ratio = 0.0
			hero_hp = GameManager.get_total_max_hp()
			hero_atk_timer = 0.0
			hero_atk_bar.value = 0.0
			_update_combat_bars()
			_spawn_floating_text(arena.hero_pos + Vector2(0, -85), "✨ 復活完成！HP 全滿", Color(0.35, 1.0, 0.55))
			_append_log("✨ 勇者完成復活詠唱，恢復全部生命並繼續戰鬥！")
		return

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
		if not is_reviving and s.is_learned() and s.is_active_skill():
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
			var dmg_mult := skill.roll_damage_multiplier()
			_append_log("🔥 施放技能【%s】(%.0f%% 傷害)！" % [skill.skill_name, dmg_mult * 100.0])
			_perform_hero_attack(dmg_mult, true)
		SkillData.SkillType.ACTIVE_HEAL:
			var heal_amount := maxi(1, int(round(GameManager.get_total_max_hp() * skill.get_effect_value())))
			hero_hp = mini(GameManager.get_total_max_hp(), hero_hp + heal_amount)
			_update_combat_bars()
			_spawn_floating_text(arena.hero_pos + Vector2(0, -85), "+%d HP" % heal_amount, Color(0.3, 1.0, 0.45))
			_append_log("💚 施放【%s】回復了 %d 點生命！" % [skill.skill_name, heal_amount])

func _perform_hero_attack(dmg_multiplier: float, is_skill: bool) -> void:
	arena.trigger_hero_attack()
	arena.trigger_enemy_hit(is_skill)

	var is_crit := randf() < GameManager.get_total_crit_rate()
	var crit_mult := GameManager.get_total_crit_dmg() if is_crit else 1.0
	var raw_dmg := int(round(GameManager.get_total_atk() * dmg_multiplier * crit_mult))
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
	var is_blocked := randf() < GameManager.get_block_chance()
	if is_blocked:
		dmg = maxi(1, int(round(dmg * (1.0 - GameManager.get_block_reduction()))))

	hero_hp = maxi(0, hero_hp - dmg)
	_update_combat_bars()

	if is_blocked:
		_spawn_floating_text(arena.hero_pos + Vector2(randf_range(-15, 15), -85), "🛡️格檔! -%d" % dmg, Color(0.45, 0.9, 1.0))
		_append_log("🛡️ 觸發【格檔】！減免 30%% 傷害，僅受到 %d 點傷害。" % dmg)
	else:
		_spawn_floating_text(arena.hero_pos + Vector2(randf_range(-15, 15), -85), "-%d" % dmg, Color(1.0, 0.35, 0.35))

	if hero_hp <= 0:
		_on_hero_defeated()

func _on_enemy_defeated() -> void:
	# 紀錄上一隻怪物的屬性（供下一隻菁英怪以 N 倍放大）
	prev_enemy_max_hp = enemy_max_hp
	prev_enemy_atk = enemy_atk

	GameManager.kill_count += 1
	var tier := GameManager.get_current_tier()
	var reward_mult := int(round(GameManager.elite_stat_multiplier)) if enemy_is_elite else 1

	# 金幣不隨累計擊殺持續成長（一般怪穩定掉落 10~15 金幣，菁英怪乘上倍率）
	var gold_reward := randi_range(10, 15) * reward_mult
	var exp_reward := (12 + GameManager.kill_count * 3) * reward_mult

	GameManager.add_gold(gold_reward)
	GameManager.add_exp(exp_reward)

	# 掉寶判定：一般怪大幅降低掉寶率 (5%) 與品質；菁英怪 100% 掉落高品質裝備
	var drop_chance := 1.0 if enemy_is_elite else 0.05
	if randf() < drop_chance:
		var source_type := "elite" if enemy_is_elite else "normal"
		var drop := GameManager.generate_random_equipment(tier, source_type)
		if enemy_is_elite:
			_append_log("💎 擊敗 %s 爆出了高品質裝備【%s】！" % [enemy_name, drop.item_name])
		else:
			_append_log("🎁 擊敗 %s 爆出了裝備【%s】！" % [enemy_name, drop.item_name])
		_spawn_item_drop_animation(drop, arena.enemy_pos)

	# 每次擊殺一般怪物時，有一定機率觸發下一隻為「菁英怪」
	if not enemy_is_elite and not GameManager.next_is_elite:
		if randf() < GameManager.elite_spawn_chance:
			GameManager.next_is_elite = true
			_spawn_floating_text(arena.enemy_pos + Vector2(-40, -115), "⚠️ 觸發菁英怪來襲！", Color(1.0, 0.35, 0.35))
			_append_log("⚠️ 殺氣凝聚！下一隻登場的將是強度 %.1f 倍的【菁英怪】！" % GameManager.elite_stat_multiplier)

	_spawn_enemy()
	_refresh_all_ui()

func _spawn_item_drop_animation(item: EquipmentData, origin_pos: Vector2) -> void:
	var fx := DroppedItemFX.new(item)
	# 起始位置：怪物胸口
	fx.position = origin_pos - Vector2(28, 28)
	fx.scale = Vector2(0.4, 0.4)
	fx.modulate.a = 0.0
	$BattleViewport.add_child(fx)

	# 1. 噴射跳躍至地面 (拋物線噴發)
	var ground_y := 235.0 - 28.0 + randf_range(-8.0, 15.0)
	var land_x := clampf(origin_pos.x + randf_range(-70.0, 60.0), 380.0, 660.0)
	var apex_y := origin_pos.y - randf_range(55.0, 85.0)

	var tw := create_tween()
	# 出現淡入 + 變大
	tw.parallel().tween_property(fx, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(fx, "scale", Vector2(1.15, 1.15), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# X 軸水平噴出
	tw.parallel().tween_property(fx, "position:x", land_x, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Y 軸先向上再墜落觸地
	tw.parallel().tween_property(fx, "position:y", apex_y, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(fx, "position:y", ground_y, 0.24).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(fx, "scale", Vector2(1.0, 1.0), 0.24)

	# 2. 地面掉落文字提示 + 閃耀停留片刻 (越高品階停留稍長，展示耀眼光芒)
	var ground_wait := 0.35 + item.rarity * 0.08
	tw.chain().tween_callback(func():
		var rarity_tag := "[%s] " % item.get_rarity_name()
		_spawn_floating_text(Vector2(land_x, ground_y - 25), "%s%s" % [rarity_tag, item.item_name], item.get_rarity_color())
	)
	tw.chain().tween_interval(ground_wait)

	# 3. 飛向背包區域 (朝下方 UI 面板飛入收納)
	var target_fly_pos := Vector2(360.0 - 28.0, 310.0 + 35.0)
	tw.chain().tween_property(fx, "position", target_fly_pos, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(fx, "scale", Vector2(0.35, 0.35), 0.38).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(fx, "modulate:a", 0.75, 0.38)

	# 4. 到達背包：收入背包資料結構並釋放特效節點
	tw.chain().tween_callback(func():
		GameManager.inventory.append(item)
		GameManager.equipment_changed.emit()
		_spawn_floating_text(Vector2(320.0, 275.0), "+1 裝備已收入背包", Color(0.4, 1.0, 0.6))
		fx.queue_free()
	)

func _on_hero_defeated() -> void:
	is_reviving = true
	revive_timer = 0.0
	hero_hp = 0
	hero_atk_timer = 0.0
	hero_atk_bar.value = 0.0
	arena.is_reviving = true
	arena.revive_ratio = 0.0
	_spawn_floating_text(arena.hero_pos + Vector2(0, -85), "⏳ 復活詠唱中 (5.0s)...", Color(0.45, 0.85, 1.0))
	_append_log("💀 勇者倒下了！開始 5 秒「復活詠唱」，敵人暫停攻擊。")
	_update_combat_bars()

func _spawn_enemy() -> void:
	var k := GameManager.kill_count
	var monster_names := ["翠綠史萊姆", "狂暴哥布林", "暗影骷髏兵", "雙頭魔狼", "深淵石像鬼"]
	var base_name: String = monster_names[k % monster_names.size()]

	enemy_is_elite = GameManager.next_is_elite
	GameManager.next_is_elite = false

	enemy_is_boss_setup(enemy_is_elite, k + 1)

	if enemy_is_elite:
		# 菁英怪：強度為上一隻怪物的 N 倍 (GameManager.elite_stat_multiplier = 1.5)，攻速固定為 1.0
		var mult := GameManager.elite_stat_multiplier
		enemy_name = "【菁英】" + base_name
		enemy_max_hp = maxi(1, int(round(prev_enemy_max_hp * mult)))
		enemy_hp = enemy_max_hp
		enemy_atk = maxi(1, int(round(prev_enemy_atk * mult)))
		enemy_aspd = 1.0
	else:
		# 一般怪物：平滑降低成長曲線，讓玩家升級與換裝的速度能穩定壓制敵人
		enemy_name = base_name
		enemy_max_hp = int(38 + k * 5.0 + pow(k, 1.08) * 1.5)
		enemy_hp = enemy_max_hp
		enemy_atk = int(5 + k * 0.45 + pow(k, 1.03) * 0.2)
		enemy_aspd = 1.0
		# 更新最近一隻一般怪基準
		prev_enemy_max_hp = enemy_max_hp
		prev_enemy_atk = enemy_atk

	enemy_atk_timer = 0.0
	_update_combat_bars()

func enemy_is_boss_setup(is_elite: bool, color_index: int) -> void:
	arena.enemy_is_boss = is_elite
	var palette := [
		Color(0.35, 0.85, 0.45),
		Color(0.85, 0.45, 0.25),
		Color(0.65, 0.45, 0.85),
		Color(0.25, 0.75, 0.85),
		Color(0.85, 0.25, 0.45)
	]
	arena.enemy_color = palette[(color_index - 1) % palette.size()]
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
	if is_reviving:
		hero_hp_bar.value = int(round(max_hp * clampf(revive_timer / REVIVE_DURATION, 0.0, 1.0)))
		var remain := maxf(0.0, REVIVE_DURATION - revive_timer)
		$BattleViewport/HeroHUD/HPLabel.text = "✨ 復活詠唱中... (%.1fs)" % remain
	else:
		hero_hp_bar.value = hero_hp
		$BattleViewport/HeroHUD/HPLabel.text = "勇者 HP: %d / %d" % [hero_hp, max_hp]

	enemy_name_label.text = "%s (攻擊:%d)" % [enemy_name, enemy_atk]
	enemy_hp_bar.max_value = enemy_max_hp
	enemy_hp_bar.value = enemy_hp
	$BattleViewport/EnemyHUD/HPLabel.text = "HP: %d / %d" % [enemy_hp, enemy_max_hp]

func _refresh_all_ui() -> void:
	var elite_tag := ("   |   🔥 當前: 菁英怪 (%.1fx)" % GameManager.elite_stat_multiplier) if enemy_is_elite else (
		"   |   ⚠️ 下一隻: 菁英怪！" if GameManager.next_is_elite else ""
	)
	stage_label.text = "💀 累計討伐: %d 隻%s" % [GameManager.kill_count, elite_tag]
	stats_label.text = "Lv.%d 勇者  |  💰 金幣: %d  |  📘 技能點: %d  |  💥 暴率: %.1f%%  |  🔥 暴傷: %.2fx\n❤️ 生命: %d   ⚔️ 攻擊: %d   🛡️ 防禦: %d   ⚡ 攻速: %.2f/秒" % [
		GameManager.level,
		GameManager.gold,
		GameManager.skill_points,
		GameManager.get_total_crit_rate() * 100.0,
		GameManager.get_total_crit_dmg(),
		GameManager.get_total_max_hp(),
		GameManager.get_total_atk(),
		GameManager.get_total_def(),
		GameManager.get_total_aspd()
	]
	exp_bar.max_value = GameManager.get_max_exp()
	exp_bar.value = GameManager.current_exp
	forge_btn.text = "⚒️ 鍛造隨機裝備 (%d 金幣)" % GameManager.forge_cost()

	_update_combat_bars()
	_refresh_equipment_ui()
	_refresh_skills_ui()

func _refresh_equipment_ui() -> void:
	for c in equip_list_vbox.get_children():
		c.queue_free()

	# 1. 三格視覺化穿戴裝備槽 (橫向並排卡片)
	var slots_hbox := HBoxContainer.new()
	slots_hbox.add_theme_constant_override("separation", 10)
	equip_list_vbox.add_child(slots_hbox)

	var slot_names := {
		EquipmentData.SlotType.WEAPON: "武器槽",
		EquipmentData.SlotType.ARMOR: "裝甲槽",
		EquipmentData.SlotType.SHIELD: "盾牌槽"
	}

	for slot_key in [EquipmentData.SlotType.WEAPON, EquipmentData.SlotType.ARMOR, EquipmentData.SlotType.SHIELD]:
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
		vbox.add_theme_constant_override("separation", 6)
		margin.add_child(vbox)

		var item: EquipmentData = GameManager.equipped.get(slot_key)

		# 置中視覺圖示槽
		var icon_center := CenterContainer.new()
		var icon := IconSlot.new(Vector2(60, 60))
		icon.setup_equipment(item, slot_key)
		icon_center.add_child(icon)
		vbox.add_child(icon_center)

		var name_lbl := Label.new()
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 14)

		var stat_lbl := Label.new()
		stat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stat_lbl.add_theme_font_size_override("font_size", 12)
		stat_lbl.add_theme_color_override("font_color", Color(0.78, 0.82, 0.9))

		var upg_btn := Button.new()
		if item != null:
			name_lbl.text = "[%s] %s +%d" % [item.get_rarity_name(), item.item_name, item.level]
			name_lbl.add_theme_color_override("font_color", item.get_rarity_color())
			stat_lbl.text = "%s (戰力:%d)" % [item.get_summary_text(), item.get_power_score()]
			var cost := item.get_upgrade_cost()
			upg_btn.text = "強化 (%dG)" % cost
			upg_btn.disabled = GameManager.gold < cost
			upg_btn.pressed.connect(func(): GameManager.upgrade_equipped(slot_key))
		else:
			name_lbl.text = "%s (空)" % slot_names[slot_key]
			name_lbl.add_theme_color_override("font_color", Color(0.5, 0.52, 0.58))
			stat_lbl.text = "尚未穿戴"
			upg_btn.text = "無裝備"
			upg_btn.disabled = true

		vbox.add_child(name_lbl)
		vbox.add_child(stat_lbl)
		vbox.add_child(upg_btn)
		slots_hbox.add_child(card)

	# 更新自動穿最強 / 自動售出較弱按鈕狀態
	if auto_equip_btn != null:
		auto_equip_btn.disabled = not GameManager.has_stronger_in_inventory()
	if auto_sell_btn != null:
		var weak_cnt := GameManager.get_weaker_inventory_count()
		auto_sell_btn.disabled = (weak_cnt <= 0)
		auto_sell_btn.text = ("💰 售出較弱裝備 (%d)" % weak_cnt) if weak_cnt > 0 else "💰 售出較弱裝備"

	# 2. 備用背包視覺化欄位 (雙欄卡片網格)
	for c in inv_list_vbox.get_children():
		c.queue_free()

	if GameManager.inventory.is_empty():
		var empty_box := HBoxContainer.new()
		empty_box.add_theme_constant_override("separation", 10)
		for empty_idx in range(4):
			var empty_slot := IconSlot.new(Vector2(50, 50))
			empty_slot.setup_equipment(null, (empty_idx % 3) as EquipmentData.SlotType)
			empty_box.add_child(empty_slot)
		var empty_lbl := Label.new()
		empty_lbl.text = "背包目前空空如也\n打怪掉落或點擊上方「鍛造」即可獲得裝備！"
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.62, 0.68))
		empty_lbl.add_theme_font_size_override("font_size", 13)
		empty_box.add_child(empty_lbl)
		inv_list_vbox.add_child(empty_box)
	else:
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		inv_list_vbox.add_child(grid)

		for i in range(GameManager.inventory.size()):
			var inv_item: EquipmentData = GameManager.inventory[i]
			var item_card := PanelContainer.new()
			item_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var margin := MarginContainer.new()
			margin.add_theme_constant_override("margin_left", 6)
			margin.add_theme_constant_override("margin_top", 6)
			margin.add_theme_constant_override("margin_right", 6)
			margin.add_theme_constant_override("margin_bottom", 6)
			item_card.add_child(margin)

			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			margin.add_child(row)

			var icon := IconSlot.new(Vector2(52, 52))
			icon.setup_equipment(inv_item, inv_item.slot)
			row.add_child(icon)

			var info_vbox := VBoxContainer.new()
			info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info_vbox.add_theme_constant_override("separation", 2)

			var is_stronger := GameManager.is_stronger_than_equipped(inv_item)
			var is_weaker := GameManager.is_weaker_than_equipped(inv_item)
			var cmp_tag := "🔼較強" if is_stronger else ("🔽較弱" if is_weaker else "🟰持平")

			var title_lbl := Label.new()
			title_lbl.text = "[%s] %s +%d  [%s]" % [inv_item.get_rarity_name(), inv_item.item_name, inv_item.level, cmp_tag]
			title_lbl.add_theme_color_override("font_color", inv_item.get_rarity_color())
			title_lbl.add_theme_font_size_override("font_size", 14)

			var stat_lbl := Label.new()
			stat_lbl.text = "[%s] %s (戰力:%d)" % [inv_item.get_slot_name(), inv_item.get_summary_text(), inv_item.get_power_score()]
			stat_lbl.add_theme_font_size_override("font_size", 12)
			stat_lbl.add_theme_color_override(
				"font_color",
				Color(0.55, 0.95, 0.65) if is_stronger else Color(0.78, 0.82, 0.88)
			)

			var btn_row := HBoxContainer.new()
			btn_row.add_theme_constant_override("separation", 6)
			var idx := i

			var eq_btn := Button.new()
			eq_btn.text = "穿戴"
			eq_btn.add_theme_font_size_override("font_size", 12)
			eq_btn.pressed.connect(func(): GameManager.equip_from_inventory(idx))

			var sell_btn := Button.new()
			var sell_price := int(10 * inv_item.rarity * inv_item.level)
			sell_btn.text = "出售(+%dG)" % sell_price
			sell_btn.add_theme_font_size_override("font_size", 12)
			sell_btn.pressed.connect(func(): GameManager.sell_inventory_item(idx))

			btn_row.add_child(eq_btn)
			btn_row.add_child(sell_btn)

			info_vbox.add_child(title_lbl)
			info_vbox.add_child(stat_lbl)
			info_vbox.add_child(btn_row)
			row.add_child(info_vbox)
			grid.add_child(item_card)


func _refresh_skills_ui() -> void:
	# 同步更新戰鬥畫面左上角的技能圖示列
	for i in range(mini(battle_skill_icons.size(), GameManager.skills.size())):
		if is_instance_valid(battle_skill_icons[i]):
			battle_skill_icons[i].setup_skill(GameManager.skills[i])

	for c in skill_list_vbox.get_children():
		c.queue_free()
	tab_skill_icons.clear()
	tab_skill_icons.resize(GameManager.skills.size())

	# 顯示目前可用技能點數橫幅與「重置技能」按鈕
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 10)
	skill_list_vbox.add_child(header_row)

	var sp_header := Label.new()
	sp_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp_header.text = "📘 可用技能點: %d 點  （每升 1 級獲得 1 點）" % GameManager.skill_points
	sp_header.add_theme_font_size_override("font_size", 14)
	sp_header.add_theme_color_override(
		"font_color",
		Color(0.45, 0.95, 0.6) if GameManager.skill_points > 0 else Color(0.75, 0.78, 0.85)
	)
	header_row.add_child(sp_header)

	var spent_sp := GameManager.get_spent_skill_points()
	var reset_btn := Button.new()
	reset_btn.custom_minimum_size = Vector2(140, 32)
	reset_btn.add_theme_font_size_override("font_size", 13)
	reset_btn.text = ("🔄 重置技能 (+%d點)" % spent_sp) if spent_sp > 0 else "🔄 重置技能"
	reset_btn.disabled = (spent_sp <= 0)
	reset_btn.pressed.connect(func():
		var refunded := GameManager.reset_skills()
		if refunded > 0:
			_spawn_floating_text(Vector2(280, 260), "🔄 技能已重置！退回 %d 點技能點" % refunded, Color(0.45, 0.9, 1.0))
	)
	header_row.add_child(reset_btn)

	# 依三大技能流派分類顯示：狂暴、鐵衛、戰術
	var categories := [
		SkillData.Category.BERSERK,
		SkillData.Category.IRON_GUARD,
		SkillData.Category.TACTICS
	]
	var cat_titles := {
		SkillData.Category.BERSERK: "🔥【狂暴】— 爆發輸出與致命暴擊",
		SkillData.Category.IRON_GUARD: "🛡️【鐵衛】— 聖光恢復與銅牆鐵壁",
		SkillData.Category.TACTICS: "⚡【戰術】— 武技專精與疾風攻速"
	}
	var cat_colors := {
		SkillData.Category.BERSERK: Color(1.0, 0.48, 0.35),
		SkillData.Category.IRON_GUARD: Color(0.38, 0.9, 0.58),
		SkillData.Category.TACTICS: Color(0.4, 0.82, 1.0)
	}

	for cat in categories:
		var cat_lbl := Label.new()
		cat_lbl.text = cat_titles[cat]
		cat_lbl.add_theme_font_size_override("font_size", 14)
		cat_lbl.add_theme_color_override("font_color", cat_colors[cat])
		skill_list_vbox.add_child(cat_lbl)

		for i in range(GameManager.skills.size()):
			var s: SkillData = GameManager.skills[i]
			if s.category != cat:
				continue

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
			var icon := IconSlot.new(Vector2(54, 54))
			icon.setup_skill(s)
			hbox.add_child(icon)
			tab_skill_icons[i] = icon

			var level_unlocked := (GameManager.level >= s.required_level)

			var vbox := VBoxContainer.new()
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			var title := Label.new()
			var req_tag := "" if s.is_learned() else ("  [需勇者 Lv.%d]" % s.required_level)
			title.text = "%s  (Lv.%d)%s" % [s.skill_name, s.level, req_tag]
			if s.is_learned():
				title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
			elif level_unlocked:
				title.add_theme_color_override("font_color", Color(0.88, 0.9, 0.95))
			else:
				title.add_theme_color_override("font_color", Color(0.95, 0.45, 0.45))

			var desc := Label.new()
			desc.text = s.get_display_desc()
			desc.add_theme_font_size_override("font_size", 12)
			desc.add_theme_color_override("font_color", Color(0.82, 0.86, 0.92))
			vbox.add_child(title)
			vbox.add_child(desc)

			var btn := Button.new()
			var cost := s.get_upgrade_cost()
			btn.custom_minimum_size = Vector2(120, 42)
			if not level_unlocked:
				btn.text = "🔒 需 Lv.%d" % s.required_level
				btn.disabled = true
			else:
				btn.text = "%s (%d點)" % [("學習" if s.level == 0 else "升級"), cost]
				btn.disabled = GameManager.skill_points < cost
			var idx := i
			btn.pressed.connect(func(): GameManager.upgrade_skill(idx))

			hbox.add_child(vbox)
			hbox.add_child(btn)
			skill_list_vbox.add_child(panel)

func _append_log(msg: String) -> void:
	if log_label == null:
		return
	log_label.append_text(msg + "\n")

