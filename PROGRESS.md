# 開發進度與跨裝置交接紀錄 (PROGRESS.md)

> 本檔案用於跨電腦同步**對話上下文、開發決策、已完成功能與待辦事項**。
> 每次執行「上傳 (`/push`)」時，AI 會自動將當次對話的最新進度更新至此檔案；在另一台電腦執行「下載 (`/pull`)」時，AI 會自動讀取此檔案以無縫接軌開發。

---

## 📌 目前專案狀態摘要

- **最後更新時間**：2026-10-22
- **引擎版本**：Godot 4.7.2 (GL Compatibility)
- **專案類型**：2D 放置型 RPG 雛型 (`IdleRPG_Prototype`)
- **核心開發原則**：**玩法驗證優先**——開發新功能時一律先用程式幾何繪圖/色塊/文字快速驗證機制，**預設不主動生成美術圖素**（除非明確指示）。

---

## ✅ 已完成的核心功能與架構

1. **自動戰鬥、無盡討伐與進階戰鬥屬性 (`scripts/Main.gd`, `scripts/BattleArena.gd`, `scripts/autoload/GameManager.gd`)**
   - 取消傳統關卡限制，怪物無限刷新，強度平滑成長（怪物攻速固定為 1.0，金幣穩定掉落 10~15G）。
   - 一般怪物死亡有 20% 機率觸發下一隻為「菁英怪」（強度 1.5 倍，100% 掉落高品質裝備）。
   - 死亡機制：勇者 HP 歸零時觸發 5 秒原地「復活詠唱」，敵人停止攻擊並保留現有血量，詠唱完畢勇者滿血繼續戰鬥。
   - **敵我雙方進階戰鬥屬性**：
     - **🔁 連擊率 (`combo_rate`)**：初始值 `5%`（敵我雙方皆具備），每次進行普通攻擊時有機會再觸發一次普通攻擊（由連擊觸發的普攻不會再次觸發連擊）。
     - **🗡️ 直接傷害 (`direct_dmg`)**：初始值 `0`（敵我雙方皆具備），無視防禦與格檔等所有減免，直接在最終傷害加入的固定真實傷害值。
     - **🍃 迴避率 (`dodge_rate`)**：初始值 `0%`（敵我雙方皆具備），每次攻擊結算前最優先判定迴避，迴避成功則該次攻擊失敗不造成傷害並顯示 `閃避! MISS`。

2. **🎰 Slot Game 式狂熱 FEVER / BOSS RUSH 模式**
   - 當擊敗菁英怪時，有 35% 機率爆發進入持續 15 秒的「BOSS RUSH FEVER」模式！
   - **⚡ 2 倍速極速戰鬥演出**：狂熱期間遊戲全局時間縮放加速至 `Engine.time_scale = 2.0`，普攻、技能、噴裝拋物線與特效全面以 2 倍速高速運轉，狂熱結束後自動無縫恢復 1.0 倍速。
   - 狂熱期間所有刷新的怪物**保證 100% 為菁英怪**，享受神裝連續噴發的爽快反饋。
   - 視覺反饋：戰鬥舞台即時切換狂熱暗紅-金黃光效天空、**格鬥遊戲超必殺技風格的「巨型勇者側面大頭像 Cut-In」與流體集中線背景**（致敬街機格鬥超必殺演出，帶有閃白衝擊、壓低帽簷/頭盔陰影、銳利金瞳、粗黑漫畫排線與巨型金鎖鏈）、動態呼吸金框與火星粒子，以及簡潔高調的 `N KILL` 炫耀擊殺計數器。
   - 除錯工具列新增「🎰 觸發RUSH」按鈕，可隨時一鍵測試體驗。

