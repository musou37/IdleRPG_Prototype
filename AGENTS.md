# Project Rules & Custom Commands (IdleRPG_Prototype)

## 跨電腦開發記憶與進度交接 (`PROGRESS.md`)

- 專案根目錄下的 `PROGRESS.md` 為**跨電腦同步對話上下文、設計決策、目前進度與待辦事項**的核心記憶檔。
- 每當開啟新對話或使用者詢問目前進度時，請優先參考 `PROGRESS.md` 以無縫銜接先前的開發脈絡。

## 專案雲端同步指令 (GitHub Sync Commands)

當使用者在對話中輸入以下簡短指令時，請直接為使用者執行對應的 Git 操作，無須再次詢問確認：

> **Git 路徑注意事項**：若當前終端機環境的 `PATH` 找不到 `git`，請在執行 PowerShell 指令前自動加上：
> `if (-not (Get-Command git -ErrorAction SilentlyContinue)) { $env:Path += ";C:\Program Files\Git\cmd" }`

1. **「上傳」/「備份」/「上傳備份」/ `/push`**：
   - **步驟 1（更新對話記憶）**：先將本次對話中完成的修改、重要討論結論與下一步待辦事項，整理並更新至專案根目錄的 `PROGRESS.md`。
   - **步驟 2（提交變更）**：自動執行 `git add -A`，根據變更內容產生清楚的 Commit 訊息並提交（若無新變更則略過 commit）。
   - **步驟 3（推送雲端）**：執行 `$env:GIT_TERMINAL_PROMPT="0"; $env:GCM_INTERACTIVE="never"; git pull --rebase --autostash origin main; git push -u origin main` 將最新進度推送至 GitHub (`https://github.com/musou37/IdleRPG_Prototype.git`)。
   - **步驟 4（回報）**：回報上傳結果、目前的 Commit ID，以及已寫入 `PROGRESS.md` 的交接摘要。

2. **「下載」/「同步」/「下載同步」/ `/pull`**：
   - **步驟 1（拉取雲端）**：自動執行 `$env:GIT_TERMINAL_PROMPT="0"; $env:GCM_INTERACTIVE="never"; git pull --rebase --autostash origin main` 從 GitHub 拉取最新進度。
   - **步驟 2（讀取對話記憶）**：自動讀取 `PROGRESS.md` 的內容。
   - **步驟 3（回報與銜接）**：回報更新狀態、最新的 Commit 紀錄，並主動向使用者摘要 `PROGRESS.md` 中紀錄的「上次開發進度與下一步待辦」，讓使用者能直接接著對話開發。

## 遊戲快捷啟動指令 (Game Launch Command)

當使用者在對話中輸入 **「執行」/「啟動」/「跑遊戲」/ `/run`** 時，請直接在後台啟動 Godot 運行遊戲，無須再次詢問確認：

```powershell
$godot = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe"
if (-not (Test-Path ".godot\global_script_class_cache.cfg")) {
    & $godot --headless --import --path "$PWD"
}
Start-Process $godot -ArgumentList "--path `"$PWD`" --position 200,50"
```
啟動後簡短回報遊戲已成功開啟即可。

