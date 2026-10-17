# 🎨 美術素材替換指南（支援熱插拔與自動備案）

本專案採用**「漸進混搭 + 自動備案」**架構（由 [`scripts/autoload/AssetLoader.gd`](../scripts/autoload/AssetLoader.gd) 負責管理）：
- **自動偵測與免編輯器載入**：你只需要將 `.png` 圖檔直接丟進對應的資料夾並命名為下方指定檔名，**無須開啟 Godot 編輯器重新匯入**，直接雙擊 `Play_Game.bat` 開啟遊戲就會自動載入最新圖片！
- **安全備案機制（Fallback）**：如果某張圖片被刪除、重新命名，或在遊戲右上角「🛠️ 除錯模式」點擊 **「🎨 美術: 正式圖素 / 原生幾何」** 切換開關，該部分就會自動退回原本的程式幾何繪圖，絕不報錯或破圖！

---

## 📁 資料夾結構與對應檔名一覽

### 1. `assets/cutin/`（BOSS RUSH 大絕招切入立繪）
| 檔案名稱 | 建議尺寸 | 說明 |
| :--- | :--- | :--- |
| `hero_cutin.png` | `500 x 400` (去背 PNG) | 發動 BOSS RUSH 時從畫面左側切入的勇者特寫大頭像。背景的斜切速度線、暗轉時間凍結與右側 `BOSS RUSH!!!` 爆裂大字由程式自動疊加。 |

### 2. `assets/backgrounds/`（戰鬥舞台背景）
| 檔案名稱 | 建議尺寸 | 說明 |
| :--- | :--- | :--- |
| `bg_normal.png` | `720 x 310` | 一般無盡討伐時的戰鬥舞台背景（下方約 25% 為角色站立地面）。 |
| `bg_boss_rush.png` | `720 x 310` | 進入 BOSS RUSH 狂熱模式時自動切換的熱血戰鬥背景。 |

### 3. `assets/sprites/`（勇者與怪物戰鬥角色圖）
> 角色與怪物皆支援「攻擊衝刺位移、受擊閃白、復活魔法陣」等所有程式動態特效！

| 檔案名稱 | 建議尺寸 | 說明 |
| :--- | :--- | :--- |
| `hero.png` | `128 x 128` (去背 PNG) | 勇者戰鬥小人（面向右方）。 |
| `monster_normal.png` | `128 x 128` (去背 PNG) | 一般怪物的通用預設外觀（面向左方）。 |
| `monster_boss.png` | `160 x 160` (去背 PNG) | 菁英怪 / BOSS 的通用預設外觀（面向左方）。 |
| `chest_ornate.png` | `256 x 256` (去背 PNG) | BOSS RUSH 結算「華麗寶箱」（3~5 殺）。 |
| `chest_luxury.png` | `256 x 256` (去背 PNG) | BOSS RUSH 結算「奢華寶箱」（6~9 殺）。 |
| `chest_ultimate.png` | `256 x 256` (去背 PNG) | BOSS RUSH 結算「究極寶箱」（10 殺以上）。 |
| *(選配擴充)*<br>`monster_slime.png`<br>`monster_goblin.png`<br>`monster_skeleton.png`<br>`monster_orc.png`<br>`monster_dragon.png`<br>`monster_demon.png` | `128 x 128` ~ `160 x 160` | 若放入特定怪物名稱對應的 PNG，遇到「史萊姆、哥布林、骷髏、半獸人、巨龍、魔王」時會優先顯示專屬外觀；若未放入則自動使用 `monster_normal.png` 或 `monster_boss.png`。 |

### 4. `assets/icons/`（裝備與技能圖示）
> 品階底色、神話彩虹流光框、`▲/▼` 戰力比較角標、`+N` 強化等級、以及擊殺噴裝拋物線光柱，皆由程式自動套用在你的去背 Icon 上！

| 檔案名稱 | 建議尺寸 | 說明 |
| :--- | :--- | :--- |
| `equip_weapon.png` | `64 x 64` (去背 PNG) | 武器部位圖示（身上的武器、背包武器、噴裝掉落物皆共用）。 |
| `equip_armor.png` | `64 x 64` (去背 PNG) | 裝甲部位圖示。 |
| `equip_shield.png` | `64 x 64` (去背 PNG) | 盾牌部位圖示。 |
| *(選配擴充)*<br>`skill_reckless.png`<br>`skill_lethal.png`<br>`skill_first_aid.png`<br>`skill_block.png`<br>`skill_sword_mastery.png`<br>`skill_wind_blessing.png` | `64 x 64` (去背 PNG) | 6 大技能圖示（若放入則取代幾何繪製的技能圖示）。 |