3. **裝備品階、主副屬性與噴裝演出 (`scripts/resources/EquipmentData.gd`, `scripts/ui/DroppedItemFX.gd`)**
   - 6 大裝備品階：白（普通）-> 綠（優秀）-> 藍（稀有）-> 紫（史詩）-> 橘（傳奇）-> 彩虹（神話，動態 HSV 漸層光暈外框）。
   - **主屬性與副屬性分離機制**：
     - **◆ 主屬性**（武器=攻擊力、裝甲=生命值、盾牌=防禦力）：**唯一會隨裝備強化等級 (`+1, +2...`) 成長**的數值。
     - **◇ 副屬性**：**不隨強化等級成長**；副屬性項目數量與數值高低完全由裝備品階決定（白裝 `0` 項、綠裝 `1` 項、藍裝 `2` 項、紫裝 `3` 項、橘裝 `4` 項、彩虹裝 `5` 項）。
     - **副屬性不重複抽選**：優先從非主屬性的屬性池中不重複抽取；僅當所需副屬性數量超過目前可用屬性種類時（如彩虹裝第 5 條）才允許重複。
   - 掉落演出：擊殺怪物後，裝備以拋物線自怪物身上噴出、於草地反彈、依品階展示耀眼光芒（Aura & 旋轉光芒），短暫停留後再流暢飛入下方背包收納。

4. **技能學習規則與三大派系 (`scripts/resources/SkillData.gd`)**
   - 每次升級獲得 1 點技能點，透過技能點升級/學習技能，設有角色等級限制。
   - 支援「🔄 重置技能」按鈕，全額退還所有已消耗技能點數。
   - 三大類型技能：
     1. 🔥 **狂暴**：
        - `reckless` 魯莽 (主動)：造成 150%~250% 浮動攻擊傷害。
        - `lethal` 致命 (被動)：永久提升暴傷（初始+5%，每級+5%）。
     2. 🛡️ **鐵衛**：
        - `first_aid` 急救 (主動)：每 5 秒回復生命（初始 1%，每級+0.5%）。
        - `block` 格檔 (被動)：受擊 20% 機率減免 30% 傷害（每級+1% 格檔機率）。
     3. ⚡ **戰術**：
        - `sword_mastery` 劍術專精 (被動)：提升攻擊力。
        - `wind_blessing` 疾風祝福 (被動)：提升攻擊速度。

5. **💾 遊戲進度記憶與存讀檔系統 (`scripts/autoload/GameManager.gd`)**
   - 採用 JSON 格式儲存於本機安全路徑（`user://idle_rpg_save.json`）。
   - 完整保存：勇者等級、當前經驗值、金幣、剩餘技能點數、無盡累計擊殺數、當前穿戴裝備（主屬性、副屬性清單與強化等級）、背包所有儲存裝備、三大派系技能學習與配點狀態。
   - **雙重自動存檔保險**：
     1. 背景每 5 秒定期自動存檔。
     2. 視窗關閉請求（`NOTIFICATION_WM_CLOSE_REQUEST`）或退出時自動最後儲存。
   - 啟動遊戲自動偵測並無縫讀取舊存檔接續遊玩（舊版裝備存檔亦支援自動補齊副屬性遷移）。
   - 除錯工具列提供「💾 存檔」與「🗑️ 重置進度」按鈕，方便隨時手動備份或重開新局。

