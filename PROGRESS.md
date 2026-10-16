# 開發進度與跨裝置交接紀錄 (PROGRESS.md)

> 本檔案用於跨電腦同步**對話上下文、開發決策、已完成功能與待辦事項**。
> 每次執行「上傳 (`/push`)」時，AI 會自動將當次對話的最新進度更新至此檔案；在另一台電腦執行「下載 (`/pull`)」時，AI 會自動讀取此檔案以無縫接軌開發。

---

## 📌 目前專案狀態摘要

- **最後更新時間**：2026-10-16
- **引擎版本**：Godot 4.6 (GL Compatibility)
- **專案類型**：2D 放置型 RPG 雛型 (`IdleRPG_Prototype`)

---

## ✅ 已完成的核心功能與架構

1. **自動戰鬥與關卡系統 (`scripts/Main.gd`, `scripts/BattleArena.gd`, `scripts/autoload/GameManager.gd`)**
   - 勇者與怪物自動讀條攻擊、傷害計算、爆擊判定、浮動戰鬥文字特效。
   - 關卡（Stage）與波次（Wave 1~5，第 5 波為 Boss）推進邏輯，支援戰敗自動退回第 1 波重整。
   - 戰鬥畫面左上角即時顯示技能冷卻圖示列（`battle_skill_bar`），右上角提供「🛠️ 除錯模式」切換戰鬥文字紀錄（`LogPanel` 預設隱藏）。

2. **裝備與背包系統 (`scripts/resources/EquipmentData.gd`, `scripts/autoload/GameManager.gd`)**
   - 3 個穿戴部位：`WEAPON`（武器）、`ARMOR`（裝甲）、`SHIELD`（盾牌）。
   - 支援「裝備強化」、「金幣鍛造隨機裝備」、「怪物掉落裝備」。
   - 背包快捷功能：⚡ **一鍵換裝**（`auto_equip_best()`）與 💰 **一鍵出售較弱裝備**（`auto_sell_weaker()`）。

3. **技能系統 (`scripts/resources/SkillData.gd`)**
   - 內建 4 種核心技能：
     1. `power_slash`：烈焰重斬（主動傷害）
     2. `holy_light`：聖光治癒（主動回血）
     3. `sword_mastery`：劍術專精（被動加攻）
     4. `wind_blessing`：疾風祝福（被動加速）

4. **程序化幾何圖示系統 (`scripts/ui/IconSlot.gd`)**
   - 不依賴外部圖片素材，使用 `_draw()` 繪製裝備（劍、胸甲、騎士盾）與技能圖示、稀有度外框、冷卻遮罩與等級標籤。

5. **跨電腦雲端同步與記憶交接機制 (`AGENTS.md`, `.agents/skills/`, `Sync_Push.bat`, `Sync_Pull.bat`)**
   - 支援在對話中直接輸入「上傳 / 備份」與「下載 / 同步」。
   - 自動偵測並補齊 Windows Git 執行檔路徑（`C:\Program Files\Git\cmd`），並自動同步更新本 `PROGRESS.md` 交接紀錄。

---

## 📝 近期對話決策與變更紀錄

- **2026-10-16 (Commit `61a2761`)**：
  - 精簡裝備部位為 3 大核心部位（武器、裝甲、盾牌），更新 `IconSlot.gd` 程序化繪圖。
  - 新增一鍵換裝（`auto_equip_best`）與一鍵出售較弱裝備（`auto_sell_weaker`）。
  - 新增戰鬥畫面左上角技能冷卻列與右上角「除錯模式」開關。
- **2026-10-16 (跨電腦同步升級)**：
  - 建立 `PROGRESS.md` 作為跨電腦 AI 對話記憶載體。
  - 修正新電腦終端機 `PATH` 未包含 `C:\Program Files\Git\cmd` 的問題，確保所有批次檔與 AI 指令皆能直接執行 Git。

---

## 🎯 下一步待辦 / 可擴充方向 (Next Steps)

- [ ] 確認存讀檔功能（`GameManager.SAVE_PATH`）是否需要綁定自動存檔或離線收益計算。
- [ ] 擴充更多怪物種類、Boss 特殊技能或關卡主題背景。
- [ ] 新增更多流派技能或轉生 / 遺物系統。