6. **🎨 漸進混搭美術載入與安全備案系統 (`scripts/autoload/AssetLoader.gd`, `assets/README_美術替換說明.md`)**
   - 支援**免編輯器直接熱載入外部 PNG 圖檔**（直接覆蓋 `assets/` 內對應檔名即可生效）。
   - 具備**完整原生幾何繪圖備案（Fallback）**：若特定圖片不存在，或在除錯工具列點擊 **「🎨 美術: 正式圖素 / 原生備案」** 切換，系統會自動退回原本的程式幾何繪圖，絕不破圖或報錯。
   - 已生成並去背套用正式美術素材：
     - 大絕招立繪：`assets/cutin/hero_cutin.png`
     - 戰鬥舞台背景：`assets/backgrounds/bg_normal.png`、`bg_boss_rush.png`
     - 角色與怪物（待機 + 帶武器拖曳刀光攻擊動作）：`assets/sprites/hero.png`、`hero_attack.png`、`monster_normal.png`、`monster_normal_attack.png`、`monster_boss.png`、`monster_boss_attack.png`
     - RUSH 寶箱（關閉上鎖 + 掀蓋開啟）：`chest_ornate_closed.png` / `chest_ornate.png`、`chest_luxury_closed.png` / `chest_luxury.png`、`chest_ultimate_closed.png` / `chest_ultimate.png`
     - 裝備部位圖示：`assets/icons/equip_weapon.png`、`equip_armor.png`、`equip_shield.png`

7. **跨電腦雲端同步與記憶交接機制 (`AGENTS.md`, `.agents/skills/`)**
   - 支援「上傳 / 備份 (`/push`)」、「下載 / 同步 (`/pull`)」與「執行 / 跑遊戲 (`/run`)」，且下載同步時自動重建 Godot 全域類別與素材快取。

---

## 📝 近期對話決策與變更紀錄

- **2026-11-02**：
   - 建立 **Web (HTML5) 網頁版匯出設定與 GitHub Pages 自動化部署流程 (`export_presets.cfg`, `.github/workflows/deploy-web.yml`, `project.godot`)**：
     - 將專案渲染器切換為 Web 與桌面皆相容的 `gl_compatibility` 模式，並設定單執行緒 Web 匯出（`variant/thread_support=false`），免除 GitHub Pages 對於 `SharedArrayBuffer` (COOP/COEP) 標頭的限制。
     - 內嵌開源繁體中文與 Emoji 字型（`assets/fonts/NotoSansTC-Bold.otf`、`assets/fonts/NotoEmoji.ttf`），並在 `GameManager._setup_fonts()` 中串接 Emoji Fallback，解決瀏覽器 WebAssembly 沙盒無法讀取作業系統字型導致中文與圖示變方框的問題。
     - 優化 `AssetLoader.get_texture()` 在匯出環境（Web / 打包 `.exe`）下優先透過 `ResourceLoader` 載入封裝於 `.pck` 內的貼圖資源。
     - 新增 GitHub Actions 自動化工作流程（`.github/workflows/deploy-web.yml`），每次推送至 `main` 分支時自動以 Godot 4.7.2 建置網頁版並發布至 `gh-pages` 分支與 GitHub Pages。
- **2026-10-22**：
   - 新增 **敵我雙方三大基礎戰鬥屬性 (`scripts/autoload/GameManager.gd`, `scripts/Main.gd`)**：
     - **連擊率 (`combo_rate`)**：初始值 `5%`，普通攻擊後有機率追加一次普通攻擊（追加的連擊普攻帶有 `is_combo = true`，不會再次觸發連擊）。
     - **直接傷害 (`direct_dmg`)**：初始值 `0`，無視防禦與格檔等一切減免，直接加進最終傷害值。
     - **迴避率 (`dodge_rate`)**：初始值 `0%`，每次攻擊前最優先判定目標迴避，成功則攻擊無效並跳出 `閃避! MISS` 飄字。
     - 敵方怪物同步具備上述三項屬性，並於戰鬥 HUD 與勇者屬性面板即時顯示。
   - 擴充 **裝備副屬性詞條池 (`scripts/resources/EquipmentData.gd`)**：
     - 將 `combo_rate`（連擊率）、`direct_dmg`（直接傷害）、`dodge_rate`（迴避率）正式納入 `SUB_STAT_TYPES`（共 8 種副屬性詞條），支援依裝備品階決定數值範圍、戰力評分計算與 Tooltip 顯示。
- **2026-10-19**：
   - 新增 **敵我雙方攻擊動作與武器拖曳刀光切換演出 (`scripts/BattleArena.gd`, `scripts/autoload/AssetLoader.gd`)**：
     - 勇者與怪物（一般怪 / 菁英 BOSS）發動攻擊時，於 `0.24` 秒攻擊期間自動切換為帶有武器拖曳刀光（Slash Trail）的揮砍動作貼圖（`hero_attack.png`、`monster_normal_attack.png`、`monster_boss_attack.png`），攻擊後自動切回待機貼圖；同時為原生幾何備案模式補上揮擊刀光弧線。
   - 改版 **裝備主屬性與副屬性系統 (`scripts/resources/EquipmentData.gd`, `scripts/autoload/GameManager.gd`)**：
     - 將裝備數值拆分為「◆ 主屬性」與「◇ 副屬性」：僅主屬性隨裝備強化等級成長，副屬性固定不隨等級成長。
     - 副屬性的項目數量（白0、綠1、藍2、紫3、橘4、彩虹5）與數值高低由裝備品階決定。
     - 實作不重複優先抽取邏輯（當所需項目數超過可用屬性種類時才允許重複），並更新裝備 Tooltip 分區顯示與舊存檔自動遷移。
   - 制定 **「玩法驗證優先 (Gameplay First, No Premature Art)」核心開發原則 (`AGENTS.md`)**：製作新功能時預設不主動生成美術圖素，優先以原生幾何繪圖/UI 快速驗證玩法，待使用者明確要求時再製作美術素材。
   - 修復 **跨電腦同步後 `.godot/global_script_class_cache.cfg` 未更新導致卡在初始畫面的問題**：於 `Sync_Pull.bat`、`Play_Game.bat` 與 `/pull`、`/run` 技能中加入 `Godot_v4.7.2-stable_win64_console.exe --headless --editor --quit` 自動重新掃描註冊新類別與匯入新素材。
- **2026-10-17**：
   - 新增 **RUSH 結算寶箱與開箱噴裝 Cut-In 系統 (`scripts/ui/RushChestCutIn.gd`, `GameManager.generate_rush_chest_reward()`)**：
     - 當 BOSS RUSH 時間結束後，依期間累計擊殺數發放額外寶箱：
       - **3~5 殺**：【華麗寶箱】（噴出 **2 件**高階裝備，保底藍~紫，高機率橘/彩虹）。
       - **6~9 殺**：【奢華寶箱】（噴出 **3 件**更高階裝備，保底紫~橘，高機率彩虹 + 基礎素質 1.38 倍加成）。
       - **10 殺以上**：【究極寶箱】（10~19 殺噴出 **4 件**，**之後每滿 10 殺再多 1 件**；全數保底傳奇橘裝與 55% 天界彩虹神話裝 + 基礎素質 1.50 倍加成）。
     - **戰鬥暫停與二段式開箱動畫**：開箱演出期間**自動暫停背後戰鬥**（`get_tree().paused = true`），先降臨**緊閉上鎖的寶箱**（`chest_*_closed.png`）進行劇烈晃動與鎖扣縫隙迸光蓄力，接著極限下壓後**轟然掀蓋切換為開啟寶箱**（`chest_*.png`），伴隨沖天光柱、擴散震波環與扇形拋物線噴裝演出，待所有裝備飛入背包後才解除暫停繼續戰鬥。
     - 已生成並去背套用 3 款寶箱的「關閉上鎖」與「掀蓋開啟」共 6 張正式美術圖（`chest_ornate_closed.png` / `chest_ornate.png`、`chest_luxury_closed.png` / `chest_luxury.png`、`chest_ultimate_closed.png` / `chest_ultimate.png`），並於除錯工具列新增 **「🎁 測寶箱」** 按鈕可一鍵循環預覽各階寶箱開箱效果。
   - 建立 **漸進式美術替換與熱插拔備案架構 (`AssetLoader.gd`)** 並導入第一批 AI 生成正式美術圖素（包含 BOSS RUSH 側面特寫大頭像、一般/狂熱雙戰鬥背景、勇者與一般怪/魔龍 BOSS 立繪、以及武器/裝甲/盾牌正式 ICON），同時完整保留原生幾何繪圖作為備案，並於除錯面板提供一鍵切換按鈕。
   - 新增 **BOSS RUSH 全畫面最上層大絕招 Cut-In 演出 (`scripts/ui/BossRushCutIn.gd`)**：
     - 獨立於 `CanvasLayer (layer = 100)` 最頂層圖層，直接**橫跨全螢幕正中央**（不再受限於上方戰鬥視窗）。
     - **時間凍結暗轉（Super Freeze）**：Cut-In 發動期間**自動暫停遊戲戰鬥與計時**（`get_tree().paused = true`），背景壓暗並觸發閃白衝擊。
     - **二段式左右切入**：先由左方高速切入**巨型勇者側面特寫大頭像**，緊接著右方猛烈撞入超巨型 **「BOSS RUSH!!!」** 爆裂字體與二次閃光，短暫定格展現魄力後雙向滑出退場並解除暫停，無縫接軌 2 倍速狂熱戰鬥。
   - 新增並簡化 **BOSS RUSH 炫耀擊殺計數器（FEVER Kill Counter）**：精簡為超直覺的兩行顯示——超大字號 `N KILL` 搭配動態熱血評語，每次擊殺菁英怪皆有 Q 彈縮放動畫；RUSH 結束後轉為黃金邊框榮耀結算，在畫面上**留存 4.5 秒**後才優雅淡出。
   - 加深全局 Tooltip 背板不透明度至 98% 深黑藍色，確保閱讀清晰不透底。
   - 裝備與背包全面改為**純 ICON 顯示**：身上裝備與備用背包皆只顯示裝備 ICON（左上角顯示 `▲較強 / ▼較弱` 小角標、右下角顯示強化等級），滑鼠懸浮顯示完整素質 Tooltip；背包圖示支援**左鍵點擊穿戴、右鍵點擊出售**。
   - 修正戰鬥中擊殺敵人或拾取裝備時 Tooltip 自動關閉的問題：將 UI 更新改為原地更新（Incremental Update），不再於每次擊殺獲得金幣/經驗時銷毀並重建圖示節點。
   - 實作完整進度存檔與讀檔系統（`save_game` / `load_game` / `reset_save_data`），每 5 秒與關閉視窗時自動存檔，避免重開遊戲變新局。
   - 修正 BOSS RUSH 期間連續菁英怪強度暴增問題：鎖定以「最近一隻一般怪」作為 1.5 倍強度基準，狂熱期間連續出現的菁英怪強度不再指數級倍增。
   - 實作 Slot Game 風格的 FEVER / BOSS RUSH 模式（擊敗菁英怪機率觸發，15 秒狂熱全菁英怪刷新，⚡ 2 倍速極速演出，專屬動態火星與金框視覺演出）。
   - 實作裝備自怪物身上噴出、彈跳停留發光、飛入背包的拋物線物理流暢演出（`DroppedItemFX.gd`）。
   - 建立 6 大裝備品階體系（包含最高階動態彩虹流光框）。
   - 平衡敵人成長曲線與菁英怪強度（1.5 倍），固定怪物攻速為 1.0。
   - 實作技能點配置機制、等級限制、全額重置技能退點功能，調整魯莽/致命/急救/格檔四大技能公式。

---

## 🎯 下一步待辦 / 可擴充方向 (Next Steps)

- [ ] FEVER / BOSS RUSH 期間增加額外獎勵加成（例如金幣/經驗雙倍或裝備掉落額外詞條）。
- [ ] 增加 FEVER 模式專屬音效或勝利結算彈窗。
- [ ] 擴充更多怪物外觀或 BOSS 獨特外觀剪影。
